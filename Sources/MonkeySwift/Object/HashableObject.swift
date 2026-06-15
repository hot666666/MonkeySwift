// MARK: - HashKey & HashableObject
public struct HashKey: Hashable, Sendable {
    public let type: ObjectType
    public let value: Int

    public init(type: ObjectType, value: Int) {
        self.type = type
        self.value = value
    }
}

public protocol HashableObject: Object {
    func hashKey() -> HashKey
}

// MARK: - HashableObject Extensions(StringObject, Integer, Boolean)
extension StringObject: HashableObject {
    public func hashKey() -> HashKey {
        return HashKey(type: type, value: value.hashValue)
    }
}

extension Integer: HashableObject {
    public func hashKey() -> HashKey {
        return HashKey(type: type, value: value)
    }
}

extension Boolean: HashableObject {
    public func hashKey() -> HashKey {
        return HashKey(type: type, value: value ? 1 : 0)
    }
}
