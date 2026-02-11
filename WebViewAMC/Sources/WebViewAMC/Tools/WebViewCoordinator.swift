import WebKit

public enum NavigationEvent: Sendable {
    case started
    case finished(URL?)
    case failed(Error)
    case timeout
}

public class WebViewCoordinator: NSObject, ObservableObject, WKNavigationDelegate {
    public weak var delegate: WebViewCoordinatorDelegate?

    private var timeoutTask: Task<Void, Never>?
    private var timeoutDuration: TimeInterval

    private let eventsContinuation: AsyncStream<NavigationEvent>.Continuation
    public let events: AsyncStream<NavigationEvent>

    init(delegate: WebViewCoordinatorDelegate? = nil,
         timeoutDuration: TimeInterval = 30) {
        self.delegate = delegate
        self.timeoutDuration = timeoutDuration
        var continuation: AsyncStream<NavigationEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventsContinuation = continuation
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        startTimeoutTimer()
        eventsContinuation.yield(.started)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopTimeoutTimer()

        if let currentURL = webView.url {
            delegate?.didNavigateTo(url: currentURL)
        }

        eventsContinuation.yield(.finished(webView.url))

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            self?.delegate?.cookiesReceiver(cookies: cookies)
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        stopTimeoutTimer()
        delegate?.didFailLoading(error: error)
        eventsContinuation.yield(.failed(error))
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        .allow
    }

    private func startTimeoutTimer() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self, timeoutDuration] in
            try? await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.delegate?.didTimeout()
                self?.eventsContinuation.yield(.timeout)
            }
        }
    }

    private func stopTimeoutTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    public func setTimeout(_ timeoutDuration: TimeInterval) {
        self.timeoutDuration = timeoutDuration
    }
}

@MainActor
public protocol WebViewCoordinatorDelegate: AnyObject {
    func cookiesReceiver(cookies: [HTTPCookie])
    func didFailLoading(error: Error)
    func didTimeout()
    func didNavigateTo(url: URL)
}

public extension WebViewCoordinatorDelegate {
    func cookiesReceiver(cookies: [HTTPCookie]) {}
    func didFailLoading(error: Error) {}
    func didTimeout() {}
    func didNavigateTo(url: URL) {}
}
