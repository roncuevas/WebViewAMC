import Foundation
import WebKit
import Combine

@MainActor
public final class WebViewProxy: ObservableObject {
    // MARK: - Reactive WKWebView State (KVO-backed)

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var url: URL?
    @Published public private(set) var title: String?
    @Published public private(set) var canGoBack: Bool = false
    @Published public private(set) var canGoForward: Bool = false
    @Published public private(set) var estimatedProgress: Double = 0.0

    // MARK: - Pass-through Access

    public let manager: WebViewManager

    public var webView: WKWebView { manager.webView }
    public var fetcher: WebViewDataFetcher { manager.fetcher }
    public var coordinator: WebViewCoordinator { manager.coordinator }
    public var cookieManager: CookieManager { manager.cookieManager }
    public var messageRouter: WebViewMessageRouter { manager.messageRouter }
    public var handler: WebViewMessageHandler { manager.handler }
    public var configuration: WebViewConfiguration { manager.configuration }

    // MARK: - Init

    public init(manager: WebViewManager = .shared) {
        self.manager = manager
        observeWebView()
    }

    // MARK: - KVO Setup

    private func observeWebView() {
        let wv = manager.webView

        wv.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        wv.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .assign(to: &$url)

        wv.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .assign(to: &$title)

        wv.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canGoBack)

        wv.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canGoForward)

        wv.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .assign(to: &$estimatedProgress)
    }

    // MARK: - Navigation Actions

    public func load(_ url: URL, cookies: [HTTPCookie]? = nil, forceRefresh: Bool = false) {
        webView.loadURL(
            id: nil,
            url: url.absoluteString,
            forceRefresh: forceRefresh,
            cookies: cookies,
            cookieDomain: configuration.cookieDomain,
            logger: configuration.logger
        )
    }

    public func load(_ urlString: String, cookies: [HTTPCookie]? = nil, forceRefresh: Bool = false) {
        webView.loadURL(
            id: nil,
            url: urlString,
            forceRefresh: forceRefresh,
            cookies: cookies,
            cookieDomain: configuration.cookieDomain,
            logger: configuration.logger
        )
    }

    public func goBack() {
        webView.goBack()
    }

    public func goForward() {
        webView.goForward()
    }

    public func reload() {
        webView.reload()
    }

    public func stop() {
        webView.stopLoading()
    }

    // MARK: - Convenience Evaluation

    public func evaluate<T: Decodable>(_ javaScript: String) async throws -> T {
        try await fetcher.evaluate(javaScript)
    }

    public func getHTML() async throws -> String? {
        try await fetcher.getHTML()
    }

    public func fetch(_ action: FetchAction) async -> FetchResult {
        await fetcher.fetch(action)
    }
}
