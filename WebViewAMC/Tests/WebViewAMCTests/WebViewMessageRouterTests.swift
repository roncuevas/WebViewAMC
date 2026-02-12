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

    // MARK: - New Tests

    @MainActor
    @Test("Registered handler takes priority over fallback")
    func handlerPriorityOverFallback() {
        let router = WebViewMessageRouter()
        var handlerCalled = false
        var fallbackCalled = false

        router.register(key: "test") { _ in handlerCalled = true }
        router.registerFallback { _ in fallbackCalled = true }

        router.route(["test": "value"])

        #expect(handlerCalled == true)
        #expect(fallbackCalled == false)
    }

    @MainActor
    @Test("Empty message dictionary does nothing")
    func emptyMessageDictionary() {
        let router = WebViewMessageRouter()
        var called = false

        router.registerFallback { _ in called = true }
        router.route([:])

        #expect(called == false)
    }

    @MainActor
    @Test("Replacing handler overwrites previous one")
    func replaceHandler() {
        let router = WebViewMessageRouter()
        var firstCalled = false
        var secondCalled = false

        router.register(key: "test") { _ in firstCalled = true }
        router.register(key: "test") { _ in secondCalled = true }

        router.route(["test": "value"])

        #expect(firstCalled == false)
        #expect(secondCalled == true)
    }

    @MainActor
    @Test("Unregistering non-existent key does not crash")
    func unregisterNonExistent() {
        let router = WebViewMessageRouter()
        router.unregister(key: "doesNotExist")
        // Should not crash
    }

    @MainActor
    @Test("Fallback receives unregistered keys while registered keys go to handlers")
    func mixedHandlerAndFallback() {
        let router = WebViewMessageRouter()
        var handlerKeys = [String]()
        var fallbackKeys = [String]()

        router.register(key: "known") { msg in handlerKeys.append(msg.key) }
        router.registerFallback { msg in fallbackKeys.append(msg.key) }

        router.route(["known": "1", "unknown": "2"])

        #expect(handlerKeys == ["known"])
        #expect(fallbackKeys == ["unknown"])
    }

    @MainActor
    @Test("Message value is correctly decoded via decoder")
    func messageValueDecoding() {
        let router = WebViewMessageRouter()
        var receivedValue: WebViewMessageValue?

        router.register(key: "flag") { msg in receivedValue = msg.value }

        router.route(["flag": "1"])

        guard case .bool(let val) = receivedValue else {
            Issue.record("Expected .bool, got \(String(describing: receivedValue))")
            return
        }
        #expect(val == true)
    }

    @MainActor
    @Test("No fallback handler does not crash for unregistered keys")
    func noFallbackNoCrash() {
        let router = WebViewMessageRouter()
        router.register(key: "only") { _ in }
        router.route(["other": "value"])
        // Should not crash
    }
}
