// MARK: - Environment
public class Environment: @unchecked Sendable {
    private var store: [String: any Object] = [:]
    private var outer: Environment?

    public init(outer: Environment? = nil) {
        self.outer = outer
    }

    public func get(_ name: String) -> (any Object)? {
        if let obj = store[name] {
            return obj
        }
        return outer?.get(name)
    }

    public func set(_ name: String, _ val: any Object) -> any Object {
        store[name] = val
        return val
    }
}
