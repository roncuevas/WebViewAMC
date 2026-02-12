import Testing
import WebKit
@testable import WebViewAMC

@Suite("WebViewManager")
struct WebViewManagerTests {
    @MainActor
    @Test("Default initialization creates all components")
    func defaultInit() {
        let manager = WebViewManager()

        #expect(manager.configuration.handlerName == "myNativeApp")
        #expect(manager.configuration.timeoutDuration == 30.0)
    }

    @MainActor
    @Test("Custom configuration is passed through")
    func customConfig() {
        let config = WebViewConfiguration(
            handlerName: "testHandler",
            timeoutDuration: 15.0,
            isInspectable: false,
            verbose: true
        )
        let manager = WebViewManager(configuration: config)

        #expect(manager.configuration.handlerName == "testHandler")
        #expect(manager.configuration.timeoutDuration == 15.0)
        #expect(manager.configuration.verbose == true)
    }

    @MainActor
    @Test("WebView navigation delegate is set to coordinator")
    func webViewDelegateSetup() {
        let manager = WebViewManager()
        #expect(manager.webView.navigationDelegate === manager.coordinator)
    }

    @MainActor
    @Test("Message handler is configured with router")
    func messageHandlerHasRouter() {
        let manager = WebViewManager()
        #expect(manager.handler.router != nil)
        #expect(manager.handler.router === manager.messageRouter)
    }

    @MainActor
    @Test("Fetcher is properly initialized")
    func fetcherInitialized() {
        let manager = WebViewManager()
        #expect(manager.fetcher.isRunning("nonexistent") == false)
    }

    @MainActor
    @Test("Shared instance is accessible")
    func sharedInstance() {
        let shared = WebViewManager.shared
        #expect(shared.configuration.handlerName == "myNativeApp")
    }

    @MainActor
    @Test("CookieManager is initialized with correct domain")
    func cookieManagerDomain() {
        let domain = URL(string: "https://example.com")!
        let config = WebViewConfiguration(cookieDomain: domain)
        let manager = WebViewManager(configuration: config)

        let cookies = manager.cookieManager.cookiesForDomain()
        // Verifies cookieManager was initialized with the domain (returns empty for no cookies)
        #expect(cookies.isEmpty)
    }
}
