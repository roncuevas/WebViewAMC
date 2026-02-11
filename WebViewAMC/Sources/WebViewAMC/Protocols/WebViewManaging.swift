import WebKit

@MainActor
public protocol WebViewManaging: AnyObject {
    var webView: WKWebView { get }
    var coordinator: WebViewCoordinator { get }
    var fetcher: WebViewDataFetcher { get }
    var handler: WebViewMessageHandler { get }
    var configuration: WebViewConfiguration { get }
    var messageRouter: WebViewMessageRouter { get }
    var cookieManager: CookieManager { get }
}
