import Foundation

@MainActor
public final class WebViewMessageRouter {
    public typealias MessageHandler = @MainActor (WebViewMessage) -> Void

    private var handlers = [String: MessageHandler]()
    private var fallbackHandler: MessageHandler?

    public init() {}

    public func register(key: String, handler: @escaping MessageHandler) {
        handlers[key] = handler
    }

    public func registerFallback(handler: @escaping MessageHandler) {
        fallbackHandler = handler
    }

    public func unregister(key: String) {
        handlers.removeValue(forKey: key)
    }

    public func unregisterAll() {
        handlers.removeAll()
        fallbackHandler = nil
    }

    public func route(_ message: [String: Any]) {
        for (key, rawValue) in message {
            let decoded = WebViewMessageDecoder.decode(key: key, rawValue: rawValue)
            let webViewMessage = WebViewMessage(
                key: key,
                rawValue: String(describing: rawValue),
                value: decoded
            )

            if let handler = handlers[key] {
                handler(webViewMessage)
            } else {
                fallbackHandler?(webViewMessage)
            }
        }
    }
}
