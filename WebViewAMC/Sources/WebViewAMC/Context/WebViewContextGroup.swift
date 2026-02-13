import WebKit

@MainActor
public final class WebViewContextGroup {

    /// The shared process pool used by all contexts in this group.
    public let processPool: WKProcessPool

    private var contexts: [String: WebViewManager] = [:]

    /// Creates a new context group with a shared process pool.
    public init(processPool: WKProcessPool = WKProcessPool()) {
        self.processPool = processPool
    }

    /// Creates and stores a new context with the group's shared process pool.
    @discardableResult
    public func createContext(
        id: String,
        configuration: WebViewConfiguration = .default
    ) -> WebViewManager {
        let manager = WebViewManager(configuration: configuration, processPool: processPool)
        contexts[id] = manager
        return manager
    }

    /// Retrieves a previously created context by identifier.
    public func context(for id: String) -> WebViewManager? {
        contexts[id]
    }

    /// Removes a context from the group.
    @discardableResult
    public func removeContext(_ id: String) -> WebViewManager? {
        contexts.removeValue(forKey: id)
    }

    /// Removes all contexts from the group.
    public func removeAll() {
        contexts.removeAll()
    }

    /// The number of contexts currently in the group.
    public var count: Int {
        contexts.count
    }

    /// The sorted identifiers of all contexts.
    public var ids: [String] {
        contexts.keys.sorted()
    }

    /// Whether a context with the given identifier exists.
    public func hasContext(_ id: String) -> Bool {
        contexts[id] != nil
    }
}
