import Testing
@testable import WebViewAMC

@Suite("DataFetchRequest")
struct DataFetchRequestTests {
    @Test("Default values are correct")
    func defaultValues() {
        let request = DataFetchRequest(id: "test", javaScript: "run()")

        #expect(request.id == "test")
        #expect(request.url == nil)
        #expect(request.forceRefresh == false)
        #expect(request.javaScript == "run()")
        #expect(request.delayToLoad == 0)
        #expect(request.delayToFetch == 1_000_000_000)
        #expect(request.delayToNextRequest == 1_000_000_000)
        #expect(request.verbose == true)
        #expect(request.iterations == nil)
        #expect(request.cookies == nil)
        #expect(request.condition == nil)
    }

    @Test("toFetchAction creates .once for no condition and no iterations")
    func toFetchActionOnce() {
        let request = DataFetchRequest(id: "once", javaScript: "run()")
        let action = request.toFetchAction()

        #expect(action.id == "once")
        #expect(action.javaScript == "run()")
        if case .once = action.strategy {
            // pass
        } else {
            Issue.record("Expected .once strategy")
        }
    }

    @Test("toFetchAction creates .poll for iterations + condition")
    func toFetchActionPoll() {
        let request = DataFetchRequest(
            id: "poll",
            javaScript: "check()",
            iterations: 5,
            condition: { true }
        )
        let action = request.toFetchAction()

        if case .poll(let maxAttempts, _, _) = action.strategy {
            #expect(maxAttempts == 5)
        } else {
            Issue.record("Expected .poll strategy")
        }
    }

    @Test("toFetchAction creates .continuous for condition only")
    func toFetchActionContinuous() {
        let request = DataFetchRequest(
            id: "continuous",
            javaScript: "loop()",
            condition: { true }
        )
        let action = request.toFetchAction()

        if case .continuous = action.strategy {
            // pass
        } else {
            Issue.record("Expected .continuous strategy")
        }
    }

    @Test("toFetchAction preserves all properties")
    func toFetchActionPreservesProperties() {
        let request = DataFetchRequest(
            id: "full",
            url: "https://example.com",
            forceRefresh: true,
            javaScript: "go()"
        )
        let action = request.toFetchAction()

        #expect(action.id == "full")
        #expect(action.url == "https://example.com")
        #expect(action.forceRefresh == true)
        #expect(action.javaScript == "go()")
    }
}
