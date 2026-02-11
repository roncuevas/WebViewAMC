import Foundation

public enum FetchStrategy: Sendable {
    case once(delay: Duration = .seconds(1))
    case poll(maxAttempts: Int, delay: Duration = .seconds(1), until: @Sendable @MainActor () -> Bool)
    case continuous(delay: Duration = .seconds(1), while: @Sendable @MainActor () -> Bool)
}

public struct FetchAction: Sendable {
    public let id: String
    public let url: String?
    public let javaScript: String
    public let strategy: FetchStrategy
    public let cookies: [HTTPCookie]?
    public let forceRefresh: Bool

    public init(id: String,
                url: String? = nil,
                javaScript: String,
                strategy: FetchStrategy = .once(),
                cookies: [HTTPCookie]? = nil,
                forceRefresh: Bool = false) {
        self.id = id
        self.url = url
        self.javaScript = javaScript
        self.strategy = strategy
        self.cookies = cookies
        self.forceRefresh = forceRefresh
    }
}
