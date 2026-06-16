// MARK: - Object Protocol
/// Object는 모든 타입의 데이터를 표현하는 인터페이스입니다.
public protocol Object: Sendable {
    var type: ObjectType { get }
    func inspect() -> String
}

// MARK: - Object Type
public enum ObjectType: String, Sendable {
    case integer = "INTEGER"
    case string = "STRING"
    case boolean = "BOOLEAN"
    case null = "NULL"
    case returnValue = "RETURN_VALUE"
    case error = "ERROR"
    case function = "FUNCTION"
    case array = "ARRAY"
    case hashMap = "HASHMAP"
    case builtin = "BUILTIN"
}

// MARK: - StringObject
public struct StringObject: Object {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public var type: ObjectType { .string }

    public func inspect() -> String {
        return value
    }
}

// MARK: - Integer
public struct Integer: Object {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }

    public var type: ObjectType { .integer }

    public func inspect() -> String {
        return "\(value)"
    }
}

// MARK: - Boolean
public struct Boolean: Object {
    public let value: Bool

    public init(value: Bool) {
        self.value = value
    }

    public var type: ObjectType { .boolean }

    public func inspect() -> String {
        return "\(value)"
    }
}

// MARK: - Null
public struct Null: Object {
    public init() {}

    public var type: ObjectType { .null }

    public func inspect() -> String {
        return "null"
    }
}

// MARK: - Return Value
public struct ReturnValue: Object {
    public let value: any Object

    public init(value: any Object) {
        self.value = value
    }

    public var type: ObjectType { .returnValue }

    public func inspect() -> String {
        return value.inspect()
    }
}

// MARK: - Error
public struct ErrorObject: Object {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var type: ObjectType { .error }

    public func inspect() -> String {
        return "ERROR: \(message)"
    }
}

// MARK: - Function
public struct Function: Object {
    public let parameters: [Identifier]
    public let body: BlockStatement
    public let environment: Environment

    public init(parameters: [Identifier], body: BlockStatement, environment: Environment) {
        self.parameters = parameters
        self.body = body
        self.environment = environment
    }

    public var type: ObjectType { .function }

    public func inspect() -> String {
        let params = parameters.map { $0.string() }.joined(separator: ", ")
        return "fn(\(params)) {\n\(body.string())\n}"
    }
}

// MARK: - Array
public struct ArrayObject: Object {
    public let elements: [any Object]

    public init(elements: [any Object]) {
        self.elements = elements
    }

    public var type: ObjectType { .array }

    public func inspect() -> String {
        let elems = elements.map { $0.inspect() }.joined(separator: ", ")
        return "[\(elems)]"
    }
}

// MARK: - HashMap
public struct HashMap: Object {
    public struct Pair: Sendable {
        public let key: any Object
        public let value: any Object

        public init(key: any Object, value: any Object) {
            self.key = key
            self.value = value
        }
    }

    public let pairs: [HashKey: Pair]

    public init(pairs: [HashKey: Pair]) {
        self.pairs = pairs
    }

    public var type: ObjectType { .hashMap }

    public func inspect() -> String {
        var items: [String] = []
        for (_, pair) in pairs {
            let keyStr = pair.key.type == .string ? "\"\(pair.key.inspect())\"" : pair.key.inspect()
            let valueStr =
                pair.value.type == .string ? "\"\(pair.value.inspect())\"" : pair.value.inspect()
            items.append("\(keyStr): \(valueStr)")
        }
        return "{\(items.joined(separator: ", "))}"
    }
}
typealias HashPair = HashMap.Pair
