import Foundation
import Combine

public final class WebViewTaskManager {
    public typealias TaskType = Task<(), any Error>
    
    private var tasks = [String: TaskType]()
    
    public func insert(key: String, value: TaskType) {
        tasks[key] = value
    }
    
    public func remove(key: String) {
        tasks.removeValue(forKey: key)
    }
    
    public var count: Int {
        tasks.count
    }
    
    public func removeAll() {
        tasks.forEach { $0.value.cancel() }
        tasks.removeAll()
    }
    
    public func remove(_ keys: [String]) {
        keys.forEach {
            tasks[$0]?.cancel()
            tasks.removeValue(forKey: $0)
        }
    }
    
    public func getKeys() -> [String] {
        tasks.keys.sorted()
    }
    
    public func hasTask(at key: String) -> Bool {
        tasks[key] != nil
    }
    
    public func getPublisher() -> Publishers.Sequence<[String : WebViewTaskManager.TaskType], Never> {
        return tasks.publisher
    }
}
