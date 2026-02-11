import Foundation
import Testing
@testable import WebViewAMC

@Suite("WebViewConfiguration")
struct WebViewConfigurationTests {
    @Test("Default configuration has expected values")
    func defaultValues() {
        let config = WebViewConfiguration.default

        #expect(config.handlerName == "myNativeApp")
        #expect(config.timeoutDuration == 30.0)
        #expect(config.isInspectable == false)
        #expect(config.cookieDomain == nil)
        #expect(config.verbose == false)
    }

    @Test("Custom configuration stores values")
    func customValues() {
        let domain = URL(string: "https://example.com")!
        let config = WebViewConfiguration(
            handlerName: "customHandler",
            timeoutDuration: 60.0,
            isInspectable: true,
            cookieDomain: domain,
            verbose: true
        )

        #expect(config.handlerName == "customHandler")
        #expect(config.timeoutDuration == 60.0)
        #expect(config.isInspectable == true)
        #expect(config.cookieDomain == domain)
        #expect(config.verbose == true)
    }

    @Test("Init with defaults matches static default")
    func initDefaultsMatchStatic() {
        let config = WebViewConfiguration()
        let defaultConfig = WebViewConfiguration.default

        #expect(config.handlerName == defaultConfig.handlerName)
        #expect(config.timeoutDuration == defaultConfig.timeoutDuration)
        #expect(config.isInspectable == defaultConfig.isInspectable)
        #expect(config.verbose == defaultConfig.verbose)
    }
}
