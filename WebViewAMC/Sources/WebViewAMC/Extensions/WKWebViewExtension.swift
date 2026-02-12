import WebKit

public extension WKWebView {
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
        let context = id.map { "[\($0)] " } ?? ""

        guard url != self.url?.absoluteString || forceRefresh else {
            logger.log(.info, "\(context)Requested URL matches current URL \(url)", source: "WKWebView")
            return
        }
        guard let parsedURL = URL(string: url) else {
            logger.log(.error, "\(context)Invalid URL: \(url)", source: "WKWebView")
            return
        }
        if let domain = cookieDomain,
           let domainCookies = HTTPCookieStorage.shared.cookies(for: domain) {
            for cookie in domainCookies {
                self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        if let cookies {
            for cookie in cookies {
                self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        self.load(URLRequest(url: parsedURL))
        logger.log(.info, "\(context)Loaded: \(parsedURL) | Force refresh: \(forceRefresh)", source: "WKWebView")
    }
}
