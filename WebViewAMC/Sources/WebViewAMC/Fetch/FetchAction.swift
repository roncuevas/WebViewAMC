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

    public static func once(
        id: String,
        url: String? = nil,
        javaScript: String,
        delay: Duration = .seconds(1),
        cookies: [HTTPCookie]? = nil,
        forceRefresh: Bool = false
    ) -> FetchAction {
        FetchAction(id: id, url: url, javaScript: javaScript,
                    strategy: .once(delay: delay),
                    cookies: cookies, forceRefresh: forceRefresh)
    }

    public static func poll(
        id: String,
        url: String? = nil,
        javaScript: String,
        maxAttempts: Int,
        delay: Duration = .seconds(1),
        cookies: [HTTPCookie]? = nil,
        forceRefresh: Bool = false,
        until: @Sendable @MainActor @escaping () -> Bool
    ) -> FetchAction {
        FetchAction(id: id, url: url, javaScript: javaScript,
                    strategy: .poll(maxAttempts: maxAttempts, delay: delay, until: until),
                    cookies: cookies, forceRefresh: forceRefresh)
    }

    public static func continuous(
        id: String,
        url: String? = nil,
        javaScript: String,
        delay: Duration = .seconds(1),
        cookies: [HTTPCookie]? = nil,
        forceRefresh: Bool = false,
        while condition: @Sendable @MainActor @escaping () -> Bool
    ) -> FetchAction {
        FetchAction(id: id, url: url, javaScript: javaScript,
                    strategy: .continuous(delay: delay, while: condition),
                    cookies: cookies, forceRefresh: forceRefresh)
    }
}
