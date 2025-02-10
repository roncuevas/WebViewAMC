import WebKit

public extension WKWebView {
    func injectJavaScript(handlerName: String,
                          javaScript: String,
                          verbose: Bool = false) {
        let combinedScript = [Scripts.common(handlerName), Scripts.advanced, javaScript]
            .joined(separator: ";")
        self.evaluateJavaScript(combinedScript) { result, error in
            if let error = error, verbose {
                print("-> Error executing JavaScript: \(error)")
            }
        }
    }
    
    func loadURL(url: String, cookies: [HTTPCookie]? = nil) {
        guard let url = URL(string: url) else {
            print("-> Invalid URL: \(url)")
            return
        }
        cookies?.forEach { cookie in
            self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
        self.load(URLRequest(url: url))
    }
}
