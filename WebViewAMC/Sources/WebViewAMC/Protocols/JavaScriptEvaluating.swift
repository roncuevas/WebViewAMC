import WebKit

@MainActor
public protocol JavaScriptEvaluating {
    func evaluateJavaScript(_ javaScript: String) async throws -> Any?
    func injectJavaScriptAsync(handlerName: String, defaultJS: [String]?, javaScript: String, verbose: Bool, logger: any WebViewLoggerProtocol) async throws -> Any?
}

extension WKWebView: @preconcurrency JavaScriptEvaluating {}
