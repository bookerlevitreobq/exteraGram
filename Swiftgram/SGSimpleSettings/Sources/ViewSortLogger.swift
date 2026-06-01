import Foundation

public class SGViewSortLogger {
    public static let shared = SGViewSortLogger()
    private var entries: [String] = []
    private let lock = NSLock()
    private let maxEntries = 1000
    
    private init() {}
    
    public func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        lock.lock()
        entries.append("[\(timestamp)] \(message)")
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        lock.unlock()
        print("SGViewSort: \(message)")
    }
    
    public func clear() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }
    
    public func copyToClipboard() -> String {
        lock.lock()
        let result = entries.joined(separator: "\n")
        lock.unlock()
        return result
    }
    
    public var count: Int {
        lock.lock()
        let c = entries.count
        lock.unlock()
        return c
    }
}
