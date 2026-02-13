import Testing
import SwiftUI
@testable import WebViewAMC

@Suite("HeadlessWebView")
struct HeadlessWebViewTests {

    @MainActor
    @Test("HeadlessWebView initializes with default shared manager")
    func defaultInit() {
        let _ = HeadlessWebView()
    }

    @MainActor
    @Test("HeadlessWebView initializes with custom manager")
    func customManagerInit() {
        let config = WebViewConfiguration(handlerName: "headless")
        let manager = WebViewManager(configuration: config)
        let _ = HeadlessWebView(manager: manager)
    }

    @MainActor
    @Test("HeadlessWebView body produces a view")
    func bodyProducesView() {
        let manager = WebViewManager()
        let headless = HeadlessWebView(manager: manager)
        let _ = headless.body
    }

    @MainActor
    @Test("HeadlessWebView works with WebViewContextGroup")
    func headlessWithContextGroup() {
        let group = WebViewContextGroup()
        let scraper = group.createContext(id: "scraper")
        let _ = HeadlessWebView(manager: scraper)
    }
}
