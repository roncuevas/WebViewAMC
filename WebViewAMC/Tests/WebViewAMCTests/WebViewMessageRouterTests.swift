import Testing
@testable import WebViewAMC

@Suite("WebViewMessageRouter")
struct WebViewMessageRouterTests {
    @MainActor
    @Test("Routes message to registered handler")
    func routeToRegisteredHandler() {
        let router = WebViewMessageRouter()
        var received: WebViewMessage?

        router.register(key: "greeting") { message in
            received = message
        }

        router.route(["greeting": "hello"])

        #expect(received?.key == "greeting")
        #expect(received?.rawValue == "hello")
    }

    @MainActor
    @Test("Routes to fallback when no handler registered")
    func routeToFallback() {
        let router = WebViewMessageRouter()
        var received: WebViewMessage?

        router.registerFallback { message in
            received = message
        }

        router.route(["unknown": "value"])

        #expect(received?.key == "unknown")
    }

    @MainActor
    @Test("Unregister removes handler")
    func unregisterHandler() {
        let router = WebViewMessageRouter()
        var callCount = 0

        router.register(key: "test") { _ in
            callCount += 1
        }

        router.route(["test": "first"])
        #expect(callCount == 1)

        router.unregister(key: "test")
        router.route(["test": "second"])
        #expect(callCount == 1)
    }

    @MainActor
    @Test("UnregisterAll clears all handlers and fallback")
    func unregisterAll() {
        let router = WebViewMessageRouter()
        var handlerCalled = false
        var fallbackCalled = false

        router.register(key: "test") { _ in handlerCalled = true }
        router.registerFallback { _ in fallbackCalled = true }

        router.unregisterAll()
        router.route(["test": "value"])

        #expect(handlerCalled == false)
        #expect(fallbackCalled == false)
    }

    @MainActor
    @Test("Routes multiple keys in single message")
    func routeMultipleKeys() {
        let router = WebViewMessageRouter()
        var keys = [String]()

        router.register(key: "a") { msg in keys.append(msg.key) }
        router.register(key: "b") { msg in keys.append(msg.key) }

        router.route(["a": "1", "b": "2"])

        #expect(keys.contains("a"))
        #expect(keys.contains("b"))
        #expect(keys.count == 2)
    }
}
