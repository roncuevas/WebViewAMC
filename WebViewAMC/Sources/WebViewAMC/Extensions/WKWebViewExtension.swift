import WebKit

public extension WKWebView {
    @available(*, deprecated, message: "Use injectJavaScriptAsync instead")
    func injectJavaScript(handlerName: String,
                          defaultJS: [String]?,
                          javaScript: String,
                          verbose: Bool = false,
                          logger: any WebViewLoggerProtocol = WebViewLogger()) {
        var combinedScript = [Scripts.common(handlerName)]
        combinedScript.append(contentsOf: defaultJS ?? [])
        combinedScript.append(javaScript)
        self.evaluateJavaScript(combinedScript.joined(separator: ";")) { _, error in
            if let error = error, verbose {
                logger.log(.error, "Error executing JavaScript: \(error)", source: "WKWebView")
            }
        }
    }

    @discardableResult
    func injectJavaScriptAsync(handlerName: String,
                               defaultJS: [String]? = nil,
                               javaScript: String,
                               verbose: Bool = false,
                               logger: any WebViewLoggerProtocol = WebViewLogger()) async throws -> Any? {
        var combinedScript = [Scripts.common(handlerName)]
        combinedScript.append(contentsOf: defaultJS ?? [])
        combinedScript.append(javaScript)
        do {
            return try await self.evaluateJavaScript(combinedScript.joined(separator: ";"))
        } catch {
            if verbose {
                logger.log(.error, "Error executing JavaScript: \(error)", source: "WKWebView")
            }
            throw error
        }
    }

    func loadURL(id: String?,
                 url: String,
                 forceRefresh: Bool = false,
                 cookies: [HTTPCookie]? = nil,
                 cookieDomain: URL? = nil,
                 logger: any WebViewLoggerProtocol = WebViewLogger()) {
        guard url != self.url?.absoluteString || forceRefresh else {
            if let id {
                logger.log(.info, "ID: \(id) - Requested URL matches current URL \(url)", source: "WKWebView")
            } else {
                logger.log(.info, "Requested URL matches current URL \(url)", source: "WKWebView")
            }
            return
        }
        guard let parsedURL = URL(string: url) else {
            logger.log(.error, "Invalid URL: \(url)", source: "WKWebView")
            return
        }
        if let domain = cookieDomain,
           let domainCookies = HTTPCookieStorage.shared.cookies(for: domain) {
            setCookies(domainCookies)
        }
        if let cookies {
            setCookies(cookies)
        }
        self.load(URLRequest(url: parsedURL))
        if let id {
            logger.log(.info, "Loaded: \(parsedURL) from \(id) | Force refresh: \(forceRefresh)", source: "WKWebView")
        } else {
            logger.log(.info, "Loaded: \(parsedURL)", source: "WKWebView")
        }
    }

    @available(*, deprecated, message: "Use CookieManager.setCookiesSync or CookieManager.injectCookies instead")
    func setCookies(_ cookies: [HTTPCookie]) {
        cookies.forEach { cookie in
            self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
    }

    @available(*, deprecated, message: "Use CookieManager.removeAllCookies instead")
    func removeCookies(_ cookies: [HTTPCookie]) {
        cookies.forEach { cookie in
            self.configuration.websiteDataStore.httpCookieStore.delete(cookie)
        }
    }

    @available(*, deprecated, message: "Use CookieManager.removeCookies(named:) instead")
    func removeCookies(_ cookieNames: [String]) {
        self.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let cookiesFiltered = cookies.filter { cookieNames.contains($0.name) }
            cookiesFiltered.forEach {
                self.configuration.websiteDataStore.httpCookieStore.delete($0)
                HTTPCookieStorage.shared.deleteCookie($0)
            }
        }
    }
}
