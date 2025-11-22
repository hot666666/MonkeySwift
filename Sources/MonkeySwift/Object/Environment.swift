// MARK: - Environment
public final class Environment: @unchecked Sendable {
    private var store: [String: any Object]
    private let outer: Environment?

    public init(outer: Environment? = nil) {
        self.store = [:]
        self.outer = outer
    }

    public func get(_ name: String) -> (any Object)? {
        if let value = store[name] {
            return value
        }
        return outer?.get(name)
    }

    public func set(_ name: String, _ value: any Object) {
        store[name] = value
    }
}
