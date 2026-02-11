import Foundation
import os

public enum WebViewLogLevel: Int, Sendable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: WebViewLogLevel, rhs: WebViewLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public protocol WebViewLoggerProtocol: Sendable {
    func log(_ level: WebViewLogLevel, _ message: String, source: String)
}

public extension WebViewLoggerProtocol {
    func log(_ level: WebViewLogLevel, _ message: String) {
        log(level, message, source: "WebViewAMC")
    }
}

public struct WebViewLogger: WebViewLoggerProtocol {
    private let osLogger: os.Logger
    private let minimumLevel: WebViewLogLevel

    public init(subsystem: String = "WebViewAMC",
                category: String = "General",
                minimumLevel: WebViewLogLevel = .info) {
        self.osLogger = os.Logger(subsystem: subsystem, category: category)
        self.minimumLevel = minimumLevel
    }

    public func log(_ level: WebViewLogLevel, _ message: String, source: String) {
        guard level >= minimumLevel else { return }
        switch level {
        case .debug:
            osLogger.debug("[\(source)] \(message)")
        case .info:
            osLogger.info("[\(source)] \(message)")
        case .warning:
            osLogger.warning("[\(source)] \(message)")
        case .error:
            osLogger.error("[\(source)] \(message)")
        }
    }
}
