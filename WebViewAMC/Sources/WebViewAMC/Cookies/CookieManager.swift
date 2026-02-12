import Foundation
import WebKit

@MainActor
public final class CookieManager {
    private let webView: WKWebView
    private let cookieDomain: URL?

    public init(webView: WKWebView, cookieDomain: URL? = nil) {
        self.webView = webView
        self.cookieDomain = cookieDomain
    }

    public func setCookiesSync(_ cookies: [HTTPCookie]) {
        for cookie in cookies {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
    }

    public func injectCookies(_ cookies: [HTTPCookie]) async {
        for cookie in cookies {
            await webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
    }

    public func removeCookies(named names: [String]) async {
        let allCookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        let filtered = allCookies.filter { names.contains($0.name) }
        for cookie in filtered {
            await webView.configuration.websiteDataStore.httpCookieStore.deleteCookie(cookie)
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }

    public func removeAllCookies() async {
        let allCookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        for cookie in allCookies {
            await webView.configuration.websiteDataStore.httpCookieStore.deleteCookie(cookie)
        }
    }

    public func getAllCookies() async -> [HTTPCookie] {
        await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
    }

    public func cookiesForDomain() -> [HTTPCookie] {
        guard let domain = cookieDomain else { return [] }
        return HTTPCookieStorage.shared.cookies(for: domain) ?? []
    }

    public static func formatForHTTPHeader(_ cookies: [HTTPCookie]) -> String {
        cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }
}
