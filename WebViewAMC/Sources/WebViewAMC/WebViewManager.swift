import Combine
import Foundation
import WebKit

@MainActor
public final class WebViewManager: Sendable {
    public static let shared = WebViewManager()
    public static let handlerName = "myNativeApp"
    public static let verbose = false
    
    public let webView: WKWebView
    public let coordinator = WebViewCoordinator()
    public lazy var fetcher = WebViewDataFetcher(webView: webView)
    public let handler = WebViewMessageHandler()
    
    private init() {
        let userContentController = WKUserContentController()
        userContentController.add(handler, name: WebViewManager.handlerName)
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        webView.navigationDelegate = coordinator
    }
}
