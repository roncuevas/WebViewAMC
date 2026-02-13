import SwiftUI
import WebKit

public struct WebView: UIViewRepresentable {
    private let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }

    public init(proxy: WebViewProxy) {
        self.webView = proxy.webView
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) { }
}
