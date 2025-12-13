// MARK: - Precedence
enum Precedence: Int, Comparable {
    case lowest = 1
    case equals = 2  // == or !=
    case lessGreater = 3  // > or <
    case sum = 4  // + or -
    case product = 5  // * or /
    case prefix = 6  // -X or !X
    case call = 7  // ( `함수 호출`
    case index = 8  // [ `인덱스 접근`

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
        case .leftBracket:
            return .index
        default:
            return .lowest
        }
    }
}

// MARK: - Parser
/// Parser는 Lexer에서 토큰을 받아서 AST(Statement Nodes)를 만드는 역할을 합니다.
/// - currentToken: 현재 토큰
/// - peekToken: 다음 토큰
/// - errors: 에러 메시지
public struct Parser {
    var lexer: Lexer
    var currentToken: TokenType = .eof
    var peekToken: TokenType = .eof
    public var errors: [String] = []

    public init(lexer: Lexer) {
        self.lexer = lexer
        /// Parser 상태 세팅
        /// [currentToken: .eof, peekToken: .eof]
        /// -> [currentToken: X, peekToken: .eof]
        /// -> [currentToken: X, peekToken: Y]
        self.nextToken()
        self.nextToken()
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

    // 어떤 토큰을 기대했고, 실제로 무엇이 왔는지 에러 메시지로 기록
    @discardableResult
    private mutating func expectPeek(_ tokenType: TokenType) -> Bool {
        /// 기대한 토큰이 peekToken이라면, nextToken()이 호출됨!
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
        let message =
            "expected next token to be \(tokenType.literal), got \(peekToken.literal) instead"
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
        /// Parse: let <identifier> = <expression>;
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
        /// Parse: return <expression>;
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
        /// Parse: <expression>;
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
        /// Parse: { <statement> }
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

    // 이전 토큰의 precedence를 가지고 재귀적으로 동작
    private mutating func parseExpression(_ precedence: Precedence) -> (any Expression)? {
        /// prefix expression(식의 가장 앞부분에 올 수 있는 모든 것을 처리)
        guard var leftExp = parsePrefixExpression() else {
            noPrefixParseFnError(currentToken)
            return nil
        }

        while !peekTokenIs(.semicolon) && precedence < peekPrecedence() {
            /// 다음에 오는 토큰이 prefix와 infix를 붙여주는 토큰인지 확인
            if !isInfixToken(peekToken) {
                return leftExp
            }

            nextToken()

            /// infix expression(식의 중간에 올 수 있는 모든 것을 처리)
            guard let infixExp = parseInfixExpression(leftExp) else {
                return leftExp
            }

            leftExp = infixExp
        }

        return leftExp
    }

    // Prefix Parse 이후 붙을 수 있는 Token
    private func isInfixToken(_ token: TokenType) -> Bool {
        switch token {
        case .plus, .minus, .slash, .asterisk, .equal, .notEqual, .lessThan, .greaterThan,
            .leftParen, .leftBracket:
            return true
        default:
            return false
        }
    }

    // Prefix Parse될 수 있는 Expression
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
        case .leftBracket:
            return parseArrayLiteral()
        /// 위에서 처리하지 못한 것들은 Prefix Parse가 불가능
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

        if currentTokenIs(.leftBracket) {
            return parseIndexExpression(left)
        }

        let token = currentToken
        let operatorSymbol = currentToken.literal
        let precedence = currentPrecedence()

        nextToken()

        guard let right = parseExpression(precedence) else {
            return nil
        }

        return InfixExpression(
            token: token, left: left, operatorSymbol: operatorSymbol, right: right)
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
        /// if ->
        /// (condition) { consequence }
        /// (condition) { consequence } else { alternative }
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

        return IfExpression(
            token: token, condition: condition, consequence: consequence, alternative: alternative)
    }

    private mutating func parseFunctionLiteral() -> FunctionLiteral? {
        /// fn ->
        /// (parameter) { body }
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
        /// ( ->
        /// )
        /// identifier, identifier, ...)
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
        /// Identifier( ->
        /// argument, argument, ...)
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

    private mutating func parseArrayLiteral() -> ArrayLiteral? {
        let token = currentToken
        guard let elements = parseExpressionList(.rightBracket) else {
            return nil
        }
        return ArrayLiteral(token: token, elements: elements)
    }

    private mutating func parseIndexExpression(_ left: any Expression) -> IndexExpression? {
        let token = currentToken

        nextToken()

        guard let index = parseExpression(.lowest) else {
            return nil
        }

        guard expectPeek(.rightBracket) else {
            return nil
        }

        return IndexExpression(token: token, left: left, index: index)
    }
}
