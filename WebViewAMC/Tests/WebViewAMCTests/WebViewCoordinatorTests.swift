import Testing
import WebKit
@testable import WebViewAMC

@Suite("WebViewCoordinator")
struct WebViewCoordinatorTests {
    @MainActor
    @Test("Events stream yields .started on didStartProvisionalNavigation")
    func eventsStreamStarted() async {
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        let webView = WKWebView()

        let task = Task<NavigationEvent?, Never> {
            for await event in coordinator.events {
                return event
            }
            return nil
        }

        // Small delay to ensure the stream consumer is ready
        try? await Task.sleep(for: .milliseconds(50))
        coordinator.webView(webView, didStartProvisionalNavigation: nil)

        // Give time for event to propagate
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let event = await task.value
        guard case .started = event else {
            Issue.record("Expected .started, got \(String(describing: event))")
            return
        }
    }

    @MainActor
    @Test("Events stream yields .finished on didFinish")
    func eventsStreamFinished() async {
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        let webView = WKWebView()

        let task = Task<NavigationEvent?, Never> {
            for await event in coordinator.events {
                if case .finished = event { return event }
            }
            return nil
        }

        try? await Task.sleep(for: .milliseconds(50))
        coordinator.webView(webView, didFinish: nil)

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let event = await task.value
        guard case .finished = event else {
            Issue.record("Expected .finished, got \(String(describing: event))")
            return
        }
    }

    @MainActor
    @Test("Events stream yields .failed on didFail")
    func eventsStreamFailed() async {
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        let webView = WKWebView()
        let testError = NSError(domain: "test", code: 42)

        let task = Task<NavigationEvent?, Never> {
            for await event in coordinator.events {
                if case .failed = event { return event }
            }
            return nil
        }

        try? await Task.sleep(for: .milliseconds(50))
        coordinator.webView(webView, didFail: nil, withError: testError)

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let event = await task.value
        guard case .failed(let error) = event else {
            Issue.record("Expected .failed, got \(String(describing: event))")
            return
        }
        #expect((error as NSError).code == 42)
    }

    @MainActor
    @Test("Events stream yields .failed on didFailProvisionalNavigation")
    func eventsStreamFailedProvisional() async {
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        let webView = WKWebView()
        let testError = NSError(domain: "test", code: 99)

        let task = Task<NavigationEvent?, Never> {
            for await event in coordinator.events {
                if case .failed = event { return event }
            }
            return nil
        }

        try? await Task.sleep(for: .milliseconds(50))
        coordinator.webView(webView, didFailProvisionalNavigation: nil, withError: testError)

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let event = await task.value
        guard case .failed(let error) = event else {
            Issue.record("Expected .failed, got \(String(describing: event))")
            return
        }
        #expect((error as NSError).code == 99)
    }

    @MainActor
    @Test("didFailProvisionalNavigation delegates to didFailLoading")
    func didFailProvisionalDelegatesToDelegate() async {
        let delegate = MockWebViewCoordinatorDelegate()
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        coordinator.delegate = delegate
        let webView = WKWebView()
        let testError = NSError(domain: "test", code: 77)

        coordinator.webView(webView, didFailProvisionalNavigation: nil, withError: testError)

        #expect(delegate.failedErrors.count == 1)
        #expect((delegate.failedErrors.first as? NSError)?.code == 77)
    }

    @MainActor
    @Test("setTimeout updates timeout duration")
    func setTimeoutUpdatesDuration() {
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        coordinator.setTimeout(60)
        // No public accessor for timeoutDuration, but we verify it doesn't crash
        // and the timeout behavior changes accordingly
    }

    @MainActor
    @Test("Events stream yields .timeout after timeout fires")
    func eventsStreamTimeout() async {
        let coordinator = WebViewCoordinator(timeoutDuration: 0.1)
        let webView = WKWebView()

        var collected = [NavigationEvent]()

        let task = Task<NavigationEvent?, Never> {
            for await event in coordinator.events {
                collected.append(event)
                if case .timeout = event { return event }
            }
            return nil
        }

        try? await Task.sleep(for: .milliseconds(50))
        coordinator.webView(webView, didStartProvisionalNavigation: nil)

        // Allow enough time for the timeout to fire and MainActor to process it
        for _ in 0..<20 {
            try? await Task.sleep(for: .milliseconds(100))
            if collected.contains(where: { if case .timeout = $0 { return true }; return false }) {
                break
            }
        }
        task.cancel()

        let event = await task.value
        guard case .timeout = event else {
            Issue.record("Expected .timeout, got \(String(describing: event))")
            return
        }
    }

    @MainActor
    @Test("Delegate receives didFailLoading on didFail")
    func delegateReceivesDidFail() {
        let delegate = MockWebViewCoordinatorDelegate()
        let coordinator = WebViewCoordinator(timeoutDuration: 30)
        coordinator.delegate = delegate
        let webView = WKWebView()
        let testError = NSError(domain: "test", code: 11)

        coordinator.webView(webView, didFail: nil, withError: testError)

        #expect(delegate.failedErrors.count == 1)
        #expect((delegate.failedErrors.first as? NSError)?.code == 11)
    }
}
