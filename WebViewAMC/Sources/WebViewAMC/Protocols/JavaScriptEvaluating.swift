import WebKit

@MainActor
public protocol JavaScriptEvaluating {
    func evaluateJavaScript(_ javaScript: String) async throws -> Any?
    func injectJavaScript(handlerName: String, defaultJS: [String]?, javaScript: String, verbose: Bool, logger: any WebViewLoggerProtocol)
}

extension WKWebView: @preconcurrency JavaScriptEvaluating {}
