import Testing
@testable import WebViewAMC

@Suite("WebViewError")
struct WebViewErrorTests {
    @Test("Equatable works for same cases")
    func equatable() {
        #expect(WebViewError.timeout == WebViewError.timeout)
        #expect(WebViewError.invalidURL("test") == WebViewError.invalidURL("test"))
        #expect(WebViewError.invalidURL("a") != WebViewError.invalidURL("b"))
        #expect(WebViewError.timeout != WebViewError.invalidURL("test"))
    }

    @Test("localizedDescription contains relevant info")
    func localizedDescription() {
        let invalidURL = WebViewError.invalidURL("bad-url")
        #expect(invalidURL.localizedDescription.contains("bad-url"))

        let jsError = WebViewError.javaScriptEvaluation("syntax error")
        #expect(jsError.localizedDescription.contains("syntax error"))

        let timeout = WebViewError.timeout
        #expect(timeout.localizedDescription.contains("timed out"))

        let navFailed = WebViewError.navigationFailed("404")
        #expect(navFailed.localizedDescription.contains("404"))

        let cancelled = WebViewError.taskCancelled("task-1")
        #expect(cancelled.localizedDescription.contains("task-1"))

        let fetchFailed = WebViewError.fetchFailed("network")
        #expect(fetchFailed.localizedDescription.contains("network"))

        let decodeFailed = WebViewError.messageDecodingFailed("bad format")
        #expect(decodeFailed.localizedDescription.contains("bad format"))
    }
}
