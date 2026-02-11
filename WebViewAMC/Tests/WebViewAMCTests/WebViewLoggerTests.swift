import Testing
@testable import WebViewAMC

@Suite("WebViewLogger")
struct WebViewLoggerTests {
    @Test("MockWebViewLogger captures messages")
    func capturesMessages() {
        let logger = MockWebViewLogger()
        logger.log(.info, "test message", source: "Test")

        #expect(logger.entries.count == 1)
        #expect(logger.entries[0].level == .info)
        #expect(logger.entries[0].message == "test message")
        #expect(logger.entries[0].source == "Test")
    }

    @Test("Level filtering with MockWebViewLogger")
    func levelFiltering() {
        let logger = MockWebViewLogger()
        logger.log(.debug, "debug msg", source: "Test")
        logger.log(.info, "info msg", source: "Test")
        logger.log(.warning, "warning msg", source: "Test")
        logger.log(.error, "error msg", source: "Test")

        #expect(logger.messages(at: .debug).count == 1)
        #expect(logger.messages(at: .info).count == 1)
        #expect(logger.messages(at: .warning).count == 1)
        #expect(logger.messages(at: .error).count == 1)
    }

    @Test("hasMessage finds matching text")
    func hasMessage() {
        let logger = MockWebViewLogger()
        logger.log(.info, "Hello World", source: "Test")

        #expect(logger.hasMessage(containing: "Hello") == true)
        #expect(logger.hasMessage(containing: "missing") == false)
    }

    @Test("Reset clears all entries")
    func reset() {
        let logger = MockWebViewLogger()
        logger.log(.info, "msg", source: "Test")
        logger.reset()

        #expect(logger.entries.isEmpty)
    }

    @Test("WebViewLogLevel comparison works")
    func levelComparison() {
        #expect(WebViewLogLevel.debug < WebViewLogLevel.info)
        #expect(WebViewLogLevel.info < WebViewLogLevel.warning)
        #expect(WebViewLogLevel.warning < WebViewLogLevel.error)
    }

    @Test("Default log method uses WebViewAMC source")
    func defaultSource() {
        let logger = MockWebViewLogger()
        logger.log(.info, "test")

        #expect(logger.entries[0].source == "WebViewAMC")
    }
}
