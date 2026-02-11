import Foundation

public struct DataFetchRequest: Sendable {
    let id: String
    let url: String?
    let forceRefresh: Bool
    let javaScript: String
    let delayToLoad: UInt64
    let delayToFetch: UInt64
    let delayToNextRequest: UInt64
    let verbose: Bool
    let iterations: Int?
    let cookies: [HTTPCookie]?
    let condition: (@Sendable @MainActor () -> Bool)?

    public init(id: String,
                url: String? = nil,
                forceRefresh: Bool = false,
                javaScript: String,
                delayToLoad: UInt64 = 0,
                delayToFetch: UInt64 = 1_000_000_000,
                delayToNextRequest: UInt64 = 1_000_000_000,
                verbose: Bool = true,
                iterations: Int? = nil,
                cookies: [HTTPCookie]? = nil,
                condition: (@Sendable @MainActor () -> Bool)? = nil) {
        self.id = id
        self.url = url
        self.forceRefresh = forceRefresh
        self.javaScript = javaScript
        self.delayToLoad = delayToLoad
        self.delayToFetch = delayToFetch
        self.delayToNextRequest = delayToNextRequest
        self.verbose = verbose
        self.iterations = iterations
        self.cookies = cookies
        self.condition = condition
    }

    public func toFetchAction() -> FetchAction {
        let strategy: FetchStrategy
        if let iterations, let condition {
            strategy = .poll(maxAttempts: iterations, delay: .nanoseconds(delayToNextRequest), until: condition)
        } else if let condition {
            strategy = .continuous(delay: .nanoseconds(delayToNextRequest), while: condition)
        } else {
            strategy = .once(delay: .nanoseconds(delayToFetch))
        }
        return FetchAction(
            id: id,
            url: url,
            javaScript: javaScript,
            strategy: strategy,
            cookies: cookies,
            forceRefresh: forceRefresh
        )
    }
}
