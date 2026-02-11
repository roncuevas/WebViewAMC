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
}
