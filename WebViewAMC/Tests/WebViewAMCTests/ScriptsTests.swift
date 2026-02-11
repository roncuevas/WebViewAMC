import Testing
@testable import WebViewAMC

@Suite("Scripts")
struct ScriptsTests {
    @Test("common() interpolates handler name")
    func commonInterpolatesHandlerName() {
        let script = Scripts.common("myHandler")

        #expect(script.contains("myHandler"))
        #expect(script.contains("window.webkit.messageHandlers.myHandler.postMessage"))
    }

    @Test("common() includes helper functions")
    func commonIncludesHelpers() {
        let script = Scripts.common("test")

        #expect(script.contains("function byID("))
        #expect(script.contains("function byClass("))
        #expect(script.contains("function byTag("))
        #expect(script.contains("function byName("))
        #expect(script.contains("function bySelector("))
        #expect(script.contains("function bySelectorAll("))
        #expect(script.contains("function imageToData("))
        #expect(script.contains("function postMessage("))
    }

    @Test("common() includes dict variable")
    func commonIncludesDict() {
        let script = Scripts.common("handler")
        #expect(script.contains("var dict = {};"))
    }

    @Test("custom() includes common and additional helpers")
    func customIncludesAdditional() {
        let script = Scripts.custom(
            handlerName: "app",
            additionalHelpers: ["function helper1() {}", "function helper2() {}"]
        )

        #expect(script.contains("function byID("))
        #expect(script.contains("function helper1()"))
        #expect(script.contains("function helper2()"))
    }

    @Test("custom() with no additional helpers equals common")
    func customWithNoHelpers() {
        let common = Scripts.common("handler")
        let custom = Scripts.custom(handlerName: "handler")

        #expect(common == custom)
    }
}
