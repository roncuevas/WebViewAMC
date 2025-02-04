import WebKit

public class WebViewCoordinator: NSObject, ObservableObject, WKNavigationDelegate {
    public weak var delegate: WebViewCoordinatorDelegate?
        
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            self.delegate?.cookiesReceiver(cookies: cookies)
        }
    }
}

@MainActor
public protocol WebViewCoordinatorDelegate: AnyObject {
    func cookiesReceiver(cookies: [HTTPCookie])
}
