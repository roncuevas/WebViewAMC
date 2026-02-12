import Testing
import WebKit
@testable import WebViewAMC

@Suite("CookieManager")
struct CookieManagerTests {
    @MainActor
    @Test("cookiesForDomain returns empty array when domain is nil")
    func cookiesForDomainNilDomain() {
        let webView = WKWebView()
        let manager = CookieManager(webView: webView, cookieDomain: nil)

        let cookies = manager.cookiesForDomain()
        #expect(cookies.isEmpty)
    }

    @MainActor
    @Test("cookiesForDomain returns empty array for domain with no cookies")
    func cookiesForDomainNoCookies() {
        let webView = WKWebView()
        let domain = URL(string: "https://nocookies.example.com")!
        let manager = CookieManager(webView: webView, cookieDomain: domain)

        let cookies = manager.cookiesForDomain()
        #expect(cookies.isEmpty)
    }

    @MainActor
    @Test("formatForHTTPHeader formats cookies correctly")
    func formatForHTTPHeader() {
        let props1: [HTTPCookiePropertyKey: Any] = [
            .name: "session",
            .value: "abc123",
            .domain: "example.com",
            .path: "/"
        ]
        let props2: [HTTPCookiePropertyKey: Any] = [
            .name: "token",
            .value: "xyz789",
            .domain: "example.com",
            .path: "/"
        ]

        guard let cookie1 = HTTPCookie(properties: props1),
              let cookie2 = HTTPCookie(properties: props2) else {
            Issue.record("Failed to create test cookies")
            return
        }

        let header = CookieManager.formatForHTTPHeader([cookie1, cookie2])
        #expect(header == "session=abc123; token=xyz789")
    }

    @MainActor
    @Test("formatForHTTPHeader returns empty string for empty array")
    func formatForHTTPHeaderEmpty() {
        let header = CookieManager.formatForHTTPHeader([])
        #expect(header == "")
    }

    @MainActor
    @Test("formatForHTTPHeader with single cookie has no separator")
    func formatForHTTPHeaderSingleCookie() {
        let props: [HTTPCookiePropertyKey: Any] = [
            .name: "solo",
            .value: "value",
            .domain: "example.com",
            .path: "/"
        ]

        guard let cookie = HTTPCookie(properties: props) else {
            Issue.record("Failed to create test cookie")
            return
        }

        let header = CookieManager.formatForHTTPHeader([cookie])
        #expect(header == "solo=value")
        #expect(!header.contains(";"))
    }
}
