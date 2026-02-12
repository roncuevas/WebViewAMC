import Foundation

public enum FetchResult: Sendable, Equatable {
    case completed(String)
    case cancelled(String)
    case failed(String, WebViewError)

    public var id: String {
        switch self {
        case .completed(let id), .cancelled(let id), .failed(let id, _):
            return id
        }
    }

    public var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    public var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }

    public var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    public var error: WebViewError? {
        if case .failed(_, let error) = self { return error }
        return nil
    }
}
