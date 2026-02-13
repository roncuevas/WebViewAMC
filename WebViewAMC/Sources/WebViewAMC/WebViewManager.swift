import Foundation
import WebKit

@MainActor
public final class WebViewManager: WebViewManaging, Sendable {
    public static let shared = WebViewManager()

    public let configuration: WebViewConfiguration
    public let webView: WKWebView
    public let coordinator: WebViewCoordinator
    public lazy var fetcher = WebViewDataFetcher(webView: webView, configuration: configuration)
    public let handler: WebViewMessageHandler
    public let messageRouter: WebViewMessageRouter
    public let cookieManager: CookieManager

    public init(configuration: WebViewConfiguration = .default, processPool: WKProcessPool? = nil) {
        self.configuration = configuration

        let userContentController = WKUserContentController()
        let messageHandler = WebViewMessageHandler()
        let router = WebViewMessageRouter()
        messageHandler.router = router
        userContentController.add(messageHandler, name: configuration.handlerName)

        let wkConfiguration = WKWebViewConfiguration()
        wkConfiguration.userContentController = userContentController
        if let processPool {
            wkConfiguration.processPool = processPool
        }
        let webView = WKWebView(frame: .zero, configuration: wkConfiguration)

        let coordinator = WebViewCoordinator(timeoutDuration: configuration.timeoutDuration)

        if #available(iOS 16.4, *) {
            webView.isInspectable = configuration.isInspectable
        }
        webView.navigationDelegate = coordinator

        self.webView = webView
        self.coordinator = coordinator
        self.handler = messageHandler
        self.messageRouter = router
        self.cookieManager = CookieManager(webView: webView, cookieDomain: configuration.cookieDomain)
    }
}
