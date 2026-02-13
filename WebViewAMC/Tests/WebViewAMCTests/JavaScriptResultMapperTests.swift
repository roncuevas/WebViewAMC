import Foundation
import Testing
@testable import WebViewAMC

@Suite("JavaScriptResultMapper")
struct JavaScriptResultMapperTests {

    // MARK: - Primitive casting

    @Test("Casts String directly")
    func castString() throws {
        let result: String = try JavaScriptResultMapper.castOrDecode("hello")
        #expect(result == "hello")
    }

    @Test("Casts Int from NSNumber")
    func castInt() throws {
        let result: Int = try JavaScriptResultMapper.castOrDecode(NSNumber(value: 42))
        #expect(result == 42)
    }

    @Test("Casts Double from NSNumber")
    func castDouble() throws {
        let result: Double = try JavaScriptResultMapper.castOrDecode(NSNumber(value: 3.14))
        #expect(result == 3.14)
    }

    @Test("Casts Bool true from NSNumber")
    func castBoolTrue() throws {
        let result: Bool = try JavaScriptResultMapper.castOrDecode(NSNumber(value: true))
        #expect(result == true)
    }

    @Test("Casts Bool false from NSNumber")
    func castBoolFalse() throws {
        let result: Bool = try JavaScriptResultMapper.castOrDecode(NSNumber(value: false))
        #expect(result == false)
    }

    // MARK: - JSON string decoding

    struct Student: Decodable, Equatable {
        let name: String
        let score: Int
    }

    @Test("Decodes Decodable struct from JSON string")
    func decodeFromJSONString() throws {
        let json = "{\"name\":\"Test\",\"score\":95}"
        let result: Student = try JavaScriptResultMapper.castOrDecode(json)
        #expect(result == Student(name: "Test", score: 95))
    }

    @Test("Decodes array from JSON string")
    func decodeArrayFromJSONString() throws {
        let json = "[{\"name\":\"A\",\"score\":90},{\"name\":\"B\",\"score\":80}]"
        let result: [Student] = try JavaScriptResultMapper.castOrDecode(json)
        #expect(result.count == 2)
        #expect(result[0].name == "A")
        #expect(result[1].score == 80)
    }

    // MARK: - Dictionary/Array fallback (JS objects)

    @Test("Decodes Decodable from Dictionary via JSONSerialization")
    func decodeFromDictionary() throws {
        let dict: [String: Any] = ["name": "Test", "score": 95]
        let result: Student = try JavaScriptResultMapper.castOrDecode(dict)
        #expect(result == Student(name: "Test", score: 95))
    }

    @Test("Decodes array of Decodable from Array via JSONSerialization")
    func decodeFromArray() throws {
        let array: [[String: Any]] = [
            ["name": "A", "score": 90],
            ["name": "B", "score": 80]
        ]
        let result: [Student] = try JavaScriptResultMapper.castOrDecode(array)
        #expect(result.count == 2)
    }

    // MARK: - Error cases

    @Test("Nil throws typeCastFailed")
    func nilThrows() {
        #expect(throws: WebViewError.self) {
            let _: String = try JavaScriptResultMapper.castOrDecode(nil)
        }
    }

    @Test("Wrong type throws typeCastFailed")
    func wrongTypeThrows() {
        // NSNumber(42) cannot be cast to String
        #expect(throws: WebViewError.self) {
            let _: String = try JavaScriptResultMapper.castOrDecode(NSNumber(value: 42))
        }
    }

    @Test("Invalid JSON string throws typeCastFailed for Decodable")
    func invalidJSONThrows() {
        #expect(throws: WebViewError.self) {
            let _: Student = try JavaScriptResultMapper.castOrDecode("not json at all")
        }
    }

    // MARK: - Custom decoder

    struct SnakeModel: Decodable, Equatable {
        let firstName: String
        let lastName: String
    }

    @Test("Custom JSONDecoder with snake_case strategy works")
    func customDecoder() throws {
        let json = "{\"first_name\":\"John\",\"last_name\":\"Doe\"}"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result: SnakeModel = try JavaScriptResultMapper.castOrDecode(json, using: decoder)
        #expect(result == SnakeModel(firstName: "John", lastName: "Doe"))
    }
}
