import Foundation
import Testing
@testable import WebViewAMC

@Suite("WebViewMessage")
struct WebViewMessageTests {
    @Test("Stores key, rawValue, and value correctly")
    func storesProperties() {
        let message = WebViewMessage(
            key: "greeting",
            rawValue: "hello",
            value: .string("hello")
        )

        #expect(message.key == "greeting")
        #expect(message.rawValue == "hello")
        if case .string(let val) = message.value {
            #expect(val == "hello")
        } else {
            Issue.record("Expected .string value")
        }
    }

    @Test("Supports all WebViewMessageValue cases")
    func allValueCases() {
        let stringMsg = WebViewMessage(key: "s", rawValue: "text", value: .string("text"))
        let boolMsg = WebViewMessage(key: "b", rawValue: "1", value: .bool(true))
        let jsonMsg = WebViewMessage(key: "j", rawValue: "{}", value: .json(Data()))
        let dataMsg = WebViewMessage(key: "d", rawValue: "data:", value: .data(Data()))
        let dictMsg = WebViewMessage(key: "m", rawValue: "{}", value: .dictionary(["k": "v"]))

        if case .string = stringMsg.value {} else { Issue.record("Expected .string") }
        if case .bool = boolMsg.value {} else { Issue.record("Expected .bool") }
        if case .json = jsonMsg.value {} else { Issue.record("Expected .json") }
        if case .data = dataMsg.value {} else { Issue.record("Expected .data") }
        if case .dictionary = dictMsg.value {} else { Issue.record("Expected .dictionary") }
    }
}
