import Foundation

enum JavaScriptResultMapper {
    static func castOrDecode<T: Decodable>(_ value: Any?, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let value else {
            throw WebViewError.typeCastFailed(
                expected: String(describing: T.self),
                actual: "nil"
            )
        }

        // Direct cast (handles String from JS strings)
        if let result = value as? T {
            return result
        }

        // NSNumber handling for numeric types and Bool
        if let number = value as? NSNumber {
            if T.self == Bool.self, let result = number.boolValue as? T {
                return result
            }
            if T.self == Int.self, let result = number.intValue as? T {
                return result
            }
            if T.self == Double.self, let result = number.doubleValue as? T {
                return result
            }
        }

        // JSON string decoding for complex Decodable types
        if let jsonString = value as? String,
           let data = jsonString.data(using: .utf8) {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw WebViewError.typeCastFailed(
                    expected: String(describing: T.self),
                    actual: "JSON decoding failed: \(error.localizedDescription)"
                )
            }
        }

        // Fallback: serialize JS object/array to JSON data, then decode
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                return try decoder.decode(T.self, from: data)
            } catch {
                throw WebViewError.typeCastFailed(
                    expected: String(describing: T.self),
                    actual: "JSON serialization/decoding failed: \(error.localizedDescription)"
                )
            }
        }

        throw WebViewError.typeCastFailed(
            expected: String(describing: T.self),
            actual: String(describing: type(of: value))
        )
    }
}
