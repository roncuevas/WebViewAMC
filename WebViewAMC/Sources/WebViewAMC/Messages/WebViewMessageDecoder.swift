import Foundation

public struct WebViewMessageDecoder: Sendable {
    public init() {}

    public static func decode(key: String, rawValue: Any) -> WebViewMessageValue {
        if let dict = rawValue as? [String: String] {
            return .dictionary(dict)
        }

        let stringValue = String(describing: rawValue)

        if isBase64DataURI(stringValue), let data = decodeDataURI(stringValue) {
            return .data(data)
        }

        if isJSONString(stringValue), let data = stringValue.data(using: .utf8) {
            return .json(data)
        }

        if stringValue == "0" {
            return .bool(false)
        }

        if stringValue == "1" {
            return .bool(true)
        }

        return .string(stringValue)
    }

    static func isBase64DataURI(_ string: String) -> Bool {
        string.hasPrefix("data:")
    }

    static func decodeDataURI(_ string: String) -> Data? {
        guard let commaIndex = string.firstIndex(of: ",") else { return nil }
        let base64String = String(string[string.index(after: commaIndex)...])
        return Data(base64Encoded: base64String)
    }

    private static func isJSONString(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("[") || trimmed.hasPrefix("{")
    }
}
