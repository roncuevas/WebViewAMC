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

    // MARK: - New Tests

    @MainActor
    @Test("Insert with existing key overwrites the task")
    func insertOverwritesExistingKey() {
        let manager = WebViewTaskManager()
        let task1 = Self.makeTask()
        let task2 = Self.makeTask()

        manager.insert(key: "same", value: task1)
        #expect(manager.count == 1)

        manager.insert(key: "same", value: task2)
        #expect(manager.count == 1)
        #expect(manager.hasTask(at: "same") == true)
    }

    @MainActor
    @Test("Remove non-existent key does not crash")
    func removeNonExistentKey() {
        let manager = WebViewTaskManager()
        manager.remove(key: "doesNotExist")
        #expect(manager.count == 0)
    }

    @MainActor
    @Test("Remove multiple with non-existent keys does not crash")
    func removeMultipleNonExistent() {
        let manager = WebViewTaskManager()
        manager.insert(key: "a", value: Self.makeTask())
        manager.remove(["a", "b", "c"])
        #expect(manager.count == 0)
    }

    @MainActor
    @Test("RemoveAll on empty manager does not crash")
    func removeAllEmpty() {
        let manager = WebViewTaskManager()
        manager.removeAll()
        #expect(manager.count == 0)
    }

    @MainActor
    @Test("Keys returns empty array when no tasks")
    func keysEmpty() {
        let manager = WebViewTaskManager()
        #expect(manager.keys.isEmpty)
    }

    @MainActor
    @Test("awaitTask returns immediately for non-existent key")
    func awaitTaskNonExistent() async {
        let manager = WebViewTaskManager()
        await manager.awaitTask(key: "missing")
        // Should return immediately without hanging
    }

    @MainActor
    @Test("awaitTask waits for task completion")
    func awaitTaskCompletion() async {
        let manager = WebViewTaskManager()
        var completed = false
        let task = Task<(), any Error> {
            try await Task.sleep(for: .milliseconds(50))
            completed = true
        }

        manager.insert(key: "wait", value: task)
        await manager.awaitTask(key: "wait")

        #expect(completed == true)
    }

    @MainActor
    @Test("removeAll cancels all tasks")
    func removeAllCancelsTasks() async {
        let manager = WebViewTaskManager()
        let task = Task<(), any Error> {
            try await Task.sleep(for: .seconds(10))
        }

        manager.insert(key: "long", value: task)
        manager.removeAll()

        #expect(task.isCancelled)
    }

    @MainActor
    @Test("remove(keys:) cancels those tasks")
    func removeKeysCancelsTasks() {
        let manager = WebViewTaskManager()
        let task = Task<(), any Error> {
            try await Task.sleep(for: .seconds(10))
        }

        manager.insert(key: "cancel-me", value: task)
        manager.remove(["cancel-me"])

        #expect(task.isCancelled)
    }
}
