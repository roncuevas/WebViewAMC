import Testing
@testable import WebViewAMC

@Suite("FetchResult")
struct FetchResultTests {
    @Test("id returns correct identifier for each case")
    func idProperty() {
        #expect(FetchResult.completed("a").id == "a")
        #expect(FetchResult.cancelled("b").id == "b")
        #expect(FetchResult.failed("c", .timeout).id == "c")
    }

    @Test("isCompleted returns true only for .completed")
    func isCompleted() {
        #expect(FetchResult.completed("a").isCompleted == true)
        #expect(FetchResult.cancelled("a").isCompleted == false)
        #expect(FetchResult.failed("a", .timeout).isCompleted == false)
    }

    @Test("isCancelled returns true only for .cancelled")
    func isCancelled() {
        #expect(FetchResult.cancelled("a").isCancelled == true)
        #expect(FetchResult.completed("a").isCancelled == false)
        #expect(FetchResult.failed("a", .timeout).isCancelled == false)
    }

    @Test("isFailed returns true only for .failed")
    func isFailed() {
        #expect(FetchResult.failed("a", .timeout).isFailed == true)
        #expect(FetchResult.completed("a").isFailed == false)
        #expect(FetchResult.cancelled("a").isFailed == false)
    }

    @Test("error returns WebViewError for .failed, nil otherwise")
    func errorProperty() {
        #expect(FetchResult.failed("a", .timeout).error == .timeout)
        #expect(FetchResult.failed("a", .fetchFailed("net")).error == .fetchFailed("net"))
        #expect(FetchResult.completed("a").error == nil)
        #expect(FetchResult.cancelled("a").error == nil)
    }

    @Test("Equatable: same cases are equal")
    func equatable() {
        #expect(FetchResult.completed("a") == FetchResult.completed("a"))
        #expect(FetchResult.cancelled("b") == FetchResult.cancelled("b"))
        #expect(FetchResult.failed("c", .timeout) == FetchResult.failed("c", .timeout))
    }

    @Test("Equatable: different cases are not equal")
    func notEqual() {
        #expect(FetchResult.completed("a") != FetchResult.cancelled("a"))
        #expect(FetchResult.completed("a") != FetchResult.completed("b"))
        #expect(FetchResult.failed("a", .timeout) != FetchResult.failed("a", .fetchFailed("x")))
    }
}
