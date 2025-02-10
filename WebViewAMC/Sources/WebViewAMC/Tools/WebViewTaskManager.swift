import Foundation

public final class WebViewTaskManager {
    public typealias TaskType = Task<(), any Error>
    
    private var tasks = [UUID: TaskType]()
    
    public func add(key: UUID = UUID(), value: TaskType) {
        tasks[key] = value
    }
    
    public func remove(key: UUID) {
        tasks.removeValue(forKey: key)
    }
    
    public var count: Int {
        tasks.count
    }
}
