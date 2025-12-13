// MARK: - Node Protocol
public protocol Node: Sendable {
    var tokenLiteral: String { get }
    func string() -> String
}

// MARK: - Statement Protocol
public protocol Statement: Node {}

// MARK: - Expression Protocol
public protocol Expression: Node {}

// MARK: - Program
public struct Program: Node {
    public var statements: [any Statement]

    public init(statements: [any Statement] = []) {
        self.statements = statements
    }

    public var tokenLiteral: String {
        if statements.count > 0 {
            return statements[0].tokenLiteral
        } else {
            return ""
        }
    }

    public func string() -> String {
        return statements.map { $0.string() }.joined()
    }
}

// MARK: - Statements

public struct LetStatement: Statement, Sendable {
    public let token: TokenType  // .let token
    public let name: Identifier
    public let value: any Expression

    public init(token: TokenType, name: Identifier, value: any Expression) {
        self.token = token
        self.name = name
        self.value = value
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "\(tokenLiteral) \(name.string()) = \(value.string());"
    }
}

public struct ReturnStatement: Statement, Sendable {
    public let token: TokenType  // .return token
    public let returnValue: any Expression

    public init(token: TokenType, returnValue: any Expression) {
        self.token = token
        self.returnValue = returnValue
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "\(tokenLiteral) \(returnValue.string());"
    }
}

public struct ExpressionStatement: Statement, Sendable {
    public let token: TokenType  // first token of expression
    public let expression: any Expression

    public init(token: TokenType, expression: any Expression) {
        self.token = token
        self.expression = expression
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return expression.string()
    }
}

public struct BlockStatement: Statement, Sendable {
    public let token: TokenType  // .leftBrace token
    public var statements: [any Statement]

    public init(token: TokenType, statements: [any Statement] = []) {
        self.token = token
        self.statements = statements
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return statements.map { $0.string() }.joined()
    }
}

// MARK: - Expressions

public struct Identifier: Expression, Sendable {
    public let token: TokenType  // .identifier token
    public let value: String

    public init(token: TokenType, value: String) {
        self.token = token
        self.value = value
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return value
    }
}

public struct IntegerLiteral: Expression, Sendable {
    public let token: TokenType  // .int token
    public let value: Int

    public init(token: TokenType, value: Int) {
        self.token = token
        self.value = value
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "\(value)"
    }
}

public struct BooleanLiteral: Expression, Sendable {
    public let token: TokenType  // .true or .false token
    public let value: Bool

    public init(token: TokenType, value: Bool) {
        self.token = token
        self.value = value
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "\(value)"
    }
}

public struct PrefixExpression: Expression, Sendable {
    public let token: TokenType  // prefix operator token
    public let operatorSymbol: String
    public let right: any Expression

    public init(token: TokenType, operatorSymbol: String, right: any Expression) {
        self.token = token
        self.operatorSymbol = operatorSymbol
        self.right = right
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "(\(operatorSymbol)\(right.string()))"
    }
}

public struct InfixExpression: Expression, Sendable {
    public let token: TokenType  // operator token
    public let left: any Expression
    public let operatorSymbol: String
    public let right: any Expression

    public init(
        token: TokenType, left: any Expression, operatorSymbol: String, right: any Expression
    ) {
        self.token = token
        self.left = left
        self.operatorSymbol = operatorSymbol
        self.right = right
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "(\(left.string()) \(operatorSymbol) \(right.string()))"
    }
}

public struct IfExpression: Expression, Sendable {
    public let token: TokenType  // .if token
    public let condition: any Expression
    public let consequence: BlockStatement
    public let alternative: BlockStatement?

    public init(
        token: TokenType, condition: any Expression, consequence: BlockStatement,
        alternative: BlockStatement? = nil
    ) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        var result = "if\(condition.string()) \(consequence.string())"
        if let alt = alternative {
            result += "else \(alt.string())"
        }
        return result
    }
}

public struct FunctionLiteral: Expression, Sendable {
    public let token: TokenType  // .function token
    public let parameters: [Identifier]
    public let body: BlockStatement

    public init(token: TokenType, parameters: [Identifier], body: BlockStatement) {
        self.token = token
        self.parameters = parameters
        self.body = body
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        let params = parameters.map { $0.string() }.joined(separator: ", ")
        return "\(tokenLiteral)(\(params)) \(body.string())"
    }
}

public struct CallExpression: Expression, Sendable {
    public let token: TokenType  // .leftParen token
    public let function: any Expression  // Identifier or FunctionLiteral
    public let arguments: [any Expression]

    public init(token: TokenType, function: any Expression, arguments: [any Expression]) {
        self.token = token
        self.function = function
        self.arguments = arguments
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        let args = arguments.map { $0.string() }.joined(separator: ", ")
        return "\(function.string())(\(args))"
    }
}

public struct ArrayLiteral: Expression, Sendable {
    public let token: TokenType  // '[' token
    public let elements: [any Expression]

    public init(token: TokenType, elements: [any Expression]) {
        self.token = token
        self.elements = elements
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        let elems = elements.map { $0.string() }.joined(separator: ", ")
        return "[\(elems)]"
    }
}

public struct IndexExpression: Expression, Sendable {
    public let token: TokenType  // '[' token
    public let left: any Expression
    public let index: any Expression

    public init(token: TokenType, left: any Expression, index: any Expression) {
        self.token = token
        self.left = left
        self.index = index
    }

    public var tokenLiteral: String { token.literal }

    public func string() -> String {
        return "(\(left.string())[\(index.string())])"
    }
}
