// MARK: - Environment
public class Environment {
    private var store: [String: Object] = [:]
    private var outer: Environment?

    public init(outer: Environment? = nil) {
        self.outer = outer
    }

    public func get(_ name: String) -> Object? {
        if let obj = store[name] {
            return obj
        }
        return outer?.get(name)
    }

    public func set(_ name: String, _ val: Object) -> Object {
        store[name] = val
        return val
    }
}
