import WebKit
import os

public extension WKWebView {
    func injectJavaScript(handlerName: String,
                          javaScript: String,
                          verbose: Bool = false) {
        let combinedScript = [Scripts.common(handlerName), Scripts.advanced, javaScript]
            .joined(separator: ";")
        self.evaluateJavaScript(combinedScript) { result, error in
            if let error = error, verbose {
                Logger().error("-> Error executing JavaScript: \(error)")
            }
        }
    }
    
    func loadURL(id: String?,
                 url: String,
                 forceRefresh: Bool = false,
                 cookies: [HTTPCookie]? = nil) {
        guard url != self.url?.absoluteString || forceRefresh else {
            if let id {
                Logger().info("-> ID: \(id) - La URL solicitada coincide con la URL actual \(url)")
            } else {
                Logger().info("-> La URL solicitada coincide con la URL actual \(url)")
            }
            return
        }
        guard let url = URL(string: url) else {
            Logger().error("-> Invalid URL: \(url)")
            return
        }
        if let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://www.saes.escom.ipn.mx/")!) {
            setCookies(cookies)
        }
        self.load(URLRequest(url: url))
        if let id {
            Logger().info("-> Loaded: \(url) from \(id) \nForce refresh: \(forceRefresh)")
        } else {
            Logger().info("-> Loaded: \(url)")
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
