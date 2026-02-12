import Testing
import Foundation
@testable import WebViewAMC

@Suite("NavigationEvent")
struct NavigationEventTests {
    @Test("started case is Sendable")
    func startedSendable() {
        let event: NavigationEvent = .started
        let _: any Sendable = event
    }

    @Test("finished case carries URL")
    func finishedWithURL() {
        let url = URL(string: "https://example.com")!
        let event: NavigationEvent = .finished(url)
        if case .finished(let u) = event {
            #expect(u == url)
        } else {
            Issue.record("Expected .finished")
        }
    }

    @Test("finished case can carry nil URL")
    func finishedWithNilURL() {
        let event: NavigationEvent = .finished(nil)
        if case .finished(let u) = event {
            #expect(u == nil)
        } else {
            Issue.record("Expected .finished")
        }
    }

    @Test("failed case carries error")
    func failedWithError() {
        let error = NSError(domain: "test", code: 42)
        let event: NavigationEvent = .failed(error)
        if case .failed(let e) = event {
            #expect((e as NSError).code == 42)
        } else {
            Issue.record("Expected .failed")
        }
    }

    @Test("timeout case exists")
    func timeoutCase() {
        let event: NavigationEvent = .timeout
        if case .timeout = event {
            // pass
        } else {
            Issue.record("Expected .timeout")
        }
    }
}
