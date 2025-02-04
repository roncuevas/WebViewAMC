import Foundation
import WebKit

@MainActor
public class WebViewManager: ObservableObject, Sendable {
    public static let shared: WebViewManager = WebViewManager()
    
    public let webView: WKWebView
    private let handlerName: String
    public let coordinator: WebViewCoordinator
    private let configuration: WKWebViewConfiguration
    public let messageHandler: WebViewMessageHandler
    private let userContentController: WKUserContentController
    
    private init(handlerName: String = "myNativeApp",
                coordinator: WebViewCoordinator = WebViewCoordinator(),
                configuration: WKWebViewConfiguration = WKWebViewConfiguration(),
                messageHandler: WebViewMessageHandler = WebViewMessageHandler(),
                userContentController: WKUserContentController = WKUserContentController()) {
        self.handlerName = handlerName
        self.coordinator = coordinator
        self.configuration = configuration
        self.messageHandler = messageHandler
        self.userContentController = userContentController
        
        userContentController.add(messageHandler, name: handlerName)
        configuration.userContentController = userContentController
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        webView.navigationDelegate = coordinator
    }
    
    public func loadURL(url: String, cookies: [HTTPCookie]? = nil) {
        guard let url = URL(string: url) else { return }
        debugPrint("LOADING URL: \(url)")
        let request = URLRequest(url: url)
        if let cookies = cookies {
            for cookie in cookies {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        webView.load(request)
    }
    
    public func injectJavaScript(_ javascript: String) {
        webView.evaluateJavaScript(common)
        webView.evaluateJavaScript(javascript)
    }
    
    private var common: String { """
    var dict = {};
    
    function byID(id) {
      return document.getElementById(id);
    }
    
    function byClass(className) {
      return document.getElementsByClassName(className);
    }
    
    function byTag(tag) {
      return document.getElementsByTagName(tag);
    }
    
    function byName(name) {
      return document.getElementsByName(name);
    }
    
    function bySelector(selector) {
      return document.querySelector(selector);
    }
    
    function bySelectorAll(selector) {
      return document.querySelectorAll(selector);
    }
    
    function postMessage(message) {
        window.webkit.messageHandlers.\(handlerName).postMessage(message);
    }
    
    function imageToData(imageElement, scale) {
        var canvas = document.createElement("canvas");
        var context = canvas.getContext("2d");
        canvas.width = imageElement.width*scale;
        canvas.height = imageElement.height*scale;
        context.drawImage(imageElement, 0, 0);
        var imageData = canvas.toDataURL("image/jpeg");
        return imageData;
    }
    
    function getCaptchaImage() {
        var captchaImage = byID('c_default_ctl00_leftcolumn_loginuser_logincaptcha_CaptchaImage');
        dict["imageData"] = imageToData(captchaImage, 1);
        postMessage(dict);
    }
    
    function getProfileImage() {
        var profileImage = byID('ctl00_mainCopy_Foto');
        dict["profileImageData"] = imageToData(profileImage, 1.5);
        postMessage(dict);
    }
    """
    }
}
