// MARK: - ObjectType
public enum ObjectType: String {
    case integer = "INTEGER"
    case boolean = "BOOLEAN"
    case null = "NULL"
    case returnValue = "RETURN_VALUE"
    case error = "ERROR"
    case function = "FUNCTION"
}

// MARK: - Object Protocol
public protocol Object {
    func type() -> ObjectType
    func inspect() -> String
}

// MARK: - Integer
public struct IntegerObject: Object {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }

    public func type() -> ObjectType {
        return .integer
    }

    public func inspect() -> String {
        return "\(value)"
    }
}

// MARK: - Boolean
public struct BooleanObject: Object {
    public let value: Bool

    public init(value: Bool) {
        self.value = value
    }

    public func type() -> ObjectType {
        return .boolean
    }

    public func inspect() -> String {
        return "\(value)"
    }
}

// MARK: - Null
public struct NullObject: Object {
    public init() {}

    public func type() -> ObjectType {
        return .null
    }

    public func inspect() -> String {
        return "null"
    }
}

// MARK: - Return Value
public struct ReturnValueObject: Object {
    public let value: Object

    public init(value: Object) {
        self.value = value
    }

    public func type() -> ObjectType {
        return .returnValue
    }

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

    public func type() -> ObjectType {
        return .error
    }

    public func inspect() -> String {
        return "ERROR: \(message)"
    }
}

// MARK: - Function
public struct FunctionObject: Object {
    public let parameters: [Identifier]
    public let body: BlockStatement
    public let env: Environment

    public init(parameters: [Identifier], body: BlockStatement, env: Environment) {
        self.parameters = parameters
        self.body = body
        self.env = env
    }

    public func type() -> ObjectType {
        return .function
    }

    public func inspect() -> String {
        let params = parameters.map { $0.string() }.joined(separator: ", ")
        return "fn(\(params)) {\n\(body.string())\n}"
    }
}

// MARK: - Helper Constants
public let NULL = NullObject()
public let TRUE = BooleanObject(value: true)
public let FALSE = BooleanObject(value: false)
