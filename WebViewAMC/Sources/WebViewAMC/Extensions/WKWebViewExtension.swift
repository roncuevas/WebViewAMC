import WebKit

public extension WKWebView {
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

    func setCookies(_ cookies: [HTTPCookie]) {
        cookies.forEach { cookie in
            self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
    }

    func removeCookies(_ cookies: [HTTPCookie]) {
        cookies.forEach { cookie in
            self.configuration.websiteDataStore.httpCookieStore.delete(cookie)
        }
    }

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
