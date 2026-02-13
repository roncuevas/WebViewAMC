import Testing
import WebKit
@testable import WebViewAMC

@Suite("WebViewProxy")
struct WebViewProxyTests {

    // MARK: - Initialization

    @MainActor
    @Test("Custom manager initialization")
    func customManagerInit() {
        let config = WebViewConfiguration(handlerName: "proxyTest")
        let manager = WebViewManager(configuration: config)
        let proxy = WebViewProxy(manager: manager)
        #expect(proxy.manager === manager)
        #expect(proxy.configuration.handlerName == "proxyTest")
    }

    // MARK: - Pass-through Properties

    @MainActor
    @Test("webView returns manager's webView")
    func webViewPassthrough() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        #expect(proxy.webView === manager.webView)
    }

    @MainActor
    @Test("fetcher returns manager's fetcher")
    func fetcherPassthrough() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        #expect(proxy.fetcher === manager.fetcher)
    }

    @MainActor
    @Test("coordinator returns manager's coordinator")
    func coordinatorPassthrough() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        #expect(proxy.coordinator === manager.coordinator)
    }

    @MainActor
    @Test("cookieManager returns manager's cookieManager")
    func cookieManagerPassthrough() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        let cookies = proxy.cookieManager.cookiesForDomain()
        #expect(cookies.isEmpty)
    }

    @MainActor
    @Test("messageRouter returns manager's messageRouter")
    func messageRouterPassthrough() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        #expect(proxy.messageRouter === manager.messageRouter)
    }

    @MainActor
    @Test("handler returns manager's handler")
    func handlerPassthrough() {
        let manager = WebViewManager()
        let proxy = WebViewProxy(manager: manager)
        #expect(proxy.handler === manager.handler)
    }

    // MARK: - Initial Published State

    @MainActor
    @Test("Initial isLoading is false")
    func initialIsLoading() {
        let proxy = WebViewProxy(manager: WebViewManager())
        #expect(proxy.isLoading == false)
    }

    @MainActor
    @Test("Initial url is nil")
    func initialUrl() {
        let proxy = WebViewProxy(manager: WebViewManager())
        #expect(proxy.url == nil)
    }

    @MainActor
    @Test("Initial title is nil")
    func initialTitle() {
        let proxy = WebViewProxy(manager: WebViewManager())
        #expect(proxy.title == nil)
    }

    @MainActor
    @Test("Initial canGoBack is false")
    func initialCanGoBack() {
        let proxy = WebViewProxy(manager: WebViewManager())
        #expect(proxy.canGoBack == false)
    }

    @MainActor
    @Test("Initial canGoForward is false")
    func initialCanGoForward() {
        let proxy = WebViewProxy(manager: WebViewManager())
        #expect(proxy.canGoForward == false)
    }

    @MainActor
    @Test("Initial estimatedProgress is 0.0")
    func initialEstimatedProgress() {
        let proxy = WebViewProxy(manager: WebViewManager())
        #expect(proxy.estimatedProgress == 0.0)
    }

    // MARK: - Navigation Actions (Safety)

    @MainActor
    @Test("load URL does not crash")
    func loadURL() {
        let proxy = WebViewProxy(manager: WebViewManager())
        proxy.load(URL(string: "https://example.com")!)
    }

    @MainActor
    @Test("load String does not crash")
    func loadString() {
        let proxy = WebViewProxy(manager: WebViewManager())
        proxy.load("https://example.com")
    }

    @MainActor
    @Test("goBack does not crash on empty history")
    func goBackEmpty() {
        let proxy = WebViewProxy(manager: WebViewManager())
        proxy.goBack()
    }

    @MainActor
    @Test("goForward does not crash on empty history")
    func goForwardEmpty() {
        let proxy = WebViewProxy(manager: WebViewManager())
        proxy.goForward()
    }

    @MainActor
    @Test("reload does not crash")
    func reloadSafe() {
        let proxy = WebViewProxy(manager: WebViewManager())
        proxy.reload()
    }

    @MainActor
    @Test("stop does not crash")
    func stopSafe() {
        let proxy = WebViewProxy(manager: WebViewManager())
        proxy.stop()
    }

    // MARK: - Convenience Evaluation

    @MainActor
    @Test("fetch delegates to fetcher")
    func fetchDelegation() async {
        let proxy = WebViewProxy(manager: WebViewManager())
        let action = FetchAction.continuous(
            id: "proxyTest",
            javaScript: "void(0)",
            delay: .milliseconds(10),
            while: { false }
        )
        let result = await proxy.fetch(action)
        #expect(result.isCompleted)
        #expect(result.id == "proxyTest")
    }
}
