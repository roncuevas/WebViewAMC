import Foundation
@testable import WebViewAMC

@MainActor
final class MockWebViewLogger: WebViewLoggerProtocol, @unchecked Sendable {
    struct LogEntry: Equatable {
        let level: WebViewLogLevel
        let message: String
        let source: String
    }

    private(set) var entries = [LogEntry]()

    nonisolated func log(_ level: WebViewLogLevel, _ message: String, source: String) {
        MainActor.assumeIsolated {
            entries.append(LogEntry(level: level, message: message, source: source))
        }
    }

    func reset() {
        entries.removeAll()
    }

    func hasMessage(containing text: String) -> Bool {
        entries.contains { $0.message.contains(text) }
    }

    func messages(at level: WebViewLogLevel) -> [LogEntry] {
        entries.filter { $0.level == level }
    }
}
