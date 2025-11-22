// MARK: - Object Protocol
public protocol Object: Sendable {
    var type: ObjectType { get }
    func inspect() -> String
}

// MARK: - Object Type
public enum ObjectType: String, Sendable {
    case integer = "INTEGER"
    case boolean = "BOOLEAN"
    case null = "NULL"
    case returnValue = "RETURN_VALUE"
    case error = "ERROR"
    case function = "FUNCTION"
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
