import Foundation

public enum WebViewError: Error, Sendable, Equatable {
    case invalidURL(String)
    case javaScriptEvaluation(String)
    case timeout
    case navigationFailed(String)
    case taskCancelled(String)
    case fetchFailed(String)
    case messageDecodingFailed(String)
}

extension WebViewError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .javaScriptEvaluation(let detail):
            return "JavaScript evaluation failed: \(detail)"
        case .timeout:
            return "Request timed out"
        case .navigationFailed(let detail):
            return "Navigation failed: \(detail)"
        case .taskCancelled(let id):
            return "Task cancelled: \(id)"
        case .fetchFailed(let detail):
            return "Fetch failed: \(detail)"
        case .messageDecodingFailed(let detail):
            return "Message decoding failed: \(detail)"
        }
    }
}
