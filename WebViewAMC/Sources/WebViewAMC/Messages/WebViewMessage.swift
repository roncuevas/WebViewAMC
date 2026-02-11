import Foundation

public enum WebViewMessageValue: Sendable {
    case string(String)
    case bool(Bool)
    case json(Data)
    case data(Data)
    case dictionary([String: String])
}

public struct WebViewMessage: Sendable {
    public let key: String
    public let rawValue: String
    public let value: WebViewMessageValue

    public init(key: String, rawValue: String, value: WebViewMessageValue) {
        self.key = key
        self.rawValue = rawValue
        self.value = value
    }
}
