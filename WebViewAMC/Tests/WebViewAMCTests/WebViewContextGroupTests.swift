import Testing
import WebKit
@testable import WebViewAMC

@Suite("WebViewContextGroup")
struct WebViewContextGroupTests {

    // MARK: - Initialization

    @MainActor
    @Test("Default init creates empty group with process pool")
    func defaultInit() {
        let group = WebViewContextGroup()
        #expect(group.count == 0)
        #expect(group.ids.isEmpty)
    }

    @MainActor
    @Test("Custom process pool is stored")
    func customProcessPool() {
        let pool = WKProcessPool()
        let group = WebViewContextGroup(processPool: pool)
        #expect(group.processPool === pool)
    }

    // MARK: - Context Creation

    @MainActor
    @Test("createContext adds a context with the given id")
    func createContextAdds() {
        let group = WebViewContextGroup()
        let manager = group.createContext(id: "first")

        #expect(group.count == 1)
        #expect(group.hasContext("first"))
        #expect(group.context(for: "first") === manager)
    }

    @MainActor
    @Test("createContext uses the group's shared process pool")
    func createContextSharesPool() {
        let group = WebViewContextGroup()
        let manager1 = group.createContext(id: "a")
        let manager2 = group.createContext(id: "b")

        #expect(manager1.webView.configuration.processPool === group.processPool)
        #expect(manager2.webView.configuration.processPool === group.processPool)
        #expect(manager1.webView.configuration.processPool === manager2.webView.configuration.processPool)
    }

    @MainActor
    @Test("createContext with custom configuration passes it through")
    func createContextCustomConfig() {
        let group = WebViewContextGroup()
        let config = WebViewConfiguration(handlerName: "custom", timeoutDuration: 60)
        let manager = group.createContext(id: "custom", configuration: config)

        #expect(manager.configuration.handlerName == "custom")
        #expect(manager.configuration.timeoutDuration == 60)
    }

    @MainActor
    @Test("createContext with duplicate id replaces existing context")
    func createContextReplacesDuplicate() {
        let group = WebViewContextGroup()
        let first = group.createContext(id: "dup")
        let second = group.createContext(id: "dup")

        #expect(group.count == 1)
        #expect(group.context(for: "dup") === second)
        #expect(group.context(for: "dup") !== first)
    }

    @MainActor
    @Test("Multiple contexts have independent components")
    func contextsHaveIndependentComponents() {
        let group = WebViewContextGroup()
        let a = group.createContext(id: "a")
        let b = group.createContext(id: "b")

        #expect(a.webView !== b.webView)
        #expect(a.coordinator !== b.coordinator)
        #expect(a.handler !== b.handler)
    }

    // MARK: - Context Lookup

    @MainActor
    @Test("context(for:) returns nil for non-existent id")
    func contextForNonExistent() {
        let group = WebViewContextGroup()
        #expect(group.context(for: "missing") == nil)
    }

    @MainActor
    @Test("hasContext returns false for non-existent id")
    func hasContextFalse() {
        let group = WebViewContextGroup()
        #expect(group.hasContext("nope") == false)
    }

    // MARK: - Context Removal

    @MainActor
    @Test("removeContext removes and returns the context")
    func removeContextReturns() {
        let group = WebViewContextGroup()
        let manager = group.createContext(id: "remove-me")

        let removed = group.removeContext("remove-me")
        #expect(removed === manager)
        #expect(group.count == 0)
        #expect(group.hasContext("remove-me") == false)
    }

    @MainActor
    @Test("removeContext returns nil for non-existent id")
    func removeContextNil() {
        let group = WebViewContextGroup()
        let removed = group.removeContext("missing")
        #expect(removed == nil)
    }

    @MainActor
    @Test("removeAll clears all contexts")
    func removeAllClears() {
        let group = WebViewContextGroup()
        group.createContext(id: "a")
        group.createContext(id: "b")
        group.createContext(id: "c")

        group.removeAll()

        #expect(group.count == 0)
        #expect(group.ids.isEmpty)
    }

    @MainActor
    @Test("removeAll on empty group does not crash")
    func removeAllEmpty() {
        let group = WebViewContextGroup()
        group.removeAll()
        #expect(group.count == 0)
    }

    // MARK: - Ids

    @MainActor
    @Test("ids returns sorted identifiers")
    func idsSorted() {
        let group = WebViewContextGroup()
        group.createContext(id: "c")
        group.createContext(id: "a")
        group.createContext(id: "b")

        #expect(group.ids == ["a", "b", "c"])
    }

    // MARK: - Process Pool Isolation

    @MainActor
    @Test("Two separate groups have different process pools")
    func separateGroupsDifferentPools() {
        let group1 = WebViewContextGroup()
        let group2 = WebViewContextGroup()

        let m1 = group1.createContext(id: "a")
        let m2 = group2.createContext(id: "a")

        #expect(m1.webView.configuration.processPool !== m2.webView.configuration.processPool)
    }

    @MainActor
    @Test("Groups can share the same process pool explicitly")
    func groupsShareExplicitPool() {
        let pool = WKProcessPool()
        let group1 = WebViewContextGroup(processPool: pool)
        let group2 = WebViewContextGroup(processPool: pool)

        let m1 = group1.createContext(id: "a")
        let m2 = group2.createContext(id: "a")

        #expect(m1.webView.configuration.processPool === m2.webView.configuration.processPool)
    }
}
