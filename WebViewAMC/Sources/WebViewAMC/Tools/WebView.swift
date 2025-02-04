import SwiftUI
import WebKit

public struct WebView: UIViewRepresentable {
    private let webView: WKWebView
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) { }
}
