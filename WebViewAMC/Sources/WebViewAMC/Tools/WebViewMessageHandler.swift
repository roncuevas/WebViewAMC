import WebKit

public final class WebViewMessageHandler: NSObject, WKScriptMessageHandler {
    public weak var delegate: WebViewMessageHandlerDelegate?
    public var router: WebViewMessageRouter?

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? [String: Any] {
            if let router {
                router.route(message)
            } else {
                delegate?.messageReceiver(message: message)
            }
        }
    }
}

@MainActor
public protocol WebViewMessageHandlerDelegate: AnyObject {
    func messageReceiver(message: [String: Any])
}
