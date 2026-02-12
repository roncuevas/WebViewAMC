import Testing
import WebKit
@testable import WebViewAMC

@Suite("WebViewDataFetcher")
struct WebViewDataFetcherTests {
    @MainActor
    @Test("FetchAction .once static factory creates correct strategy")
    func onceFactory() {
        let action = FetchAction.once(id: "test", javaScript: "run()", delay: .seconds(2))
        #expect(action.id == "test")
        #expect(action.javaScript == "run()")
        if case .once(let delay) = action.strategy {
            #expect(delay == .seconds(2))
        } else {
            Issue.record("Expected .once strategy")
        }
    }

    @MainActor
    @Test("FetchAction .poll static factory creates correct strategy")
    func pollFactory() {
        let action = FetchAction.poll(id: "poll", javaScript: "check()", maxAttempts: 3, delay: .seconds(1), until: { true })
        #expect(action.id == "poll")
        if case .poll(let max, let delay, _) = action.strategy {
            #expect(max == 3)
            #expect(delay == .seconds(1))
        } else {
            Issue.record("Expected .poll strategy")
        }
    }

    @MainActor
    @Test("FetchAction .continuous static factory creates correct strategy")
    func continuousFactory() {
        let action = FetchAction.continuous(id: "cont", javaScript: "loop()", delay: .milliseconds(500), while: { false })
        #expect(action.id == "cont")
        if case .continuous(let delay, _) = action.strategy {
            #expect(delay == .milliseconds(500))
        } else {
            Issue.record("Expected .continuous strategy")
        }
    }

    @MainActor
    @Test("FetchAction factories preserve optional properties")
    func factoryPreservesProperties() {
        let action = FetchAction.once(id: "test", url: "https://example.com", javaScript: "run()", forceRefresh: true)
        #expect(action.url == "https://example.com")
        #expect(action.forceRefresh == true)
    }

    @MainActor
    @Test("isRunning returns false for non-existent task")
    func isRunningFalse() {
        let webView = WKWebView()
        let fetcher = WebViewDataFetcher(webView: webView)
        #expect(fetcher.isRunning("nonexistent") == false)
    }

    @MainActor
    @Test("cancelAllTasks clears all tasks")
    func cancelAllTasks() {
        let webView = WKWebView()
        let fetcher = WebViewDataFetcher(webView: webView)
        fetcher.cancelAllTasks()
        #expect(fetcher.isRunning("any") == false)
    }

    @MainActor
    @Test("cancelTasks removes specific tasks")
    func cancelSpecificTasks() {
        let webView = WKWebView()
        let fetcher = WebViewDataFetcher(webView: webView)
        fetcher.cancelTasks(["a", "b"])
        #expect(fetcher.isRunning("a") == false)
        #expect(fetcher.isRunning("b") == false)
    }

    @MainActor
    @Test("fetch FetchAction tracks task while running")
    func fetchActionTracksTask() async {
        let webView = WKWebView()
        let fetcher = WebViewDataFetcher(webView: webView)
        var wasRunning = false

        let action = FetchAction.poll(
            id: "tracked",
            javaScript: "test()",
            maxAttempts: 2,
            delay: .milliseconds(50),
            until: {
                if fetcher.isRunning("tracked") {
                    wasRunning = true
                }
                return false
            }
        )

        _ = await fetcher.fetch(action)

        #expect(wasRunning == true)
        #expect(fetcher.isRunning("tracked") == false)
    }

    @MainActor
    @Test("fetch FetchAction .poll stops when condition is met")
    func pollStopsOnCondition() async {
        let webView = WKWebView()
        let fetcher = WebViewDataFetcher(webView: webView)
        var attemptCount = 0

        let action = FetchAction.poll(
            id: "pollStop",
            javaScript: "check()",
            maxAttempts: 10,
            delay: .milliseconds(10),
            until: {
                attemptCount += 1
                return attemptCount >= 3
            }
        )

        let result = await fetcher.fetch(action)

        if case .completed = result {
            #expect(attemptCount == 3)
        } else {
            Issue.record("Expected .completed, got \(result)")
        }
    }

    @MainActor
    @Test("fetch FetchAction .continuous stops when condition becomes false")
    func continuousStopsOnCondition() async {
        let webView = WKWebView()
        let fetcher = WebViewDataFetcher(webView: webView)
        var count = 0

        let action = FetchAction.continuous(
            id: "contStop",
            javaScript: "loop()",
            delay: .milliseconds(10),
            while: {
                count += 1
                return count < 4
            }
        )

        let result = await fetcher.fetch(action)

        if case .completed = result {
            #expect(count >= 4)
        } else {
            Issue.record("Expected .completed, got \(result)")
        }
    }
}
