// MARK: - Node Protocol
public protocol Node {
    func tokenLiteral() -> String
    func string() -> String
}

// MARK: - Statement Protocol
public protocol Statement: Node {
    func statementNode()
}

// MARK: - Expression Protocol
public protocol Expression: Node {
    func expressionNode()
}

// MARK: - Program
public struct Program: Node {
    public var statements: [Statement]

    public init(statements: [Statement] = []) {
        self.statements = statements
    }

    public func tokenLiteral() -> String {
        if !statements.isEmpty {
            return statements[0].tokenLiteral()
        }
        return ""
    }

    public func string() -> String {
        return statements.map { $0.string() }.joined()
    }
}

// MARK: - Statements

public struct LetStatement: Statement {
    public let token: TokenType  // .let
    public let name: Identifier
    public let value: Expression

    public init(token: TokenType, name: Identifier, value: Expression) {
        self.token = token
        self.name = name
        self.value = value
    }

    public func statementNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return "\(tokenLiteral()) \(name.string()) = \(value.string());"
    }
}

public struct ReturnStatement: Statement {
    public let token: TokenType  // .return
    public let returnValue: Expression

    public init(token: TokenType, returnValue: Expression) {
        self.token = token
        self.returnValue = returnValue
    }

    public func statementNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return "\(tokenLiteral()) \(returnValue.string());"
    }
}

public struct ExpressionStatement: Statement {
    public let token: TokenType  // 표현식의 첫 번째 토큰
    public let expression: Expression

    public init(token: TokenType, expression: Expression) {
        self.token = token
        self.expression = expression
    }

    public func statementNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return expression.string()
    }
}

public struct BlockStatement: Statement {
    public let token: TokenType  // .leftBrace
    public var statements: [Statement]

    public init(token: TokenType, statements: [Statement] = []) {
        self.token = token
        self.statements = statements
    }

    public func statementNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return statements.map { $0.string() }.joined()
    }
}

// MARK: - Expressions

public struct Identifier: Expression {
    public let token: TokenType  // .identifier
    public let value: String

    public init(token: TokenType, value: String) {
        self.token = token
        self.value = value
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return value
    }
}

public struct IntegerLiteral: Expression {
    public let token: TokenType  // .int
    public let value: Int

    public init(token: TokenType, value: Int) {
        self.token = token
        self.value = value
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return "\(value)"
    }
}

public struct BooleanLiteral: Expression {
    public let token: TokenType  // .true or .false
    public let value: Bool

    public init(token: TokenType, value: Bool) {
        self.token = token
        self.value = value
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return token.literal
    }
}

public struct PrefixExpression: Expression {
    public let token: TokenType  // prefix operator (!, -)
    public let operator_: String
    public let right: Expression

    public init(token: TokenType, operator_: String, right: Expression) {
        self.token = token
        self.operator_ = operator_
        self.right = right
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return "(\(operator_)\(right.string()))"
    }
}

public struct InfixExpression: Expression {
    public let token: TokenType  // operator token (+, -, *, /, <, >, ==, !=)
    public let left: Expression
    public let operator_: String
    public let right: Expression

    public init(token: TokenType, left: Expression, operator_: String, right: Expression) {
        self.token = token
        self.left = left
        self.operator_ = operator_
        self.right = right
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        return "(\(left.string()) \(operator_) \(right.string()))"
    }
}

public struct IfExpression: Expression {
    public let token: TokenType  // .if
    public let condition: Expression
    public let consequence: BlockStatement
    public let alternative: BlockStatement?

    public init(token: TokenType, condition: Expression, consequence: BlockStatement, alternative: BlockStatement? = nil) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        var str = "if\(condition.string()) \(consequence.string())"
        if let alt = alternative {
            str += "else \(alt.string())"
        }
        return str
    }
}

public struct FunctionLiteral: Expression {
    public let token: TokenType  // .function
    public let parameters: [Identifier]
    public let body: BlockStatement

    public init(token: TokenType, parameters: [Identifier], body: BlockStatement) {
        self.token = token
        self.parameters = parameters
        self.body = body
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        let params = parameters.map { $0.string() }.joined(separator: ", ")
        return "\(tokenLiteral())(\(params)) \(body.string())"
    }
}

public struct CallExpression: Expression {
    public let token: TokenType  // .leftParen
    public let function: Expression  // Identifier or FunctionLiteral
    public let arguments: [Expression]

    public init(token: TokenType, function: Expression, arguments: [Expression]) {
        self.token = token
        self.function = function
        self.arguments = arguments
    }

    public func expressionNode() {}

    public func tokenLiteral() -> String {
        return token.literal
    }

    public func string() -> String {
        let args = arguments.map { $0.string() }.joined(separator: ", ")
        return "\(function.string())(\(args))"
    }
}
