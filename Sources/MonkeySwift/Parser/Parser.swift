// MARK: - Precedence
enum Precedence: Int, Comparable {
    case lowest = 1
    case equals = 2          // ==
    case lessGreater = 3     // > or <
    case sum = 4             // +
    case product = 5         // *
    case prefix = 6          // -X or !X
    case call = 7            // myFunction(X)

    static func < (lhs: Precedence, rhs: Precedence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func from(_ tokenType: TokenType) -> Precedence {
        switch tokenType {
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
        var parser = Parser(
            lexer: lexer,
            currentToken: .eof,
            peekToken: .eof,
            errors: []
        )
        parser.nextToken()
        parser.nextToken()
        return parser
    }

    private init(lexer: Lexer, currentToken: TokenType, peekToken: TokenType, errors: [String]) {
        self.lexer = lexer
        self.currentToken = currentToken
        self.peekToken = peekToken
        self.errors = errors
    }

    public mutating func parseProgram() -> Program {
        var statements: [any Statement] = []

        while currentToken != .eof {
            if let statement = parseStatement() {
                statements.append(statement)
            }
            nextToken()
        }

        return Program(statements: statements)
    }

    // MARK: - Token Management

    private mutating func nextToken() {
        currentToken = peekToken
        peekToken = lexer.nextTokenType()
    }

    private func currentTokenIs(_ tokenType: TokenType) -> Bool {
        return currentToken == tokenType
    }

    private func peekTokenIs(_ tokenType: TokenType) -> Bool {
        return peekToken == tokenType
    }

    private mutating func expectPeek(_ tokenType: TokenType) -> Bool {
        if peekTokenIs(tokenType) {
            nextToken()
            return true
        } else {
            peekError(tokenType)
            return false
        }
    }

    private func peekPrecedence() -> Precedence {
        return Precedence.from(peekToken)
    }

    private func currentPrecedence() -> Precedence {
        return Precedence.from(currentToken)
    }

    // MARK: - Error Handling

    private mutating func peekError(_ tokenType: TokenType) {
        let message = "expected next token to be \(tokenType.literal), got \(peekToken.literal) instead"
        errors.append(message)
    }

    private mutating func noPrefixParseFnError(_ tokenType: TokenType) {
        let message = "no prefix parse function for \(tokenType.literal) found"
        errors.append(message)
    }

    // MARK: - Statement Parsing

    private mutating func parseStatement() -> (any Statement)? {
        switch currentToken {
        case .let:
            return parseLetStatement()
        case .return:
            return parseReturnStatement()
        default:
            return parseExpressionStatement()
        }
    }

    private mutating func parseLetStatement() -> LetStatement? {
        let token = currentToken

        guard case .identifier(let name) = peekToken else {
            expectPeek(.identifier(name: ""))
            return nil
        }

        let nameToken = peekToken
        nextToken()
        let identifier = Identifier(token: nameToken, value: name)

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

    private mutating func parseReturnStatement() -> ReturnStatement? {
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

    private mutating func parseExpressionStatement() -> ExpressionStatement? {
        let token = currentToken

        guard let expression = parseExpression(.lowest) else {
            return nil
        }

        let statement = ExpressionStatement(token: token, expression: expression)

        if peekTokenIs(.semicolon) {
            nextToken()
        }

        return statement
    }

    private mutating func parseBlockStatement() -> BlockStatement {
        let token = currentToken
        var statements: [any Statement] = []

        nextToken()

        while !currentTokenIs(.rightBrace) && !currentTokenIs(.eof) {
            if let statement = parseStatement() {
                statements.append(statement)
            }
            nextToken()
        }

        return BlockStatement(token: token, statements: statements)
    }

    // MARK: - Expression Parsing

    private mutating func parseExpression(_ precedence: Precedence) -> (any Expression)? {
        guard var leftExp = parsePrefixExpression() else {
            noPrefixParseFnError(currentToken)
            return nil
        }

        while !peekTokenIs(.semicolon) && precedence < peekPrecedence() {
            if !isInfixToken(peekToken) {
                return leftExp
            }

            nextToken()

            guard let infixExp = parseInfixExpression(leftExp) else {
                return leftExp
            }

            leftExp = infixExp
        }

        return leftExp
    }

    private func isInfixToken(_ token: TokenType) -> Bool {
        switch token {
        case .plus, .minus, .slash, .asterisk, .equal, .notEqual, .lessThan, .greaterThan, .leftParen:
            return true
        default:
            return false
        }
    }

    private mutating func parsePrefixExpression() -> (any Expression)? {
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

    private mutating func parsePrefixOperatorExpression() -> PrefixExpression? {
        let token = currentToken
        let operatorSymbol = currentToken.literal

        nextToken()

        guard let right = parseExpression(.prefix) else {
            return nil
        }

        return PrefixExpression(token: token, operatorSymbol: operatorSymbol, right: right)
    }

    private mutating func parseInfixExpression(_ left: any Expression) -> (any Expression)? {
        if currentTokenIs(.leftParen) {
            return parseCallExpression(left)
        }

        let token = currentToken
        let operatorSymbol = currentToken.literal
        let precedence = currentPrecedence()

        nextToken()

        guard let right = parseExpression(precedence) else {
            return nil
        }

        return InfixExpression(token: token, left: left, operatorSymbol: operatorSymbol, right: right)
    }

    private mutating func parseGroupedExpression() -> (any Expression)? {
        nextToken()

        let expression = parseExpression(.lowest)

        guard expectPeek(.rightParen) else {
            return nil
        }

        return expression
    }

    private mutating func parseIfExpression() -> IfExpression? {
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

    private mutating func parseFunctionLiteral() -> FunctionLiteral? {
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

    private mutating func parseFunctionParameters() -> [Identifier]? {
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

    private mutating func parseCallExpression(_ function: any Expression) -> CallExpression? {
        let token = currentToken
        guard let arguments = parseExpressionList(.rightParen) else {
            return nil
        }
        return CallExpression(token: token, function: function, arguments: arguments)
    }

    private mutating func parseExpressionList(_ end: TokenType) -> [any Expression]? {
        var list: [any Expression] = []

        if peekTokenIs(end) {
            nextToken()
            return list
        }

        nextToken()

        guard let expression = parseExpression(.lowest) else {
            return nil
        }

        list.append(expression)

        while peekTokenIs(.comma) {
            nextToken()
            nextToken()

            guard let expression = parseExpression(.lowest) else {
                return nil
            }

            list.append(expression)
        }

        guard expectPeek(end) else {
            return nil
        }

        return list
    }
}
