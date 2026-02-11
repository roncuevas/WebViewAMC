import Foundation

public struct WebViewConfiguration: Sendable {
    public let handlerName: String
    public let timeoutDuration: TimeInterval
    public let isInspectable: Bool
    public let cookieDomain: URL?
    public let verbose: Bool
    public let logger: any WebViewLoggerProtocol

    public init(handlerName: String = "myNativeApp",
                timeoutDuration: TimeInterval = 30.0,
                isInspectable: Bool = false,
                cookieDomain: URL? = nil,
                verbose: Bool = false,
                logger: any WebViewLoggerProtocol = WebViewLogger()) {
        self.handlerName = handlerName
        self.timeoutDuration = timeoutDuration
        self.isInspectable = isInspectable
        self.cookieDomain = cookieDomain
        self.verbose = verbose
        self.logger = logger
    }

    public static let `default` = WebViewConfiguration()
}
