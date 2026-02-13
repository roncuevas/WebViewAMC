import Testing
import SwiftUI
@testable import WebViewAMC

@Suite("WebViewReader")
struct WebViewReaderTests {

    @MainActor
    @Test("WebViewReader accepts custom manager")
    func readerCustomManager() {
        let config = WebViewConfiguration(handlerName: "readerTest")
        let manager = WebViewManager(configuration: config)
        let _ = WebViewReader(manager: manager) { proxy in
            Text(proxy.configuration.handlerName)
        }
    }

    @MainActor
    @Test("WebView accepts proxy initializer")
    func webViewProxyInit() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        let _ = WebView(proxy: proxy)
    }
}
