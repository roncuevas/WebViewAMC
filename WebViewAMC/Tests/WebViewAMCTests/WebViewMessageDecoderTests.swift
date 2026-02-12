import Testing
@testable import WebViewAMC

@Suite("WebViewMessageDecoder")
struct WebViewMessageDecoderTests {
    @Test("Decodes plain string")
    func decodePlainString() {
        let result = WebViewMessageDecoder.decode(key: "name", rawValue: "hello")
        guard case .string(let value) = result else {
            Issue.record("Expected .string, got \(result)")
            return
        }
        #expect(value == "hello")
    }

    @Test("Decodes bool true from '1'")
    func decodeBoolTrue() {
        let result = WebViewMessageDecoder.decode(key: "flag", rawValue: "1")
        guard case .bool(let value) = result else {
            Issue.record("Expected .bool, got \(result)")
            return
        }
        #expect(value == true)
    }

    @Test("Decodes bool false from '0'")
    func decodeBoolFalse() {
        let result = WebViewMessageDecoder.decode(key: "flag", rawValue: "0")
        guard case .bool(let value) = result else {
            Issue.record("Expected .bool, got \(result)")
            return
        }
        #expect(value == false)
    }

    @Test("Decodes JSON object string")
    func decodeJSONObject() {
        let jsonString = "{\"name\":\"test\"}"
        let result = WebViewMessageDecoder.decode(key: "data", rawValue: jsonString)
        guard case .json(let data) = result else {
            Issue.record("Expected .json, got \(result)")
            return
        }
        #expect(data.count > 0)
    }

    @Test("Decodes JSON array string")
    func decodeJSONArray() {
        let jsonString = "[1,2,3]"
        let result = WebViewMessageDecoder.decode(key: "items", rawValue: jsonString)
        guard case .json(let data) = result else {
            Issue.record("Expected .json, got \(result)")
            return
        }
        #expect(data.count > 0)
    }

    @Test("Decodes base64 data URI")
    func decodeDataURI() {
        let dataURI = "data:image/jpeg;base64,/9j/4AAQ"
        let result = WebViewMessageDecoder.decode(key: "image", rawValue: dataURI)
        guard case .data = result else {
            Issue.record("Expected .data, got \(result)")
            return
        }
    }

    @Test("Decodes dictionary")
    func decodeDictionary() {
        let dict: [String: String] = ["key1": "val1", "key2": "val2"]
        let result = WebViewMessageDecoder.decode(key: "meta", rawValue: dict)
        guard case .dictionary(let value) = result else {
            Issue.record("Expected .dictionary, got \(result)")
            return
        }
        #expect(value["key1"] == "val1")
        #expect(value["key2"] == "val2")
    }

    @Test("Empty string decodes as string")
    func decodeEmptyString() {
        let result = WebViewMessageDecoder.decode(key: "empty", rawValue: "")
        guard case .string(let value) = result else {
            Issue.record("Expected .string, got \(result)")
            return
        }
        #expect(value == "")
    }

    @Test("isBase64DataURI detects data: prefix")
    func isBase64DataURI() {
        #expect(WebViewMessageDecoder.isBase64DataURI("data:image/png;base64,abc") == true)
        #expect(WebViewMessageDecoder.isBase64DataURI("not-data") == false)
    }

    @Test("decodeDataURI returns nil for malformed URI")
    func decodeDataURIMalformed() {
        let result = WebViewMessageDecoder.decodeDataURI("data:nope")
        #expect(result == nil)
    }

    // MARK: - Edge Cases

    @Test("JSON with leading whitespace still detected as JSON")
    func jsonWithWhitespace() {
        let result = WebViewMessageDecoder.decode(key: "data", rawValue: "  {\"a\":1}")
        guard case .json = result else {
            Issue.record("Expected .json for whitespace-prefixed JSON, got \(result)")
            return
        }
    }

    @Test("JSON array with leading whitespace still detected as JSON")
    func jsonArrayWithWhitespace() {
        let result = WebViewMessageDecoder.decode(key: "data", rawValue: "  [1,2]")
        guard case .json = result else {
            Issue.record("Expected .json for whitespace-prefixed array, got \(result)")
            return
        }
    }

    @Test("Numeric value 2 decodes as string, not bool")
    func numericNonBoolValue() {
        let result = WebViewMessageDecoder.decode(key: "num", rawValue: "2")
        guard case .string(let value) = result else {
            Issue.record("Expected .string for '2', got \(result)")
            return
        }
        #expect(value == "2")
    }

    @Test("Integer 0 decodes as bool false via String(describing:)")
    func integerZero() {
        let result = WebViewMessageDecoder.decode(key: "val", rawValue: 0)
        guard case .bool(let value) = result else {
            Issue.record("Expected .bool for integer 0, got \(result)")
            return
        }
        #expect(value == false)
    }

    @Test("Integer 1 decodes as bool true via String(describing:)")
    func integerOne() {
        let result = WebViewMessageDecoder.decode(key: "val", rawValue: 1)
        guard case .bool(let value) = result else {
            Issue.record("Expected .bool for integer 1, got \(result)")
            return
        }
        #expect(value == true)
    }

    @Test("Data URI with invalid base64 falls back to string")
    func invalidBase64DataURI() {
        let result = WebViewMessageDecoder.decode(key: "img", rawValue: "data:image/png;base64,!!!invalid!!!")
        // Invalid base64 returns nil from Data(base64Encoded:), so should not decode as .data
        guard case .string = result else {
            Issue.record("Expected .string for invalid base64 data URI, got \(result)")
            return
        }
    }

    @Test("Empty JSON object decodes as JSON")
    func emptyJSONObject() {
        let result = WebViewMessageDecoder.decode(key: "empty", rawValue: "{}")
        guard case .json = result else {
            Issue.record("Expected .json for '{}', got \(result)")
            return
        }
    }

    @Test("Empty JSON array decodes as JSON")
    func emptyJSONArray() {
        let result = WebViewMessageDecoder.decode(key: "empty", rawValue: "[]")
        guard case .json = result else {
            Issue.record("Expected .json for '[]', got \(result)")
            return
        }
    }

    @Test("Dictionary takes priority over other decodings")
    func dictionaryPriority() {
        // A [String: String] dict should be caught before String(describing:) conversion
        let dict: [String: String] = ["0": "zero"]
        let result = WebViewMessageDecoder.decode(key: "k", rawValue: dict)
        guard case .dictionary = result else {
            Issue.record("Expected .dictionary, got \(result)")
            return
        }
    }

    @Test("Unicode string decodes correctly")
    func unicodeString() {
        let result = WebViewMessageDecoder.decode(key: "text", rawValue: "Hola mundo")
        guard case .string(let value) = result else {
            Issue.record("Expected .string, got \(result)")
            return
        }
        #expect(value == "Hola mundo")
    }

    @Test("Data URI with empty payload returns empty Data")
    func dataURIEmptyPayload() {
        let result = WebViewMessageDecoder.decodeDataURI("data:text/plain;base64,")
        #expect(result != nil)
        #expect(result?.count == 0)
    }
}
