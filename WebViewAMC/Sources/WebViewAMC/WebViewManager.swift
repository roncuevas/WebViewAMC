import Combine
import Foundation
import WebKit

@MainActor
public final class WebViewManager: Sendable, WebViewMessageHandlerDelegate, WebViewCoordinatorDelegate {
    public static let shared = WebViewManager()
    
    public let webView: WKWebView
    public let handlerName = "myNativeApp"
    public let coordinator = WebViewCoordinator()
    public let messageHandler = WebViewMessageHandler()
    
    private let messageSubject = PassthroughSubject<[String: Any], Never>()
    private let cookiesSubject = PassthroughSubject<[HTTPCookie], Never>()
    
    public var messagePublisher: AnyPublisher<[String: Any], Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    public var cookiesPublisher: AnyPublisher<[HTTPCookie], Never> {
        cookiesSubject.eraseToAnyPublisher()
    }
    
    private init() {
        // Configuración del controlador de contenido
        let userContentController = WKUserContentController()
        userContentController.add(messageHandler, name: handlerName)
        
        // Configuración del WKWebView
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        // Asignación de delegados
        webView.navigationDelegate = coordinator
        coordinator.delegate = self
        messageHandler.delegate = self
    }
    
    // MARK: - WebViewMessageHandlerDelegate & WebViewCoordinatorDelegate
    
    public func messageReceiver(message: [String: Any]) {
        messageSubject.send(message)
    }
    
    public func cookiesReceiver(cookies: [HTTPCookie]) {
        cookiesSubject.send(cookies)
    }
}

// MARK: - Métodos públicos

public extension WebViewManager {
    func loadURL(url: String, cookies: [HTTPCookie]? = nil) {
        guard let url = URL(string: url) else {
            print("URL inválido: \(url)")
            return
        }
        
        // Inyecta las cookies (si las hay)
        cookies?.forEach { cookie in
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
        
        webView.load(URLRequest(url: url))
    }
    
    func injectJavaScript(_ javascript: String) {
        // Combina los scripts: el común, el avanzado y el script adicional
        let combinedScript = [Scripts.common(handlerName), Scripts.advanced, javascript]
            .joined(separator: ";")
        
        webView.evaluateJavaScript(combinedScript) { result, error in
            if let error = error {
                print("Error ejecutando JavaScript: \(error)")
            }
        }
    }
    
    func getById(id: String) {
        // Aquí se asume que se desea obtener un elemento por id.
        // Se podría tener un script específico en 'Scripts' para esta tarea, por ejemplo:
        // let script = Scripts.getElementById(id)
        // webView.evaluateJavaScript(script) { ... }
        // Por ahora, simplemente se inyecta el script común.
        webView.evaluateJavaScript(Scripts.common(handlerName)) { result, error in
            if let error = error {
                print("Error en getById: \(error)")
            }
        }
    }
}
