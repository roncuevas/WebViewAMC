import Testing
@testable import WebViewAMC

@Suite("WebViewTaskManager")
struct WebViewTaskManagerTests {
    private static func makeTask() -> Task<(), any Error> {
        Task { () throws in }
    }

    @MainActor
    @Test("Insert and check task existence")
    func insertAndHasTask() {
        let manager = WebViewTaskManager()
        let task = Self.makeTask()
        manager.insert(key: "test", value: task)

        #expect(manager.hasTask(at: "test") == true)
        #expect(manager.hasTask(at: "nonexistent") == false)
    }

    @MainActor
    @Test("Remove single task")
    func removeSingleTask() {
        let manager = WebViewTaskManager()
        let task = Self.makeTask()
        manager.insert(key: "test", value: task)
        manager.remove(key: "test")

        #expect(manager.hasTask(at: "test") == false)
        #expect(manager.count == 0)
    }

    @MainActor
    @Test("Remove all tasks")
    func removeAllTasks() {
        let manager = WebViewTaskManager()
        manager.insert(key: "a", value: Self.makeTask())
        manager.insert(key: "b", value: Self.makeTask())
        manager.insert(key: "c", value: Self.makeTask())

        manager.removeAll()

        #expect(manager.count == 0)
    }

    @MainActor
    @Test("Remove multiple tasks by keys")
    func removeMultipleByKeys() {
        let manager = WebViewTaskManager()
        manager.insert(key: "a", value: Self.makeTask())
        manager.insert(key: "b", value: Self.makeTask())
        manager.insert(key: "c", value: Self.makeTask())

        manager.remove(["a", "c"])

        #expect(manager.count == 1)
        #expect(manager.hasTask(at: "b") == true)
    }

    @MainActor
    @Test("Keys returns sorted keys")
    func keysAreSorted() {
        let manager = WebViewTaskManager()
        manager.insert(key: "c", value: Self.makeTask())
        manager.insert(key: "a", value: Self.makeTask())
        manager.insert(key: "b", value: Self.makeTask())

        #expect(manager.keys == ["a", "b", "c"])
    }

    @MainActor
    @Test("Count reflects number of tasks")
    func countReflectsSize() {
        let manager = WebViewTaskManager()

        #expect(manager.count == 0)

        manager.insert(key: "x", value: Self.makeTask())
        #expect(manager.count == 1)

        manager.insert(key: "y", value: Self.makeTask())
        #expect(manager.count == 2)
    }

}
