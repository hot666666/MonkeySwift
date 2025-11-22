// MARK: - Precedence
enum Precedence: Int, Comparable {
    case lowest = 1
    case equals         // ==
    case lessGreater    // > or <
    case sum            // +
    case product        // *
    case prefix         // -X or !X
    case call           // myFunction(X)

    static func < (lhs: Precedence, rhs: Precedence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension TokenType {
    var precedence: Precedence {
        switch self {
        case .equal, .notEqual:
            return .equals
        case .lessThan, .greaterThan:
            return .lessGreater
        case .plus, .minus:
            return .sum
        case .slash, .asterisk:
            return .product
        case .leftParen:
            return .call
        default:
            return .lowest
        }
    }
}

// MARK: - Parser
public struct Parser {
    var lexer: Lexer
    var currentToken: TokenType
    var peekToken: TokenType
    public var errors: [String] = []

    public init(lexer: Lexer) {
        self.lexer = lexer
        self.currentToken = .eof
        self.peekToken = .eof

        // Read two tokens to initialize currentToken and peekToken
        nextToken()
        nextToken()
    }

    mutating func nextToken() {
        currentToken = peekToken
        peekToken = lexer.nextTokenType()
    }

    public mutating func parseProgram() -> Program {
        var program = Program()

        while currentToken != .eof {
            if let stmt = parseStatement() {
                program.statements.append(stmt)
            }
            nextToken()
        }

        return program
    }

    mutating func parseStatement() -> Statement? {
        switch currentToken {
        case .let:
            return parseLetStatement()
        case .return:
            return parseReturnStatement()
        default:
            return parseExpressionStatement()
        }
    }

    mutating func parseLetStatement() -> LetStatement? {
        let token = currentToken

        guard expectPeek(.identifier(name: "")) else {
            return nil
        }

        guard case .identifier(let name) = currentToken else {
            return nil
        }
        let identifier = Identifier(token: currentToken, value: name)

        guard expectPeek(.assign) else {
            return nil
        }

        nextToken()

        guard let value = parseExpression(.lowest) else {
            return nil
        }

        if peekTokenIs(.semicolon) {
            nextToken()
        }

        return LetStatement(token: token, name: identifier, value: value)
    }

    mutating func parseReturnStatement() -> ReturnStatement? {
        let token = currentToken

        nextToken()

        guard let returnValue = parseExpression(.lowest) else {
            return nil
        }

        if peekTokenIs(.semicolon) {
            nextToken()
        }

        return ReturnStatement(token: token, returnValue: returnValue)
    }

    mutating func parseExpressionStatement() -> ExpressionStatement? {
        let token = currentToken

        guard let expression = parseExpression(.lowest) else {
            return nil
        }

        let stmt = ExpressionStatement(token: token, expression: expression)

        if peekTokenIs(.semicolon) {
            nextToken()
        }

        return stmt
    }

    mutating func parseExpression(_ precedence: Precedence) -> Expression? {
        // Prefix
        guard var leftExp = parsePrefixExpression() else {
            noPrefixParseFnError(currentToken)
            return nil
        }

        // Infix
        while !peekTokenIs(.semicolon) && precedence < peekToken.precedence {
            nextToken()

            guard let infixExp = parseInfixExpression(leftExp) else {
                return leftExp
            }

            leftExp = infixExp
        }

        return leftExp
    }

    mutating func parsePrefixExpression() -> Expression? {
        switch currentToken {
        case .identifier(let name):
            return Identifier(token: currentToken, value: name)
        case .int(let value):
            return IntegerLiteral(token: currentToken, value: value)
        case .true:
            return BooleanLiteral(token: currentToken, value: true)
        case .false:
            return BooleanLiteral(token: currentToken, value: false)
        case .bang, .minus:
            return parsePrefixOperatorExpression()
        case .leftParen:
            return parseGroupedExpression()
        case .if:
            return parseIfExpression()
        case .function:
            return parseFunctionLiteral()
        default:
            return nil
        }
    }

    mutating func parsePrefixOperatorExpression() -> PrefixExpression? {
        let token = currentToken
        let operator_ = currentToken.literal

        nextToken()

        guard let right = parseExpression(.prefix) else {
            return nil
        }

        return PrefixExpression(token: token, operator_: operator_, right: right)
    }

    mutating func parseInfixExpression(_ left: Expression) -> Expression? {
        switch currentToken {
        case .plus, .minus, .slash, .asterisk, .equal, .notEqual, .lessThan, .greaterThan:
            return parseInfixOperatorExpression(left)
        case .leftParen:
            return parseCallExpression(left)
        default:
            return nil
        }
    }

    mutating func parseInfixOperatorExpression(_ left: Expression) -> InfixExpression? {
        let token = currentToken
        let operator_ = currentToken.literal
        let precedence = currentToken.precedence

        nextToken()

        guard let right = parseExpression(precedence) else {
            return nil
        }

        return InfixExpression(token: token, left: left, operator_: operator_, right: right)
    }

    mutating func parseGroupedExpression() -> Expression? {
        nextToken()

        let exp = parseExpression(.lowest)

        if !expectPeek(.rightParen) {
            return nil
        }

        return exp
    }

    mutating func parseIfExpression() -> IfExpression? {
        let token = currentToken

        guard expectPeek(.leftParen) else {
            return nil
        }

        nextToken()

        guard let condition = parseExpression(.lowest) else {
            return nil
        }

        guard expectPeek(.rightParen) else {
            return nil
        }

        guard expectPeek(.leftBrace) else {
            return nil
        }

        let consequence = parseBlockStatement()

        var alternative: BlockStatement? = nil
        if peekTokenIs(.else) {
            nextToken()

            guard expectPeek(.leftBrace) else {
                return nil
            }

            alternative = parseBlockStatement()
        }

        return IfExpression(token: token, condition: condition, consequence: consequence, alternative: alternative)
    }

    mutating func parseBlockStatement() -> BlockStatement {
        var block = BlockStatement(token: currentToken)

        nextToken()

        while !currentTokenIs(.rightBrace) && !currentTokenIs(.eof) {
            if let stmt = parseStatement() {
                block.statements.append(stmt)
            }
            nextToken()
        }

        return block
    }

    mutating func parseFunctionLiteral() -> FunctionLiteral? {
        let token = currentToken

        guard expectPeek(.leftParen) else {
            return nil
        }

        guard let parameters = parseFunctionParameters() else {
            return nil
        }

        guard expectPeek(.leftBrace) else {
            return nil
        }

        let body = parseBlockStatement()

        return FunctionLiteral(token: token, parameters: parameters, body: body)
    }

    mutating func parseFunctionParameters() -> [Identifier]? {
        var identifiers: [Identifier] = []

        if peekTokenIs(.rightParen) {
            nextToken()
            return identifiers
        }

        nextToken()

        guard case .identifier(let name) = currentToken else {
            return nil
        }

        identifiers.append(Identifier(token: currentToken, value: name))

        while peekTokenIs(.comma) {
            nextToken()
            nextToken()

            guard case .identifier(let name) = currentToken else {
                return nil
            }

            identifiers.append(Identifier(token: currentToken, value: name))
        }

        guard expectPeek(.rightParen) else {
            return nil
        }

        return identifiers
    }

    mutating func parseCallExpression(_ function: Expression) -> CallExpression? {
        let token = currentToken
        guard let arguments = parseExpressionList(.rightParen) else {
            return nil
        }
        return CallExpression(token: token, function: function, arguments: arguments)
    }

    mutating func parseExpressionList(_ end: TokenType) -> [Expression]? {
        var list: [Expression] = []

        if peekTokenIs(end) {
            nextToken()
            return list
        }

        nextToken()

        guard let exp = parseExpression(.lowest) else {
            return nil
        }

        list.append(exp)

        while peekTokenIs(.comma) {
            nextToken()
            nextToken()

            guard let exp = parseExpression(.lowest) else {
                return nil
            }

            list.append(exp)
        }

        guard expectPeek(end) else {
            return nil
        }

        return list
    }

    // MARK: - Helper methods

    func currentTokenIs(_ tokenType: TokenType) -> Bool {
        return discriminatorEqual(currentToken, tokenType)
    }

    func peekTokenIs(_ tokenType: TokenType) -> Bool {
        return discriminatorEqual(peekToken, tokenType)
    }

    mutating func expectPeek(_ tokenType: TokenType) -> Bool {
        if peekTokenIs(tokenType) {
            nextToken()
            return true
        } else {
            peekError(tokenType)
            return false
        }
    }

    mutating func peekError(_ tokenType: TokenType) {
        let msg = "expected next token to be \(tokenType.literal), got \(peekToken.literal) instead"
        errors.append(msg)
    }

    mutating func noPrefixParseFnError(_ tokenType: TokenType) {
        let msg = "no prefix parse function for \(tokenType.literal) found"
        errors.append(msg)
    }

    // Helper to compare token discriminators (ignoring associated values for specific types)
    func discriminatorEqual(_ lhs: TokenType, _ rhs: TokenType) -> Bool {
        switch (lhs, rhs) {
        case (.identifier, .identifier):
            return true
        case (.int, .int):
            return true
        case (.assign, .assign),
             (.plus, .plus),
             (.minus, .minus),
             (.bang, .bang),
             (.asterisk, .asterisk),
             (.slash, .slash),
             (.comma, .comma),
             (.semicolon, .semicolon),
             (.lessThan, .lessThan),
             (.greaterThan, .greaterThan),
             (.equal, .equal),
             (.notEqual, .notEqual),
             (.leftParen, .leftParen),
             (.rightParen, .rightParen),
             (.leftBrace, .leftBrace),
             (.rightBrace, .rightBrace),
             (.function, .function),
             (.let, .let),
             (.true, .true),
             (.false, .false),
             (.if, .if),
             (.else, .else),
             (.return, .return),
             (.eof, .eof):
            return true
        default:
            return false
        }
    }
}
