import Combine
import Foundation

public final class WebViewReceiver: WebViewMessageHandlerDelegate, WebViewCoordinatorDelegate {
    public static let shared: WebViewReceiver = WebViewReceiver()
    private init() {}
    
    private let messageSubject = PassthroughSubject<[String: Any], Never>()
    private let cookiesSubject = PassthroughSubject<[HTTPCookie], Never>()
    
    public var messagePublisher: AnyPublisher<[String: Any], Never> {
        messageSubject.eraseToAnyPublisher()
    }
    public var cookiesPublisher: AnyPublisher<[String: Any], Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    public func messageReceiver(message: [String: Any]) {
        messageSubject.send(message)
    }
    
    public func cookiesReceiver(cookies: [HTTPCookie]) {
        cookiesSubject.send(cookies)
    }
}
