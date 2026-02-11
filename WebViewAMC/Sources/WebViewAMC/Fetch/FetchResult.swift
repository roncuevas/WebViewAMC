import Foundation

public enum FetchResult: Sendable {
    case completed(String)
    case cancelled(String)
    case failed(String, WebViewError)
}
