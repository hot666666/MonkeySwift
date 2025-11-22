import Testing
@testable import MonkeySwift

@Suite("ASTTests")
struct MonkeySwiftAST {
    @Test func testLetStatement() {
        let letToken = TokenType.let
        let nameToken = TokenType.identifier(name: "myVar")
        let valueToken = TokenType.int(value: 5)

        let name = Identifier(token: nameToken, value: "myVar")
        let value = IntegerLiteral(token: valueToken, value: 5)
        let statement = LetStatement(token: letToken, name: name, value: value)

        #expect(statement.tokenLiteral == "let")
        #expect(statement.string() == "let myVar = 5;")
    }

    @Test func testReturnStatement() {
        let returnToken = TokenType.return
        let valueToken = TokenType.int(value: 42)

        let value = IntegerLiteral(token: valueToken, value: 42)
        let statement = ReturnStatement(token: returnToken, returnValue: value)

        #expect(statement.tokenLiteral == "return")
        #expect(statement.string() == "return 42;")
    }

    @Test func testExpressionStatement() {
        let token = TokenType.identifier(name: "x")
        let identifier = Identifier(token: token, value: "x")
        let statement = ExpressionStatement(token: token, expression: identifier)

        #expect(statement.tokenLiteral == "x")
        #expect(statement.string() == "x")
    }

    @Test func testBlockStatement() {
        let token = TokenType.leftBrace
        let stmt1Token = TokenType.identifier(name: "x")
        let stmt1 = ExpressionStatement(
            token: stmt1Token,
            expression: Identifier(token: stmt1Token, value: "x")
        )

        let stmt2Token = TokenType.identifier(name: "y")
        let stmt2 = ExpressionStatement(
            token: stmt2Token,
            expression: Identifier(token: stmt2Token, value: "y")
        )

        let block = BlockStatement(token: token, statements: [stmt1, stmt2])

        #expect(block.tokenLiteral == "{")
        #expect(block.string() == "xy")
    }

    @Test func testIdentifier() {
        let token = TokenType.identifier(name: "foobar")
        let identifier = Identifier(token: token, value: "foobar")

        #expect(identifier.tokenLiteral == "foobar")
        #expect(identifier.string() == "foobar")
    }

    @Test func testIntegerLiteral() {
        let token = TokenType.int(value: 123)
        let literal = IntegerLiteral(token: token, value: 123)

        #expect(literal.tokenLiteral == "123")
        #expect(literal.string() == "123")
    }

    @Test func testBooleanLiteral() {
        let trueToken = TokenType.true
        let trueLiteral = BooleanLiteral(token: trueToken, value: true)

        #expect(trueLiteral.tokenLiteral == "true")
        #expect(trueLiteral.string() == "true")

        let falseToken = TokenType.false
        let falseLiteral = BooleanLiteral(token: falseToken, value: false)

        #expect(falseLiteral.tokenLiteral == "false")
        #expect(falseLiteral.string() == "false")
    }

    @Test func testPrefixExpression() {
        let token = TokenType.bang
        let rightToken = TokenType.int(value: 5)
        let right = IntegerLiteral(token: rightToken, value: 5)
        let expr = PrefixExpression(token: token, operatorSymbol: "!", right: right)

        #expect(expr.tokenLiteral == "!")
        #expect(expr.string() == "(!5)")
    }

    @Test func testInfixExpression() {
        let token = TokenType.plus
        let leftToken = TokenType.int(value: 5)
        let left = IntegerLiteral(token: leftToken, value: 5)
        let rightToken = TokenType.int(value: 10)
        let right = IntegerLiteral(token: rightToken, value: 10)

        let expr = InfixExpression(token: token, left: left, operatorSymbol: "+", right: right)

        #expect(expr.tokenLiteral == "+")
        #expect(expr.string() == "(5 + 10)")
    }

    @Test func testIfExpression() {
        let token = TokenType.if
        let conditionToken = TokenType.identifier(name: "x")
        let condition = Identifier(token: conditionToken, value: "x")

        let consequenceToken = TokenType.leftBrace
        let consequenceStmtToken = TokenType.identifier(name: "y")
        let consequenceStmt = ExpressionStatement(
            token: consequenceStmtToken,
            expression: Identifier(token: consequenceStmtToken, value: "y")
        )
        let consequence = BlockStatement(token: consequenceToken, statements: [consequenceStmt])

        let ifExpr = IfExpression(token: token, condition: condition, consequence: consequence)

        #expect(ifExpr.tokenLiteral == "if")
        #expect(ifExpr.string() == "ifx y")
    }

    @Test func testIfElseExpression() {
        let token = TokenType.if
        let conditionToken = TokenType.identifier(name: "x")
        let condition = Identifier(token: conditionToken, value: "x")

        let consequenceToken = TokenType.leftBrace
        let consequenceStmtToken = TokenType.identifier(name: "y")
        let consequenceStmt = ExpressionStatement(
            token: consequenceStmtToken,
            expression: Identifier(token: consequenceStmtToken, value: "y")
        )
        let consequence = BlockStatement(token: consequenceToken, statements: [consequenceStmt])

        let alternativeToken = TokenType.leftBrace
        let alternativeStmtToken = TokenType.identifier(name: "z")
        let alternativeStmt = ExpressionStatement(
            token: alternativeStmtToken,
            expression: Identifier(token: alternativeStmtToken, value: "z")
        )
        let alternative = BlockStatement(token: alternativeToken, statements: [alternativeStmt])

        let ifExpr = IfExpression(token: token, condition: condition, consequence: consequence, alternative: alternative)

        #expect(ifExpr.tokenLiteral == "if")
        #expect(ifExpr.string() == "ifx yelse z")
    }

    @Test func testFunctionLiteral() {
        let token = TokenType.function

        let param1Token = TokenType.identifier(name: "x")
        let param1 = Identifier(token: param1Token, value: "x")

        let param2Token = TokenType.identifier(name: "y")
        let param2 = Identifier(token: param2Token, value: "y")

        let bodyToken = TokenType.leftBrace
        let bodyStmtToken = TokenType.identifier(name: "x")
        let bodyStmt = ExpressionStatement(
            token: bodyStmtToken,
            expression: Identifier(token: bodyStmtToken, value: "x")
        )
        let body = BlockStatement(token: bodyToken, statements: [bodyStmt])

        let funcLiteral = FunctionLiteral(token: token, parameters: [param1, param2], body: body)

        #expect(funcLiteral.tokenLiteral == "fn")
        #expect(funcLiteral.string() == "fn(x, y) x")
    }

    @Test func testCallExpression() {
        let token = TokenType.leftParen

        let funcToken = TokenType.identifier(name: "add")
        let function = Identifier(token: funcToken, value: "add")

        let arg1Token = TokenType.int(value: 1)
        let arg1 = IntegerLiteral(token: arg1Token, value: 1)

        let arg2Token = TokenType.int(value: 2)
        let arg2 = IntegerLiteral(token: arg2Token, value: 2)

        let callExpr = CallExpression(token: token, function: function, arguments: [arg1, arg2])

        #expect(callExpr.tokenLiteral == "(")
        #expect(callExpr.string() == "add(1, 2)")
    }

    @Test func testProgram() {
        let letToken = TokenType.let
        let nameToken = TokenType.identifier(name: "x")
        let valueToken = TokenType.int(value: 5)

        let name = Identifier(token: nameToken, value: "x")
        let value = IntegerLiteral(token: valueToken, value: 5)
        let letStmt = LetStatement(token: letToken, name: name, value: value)

        let returnToken = TokenType.return
        let returnValueToken = TokenType.identifier(name: "x")
        let returnValue = Identifier(token: returnValueToken, value: "x")
        let returnStmt = ReturnStatement(token: returnToken, returnValue: returnValue)

        let program = Program(statements: [letStmt, returnStmt])

        #expect(program.tokenLiteral == "let")
        #expect(program.string() == "let x = 5;return x;")
    }

    @Test func testEmptyProgram() {
        let program = Program()

        #expect(program.tokenLiteral == "")
        #expect(program.string() == "")
    }

    @Test func testComplexExpression() {
        // Test: (5 + 10) * 2
        let plusToken = TokenType.plus
        let leftToken = TokenType.int(value: 5)
        let left = IntegerLiteral(token: leftToken, value: 5)
        let rightToken = TokenType.int(value: 10)
        let right = IntegerLiteral(token: rightToken, value: 10)

        let addExpr = InfixExpression(token: plusToken, left: left, operatorSymbol: "+", right: right)

        let multiplyToken = TokenType.asterisk
        let multiplierToken = TokenType.int(value: 2)
        let multiplier = IntegerLiteral(token: multiplierToken, value: 2)

        let multiplyExpr = InfixExpression(token: multiplyToken, left: addExpr, operatorSymbol: "*", right: multiplier)

        #expect(multiplyExpr.string() == "((5 + 10) * 2)")
    }
}
