import Foundation
import WebKit
@testable import WebViewAMC

@MainActor
final class MockJavaScriptEvaluator: JavaScriptEvaluating {
    var stubbedResult: Any?
    var stubbedError: Error?
    var lastEvaluatedScript: String?
    var lastInjectedScript: String?
    var evaluateCallCount = 0
    var injectCallCount = 0

    func evaluateJavaScript(_ javaScript: String) async throws -> Any? {
        evaluateCallCount += 1
        lastEvaluatedScript = javaScript
        if let error = stubbedError {
            throw error
        }
        return stubbedResult
    }

    func injectJavaScript(handlerName: String, defaultJS: [String]?, javaScript: String, verbose: Bool, logger: any WebViewLoggerProtocol) {
        injectCallCount += 1
        lastInjectedScript = javaScript
    }
}
