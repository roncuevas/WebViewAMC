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

    // MARK: - New Tests

    @Test("Default once delay is 1 second")
    func defaultOnceDelay() {
        let action = FetchAction(id: "test", javaScript: "void(0)")
        if case .once(let delay) = action.strategy {
            #expect(delay == .seconds(1))
        } else {
            Issue.record("Expected .once")
        }
    }

    @Test("Default forceRefresh is false")
    func defaultForceRefresh() {
        let action = FetchAction(id: "test", javaScript: "void(0)")
        #expect(action.forceRefresh == false)
    }

    @Test("Default url is nil")
    func defaultUrlNil() {
        let action = FetchAction(id: "test", javaScript: "void(0)")
        #expect(action.url == nil)
    }

    @Test("Default cookies is nil")
    func defaultCookiesNil() {
        let action = FetchAction(id: "test", javaScript: "void(0)")
        #expect(action.cookies == nil)
    }

    @Test("Once factory defaults to 1 second delay")
    func onceFactoryDefaultDelay() {
        let action = FetchAction.once(id: "test", javaScript: "void(0)")
        if case .once(let delay) = action.strategy {
            #expect(delay == .seconds(1))
        } else {
            Issue.record("Expected .once")
        }
    }

    @Test("Poll factory defaults to 1 second delay")
    func pollFactoryDefaultDelay() {
        let action = FetchAction.poll(
            id: "test",
            javaScript: "void(0)",
            maxAttempts: 3,
            until: { true }
        )
        if case .poll(_, let delay, _) = action.strategy {
            #expect(delay == .seconds(1))
        } else {
            Issue.record("Expected .poll")
        }
    }

    @Test("Continuous factory defaults to 1 second delay")
    func continuousFactoryDefaultDelay() {
        let action = FetchAction.continuous(
            id: "test",
            javaScript: "void(0)",
            while: { true }
        )
        if case .continuous(let delay, _) = action.strategy {
            #expect(delay == .seconds(1))
        } else {
            Issue.record("Expected .continuous")
        }
    }

    @Test("All factories preserve URL and forceRefresh")
    func factoriesPreserveCommonProperties() {
        let once = FetchAction.once(id: "a", url: "https://a.com", javaScript: "x()", forceRefresh: true)
        let poll = FetchAction.poll(id: "b", url: "https://b.com", javaScript: "y()", maxAttempts: 1, forceRefresh: true, until: { true })
        let continuous = FetchAction.continuous(id: "c", url: "https://c.com", javaScript: "z()", forceRefresh: true, while: { true })

        #expect(once.url == "https://a.com")
        #expect(once.forceRefresh == true)
        #expect(poll.url == "https://b.com")
        #expect(poll.forceRefresh == true)
        #expect(continuous.url == "https://c.com")
        #expect(continuous.forceRefresh == true)
    }

    // MARK: - WaitCondition tests

    @Test("Default waitFor is .none")
    func defaultWaitForIsNone() {
        let action = FetchAction(id: "test", javaScript: "void(0)")
        if case .none = action.waitFor {
            // pass
        } else {
            Issue.record("Expected .none waitFor")
        }
    }

    @Test("Once factory accepts waitFor")
    func onceFactoryWithWaitFor() {
        let action = FetchAction.once(
            id: "test",
            javaScript: "void(0)",
            waitFor: .element("#result")
        )
        if case .element(let selector, _, _) = action.waitFor {
            #expect(selector == "#result")
        } else {
            Issue.record("Expected .element waitFor")
        }
    }

    @Test("Poll factory accepts waitFor")
    func pollFactoryWithWaitFor() {
        let action = FetchAction.poll(
            id: "test",
            javaScript: "void(0)",
            maxAttempts: 3,
            waitFor: .navigation(timeout: .seconds(5)),
            until: { true }
        )
        if case .navigation(let timeout, _) = action.waitFor {
            #expect(timeout == .seconds(5))
        } else {
            Issue.record("Expected .navigation waitFor")
        }
    }

    @Test("Continuous factory accepts waitFor")
    func continuousFactoryWithWaitFor() {
        let action = FetchAction.continuous(
            id: "test",
            javaScript: "void(0)",
            waitFor: .element("#table", timeout: .seconds(20)),
            while: { false }
        )
        if case .element(let selector, let timeout, _) = action.waitFor {
            #expect(selector == "#table")
            #expect(timeout == .seconds(20))
        } else {
            Issue.record("Expected .element waitFor")
        }
    }

    @Test("Existing factories still work without waitFor")
    func backwardCompatibility() {
        let once = FetchAction.once(id: "a", javaScript: "x()")
        let poll = FetchAction.poll(id: "b", javaScript: "y()", maxAttempts: 1, until: { true })
        let continuous = FetchAction.continuous(id: "c", javaScript: "z()", while: { false })

        if case .none = once.waitFor {} else { Issue.record("Expected .none") }
        if case .none = poll.waitFor {} else { Issue.record("Expected .none") }
        if case .none = continuous.waitFor {} else { Issue.record("Expected .none") }
    }
}
