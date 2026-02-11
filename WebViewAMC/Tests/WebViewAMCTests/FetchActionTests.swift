import Testing
@testable import WebViewAMC

@Suite("FetchAction")
struct FetchActionTests {
    @Test("Default strategy is .once")
    func defaultStrategy() {
        let action = FetchAction(id: "test", javaScript: "console.log(1)")

        if case .once = action.strategy {
            // pass
        } else {
            Issue.record("Expected .once strategy")
        }
    }

    @Test("Stores all properties correctly")
    func storesProperties() {
        let action = FetchAction(
            id: "myAction",
            url: "https://example.com",
            javaScript: "document.title",
            forceRefresh: true
        )

        #expect(action.id == "myAction")
        #expect(action.url == "https://example.com")
        #expect(action.javaScript == "document.title")
        #expect(action.forceRefresh == true)
        #expect(action.cookies == nil)
    }

    @Test("Poll strategy stores parameters")
    func pollStrategy() {
        let action = FetchAction(
            id: "poll",
            javaScript: "check()",
            strategy: .poll(maxAttempts: 5, delay: .seconds(2), until: { true })
        )

        if case .poll(let maxAttempts, let delay, _) = action.strategy {
            #expect(maxAttempts == 5)
            #expect(delay == .seconds(2))
        } else {
            Issue.record("Expected .poll strategy")
        }
    }

    @Test("Continuous strategy stores parameters")
    func continuousStrategy() {
        let action = FetchAction(
            id: "loop",
            javaScript: "loop()",
            strategy: .continuous(delay: .milliseconds(500), while: { false })
        )

        if case .continuous(let delay, _) = action.strategy {
            #expect(delay == .milliseconds(500))
        } else {
            Issue.record("Expected .continuous strategy")
        }
    }
}
