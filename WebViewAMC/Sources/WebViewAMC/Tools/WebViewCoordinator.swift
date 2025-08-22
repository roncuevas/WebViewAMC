import WebKit

public class WebViewCoordinator: NSObject, ObservableObject, WKNavigationDelegate {
    public weak var delegate: WebViewCoordinatorDelegate?
    
    private var timeoutTimer: Timer?
    private var timeoutDuration: TimeInterval = 30.0  // Duración del timeout en segundos
    
    init(delegate: WebViewCoordinatorDelegate? = nil,
         timeoutDuration: TimeInterval = 30) {
        self.delegate = delegate
        self.timeoutDuration = timeoutDuration
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Iniciar el temporizador cuando comienza la navegación
        startTimeoutTimer()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Detener el temporizador cuando la navegación se complete
        stopTimeoutTimer()

        if let currentURL = webView.url {
            delegate?.didNavigateTo(url: currentURL)
        }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            // HTTPCookieStorage.shared.setCookies(cookies, for: URL(string: "https://www.saes.escom.ipn.mx/")!, mainDocumentURL: nil)
            self?.delegate?.cookiesReceiver(cookies: cookies)
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Detener el temporizador si ocurre un error
        stopTimeoutTimer()
        delegate?.didFailLoading(error: error)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        let url = navigationAction.request.url
        return .allow
    }

    private func startTimeoutTimer() {
        timeoutTimer?.invalidate() // Asegura que cualquier temporizador previo sea invalidado
        timeoutTimer = Timer.scheduledTimer(timeInterval: timeoutDuration, target: self, selector: #selector(timeoutReached), userInfo: nil, repeats: false)
    }
    
    private func stopTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    @objc private func timeoutReached() {
        delegate?.didTimeout()
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
