import Testing

@testable import MonkeyCore
@testable import MonkeyLexer
@testable import MonkeyParser

@Suite("Parser tests")
struct ParserTests {
    @Test("Let statement parsing")
    func testLetStatements() {
        let input = """
            let x = 5;
            let y = 10;
            let foobar = 838383;
            """

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 3, "program.statements does not contain 3 statements")

        let expectedIdentifiers = ["x", "y", "foobar"]

        for (i, expectedIdentifier) in expectedIdentifiers.enumerated() {
            let stmt = program.statements[i]
            #expect(stmt is LetStatement, "statement is not LetStatement")

            if let letStmt = stmt as? LetStatement {
                #expect(letStmt.name.value == expectedIdentifier,
                       "letStmt.name.value not '\(expectedIdentifier)'. got=\(letStmt.name.value)")
            }
        }
    }

    @Test("Return statement parsing")
    func testReturnStatements() {
        let input = """
            return 5;
            return 10;
            return 993322;
            """

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 3, "program.statements does not contain 3 statements")

        for stmt in program.statements {
            #expect(stmt is ReturnStatement, "statement is not ReturnStatement")
        }
    }

    @Test("Identifier expression parsing")
    func testIdentifierExpression() {
        let input = "foobar;"

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 1, "program has not enough statements")

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            #expect(Bool(false), "statement is not ExpressionStatement")
            return
        }

        guard let ident = stmt.expression as? Identifier else {
            #expect(Bool(false), "expression is not Identifier")
            return
        }

        #expect(ident.value == "foobar", "ident.value not 'foobar'. got=\(ident.value)")
    }

    @Test("Integer literal expression parsing")
    func testIntegerLiteralExpression() {
        let input = "5;"

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 1, "program has not enough statements")

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            #expect(Bool(false), "statement is not ExpressionStatement")
            return
        }

        guard let literal = stmt.expression as? IntegerLiteral else {
            #expect(Bool(false), "expression is not IntegerLiteral")
            return
        }

        #expect(literal.value == 5, "literal.value not 5. got=\(literal.value)")
    }

    @Test("Prefix expression parsing")
    func testParsingPrefixExpressions() {
        let tests: [(String, String, Any)] = [
            ("!5;", "!", 5),
            ("-15;", "-", 15),
            ("!true;", "!", true),
            ("!false;", "!", false),
        ]

        for (input, expectedOperator, expectedValue) in tests {
            let lexer = Lexer(input: input)
            var parser = Parser(lexer: lexer)
            let program = parser.parseProgram()

            checkParserErrors(parser)

            #expect(program.statements.count == 1, "program has not enough statements")

            guard let stmt = program.statements[0] as? ExpressionStatement else {
                #expect(Bool(false), "statement is not ExpressionStatement")
                continue
            }

            guard let exp = stmt.expression as? PrefixExpression else {
                #expect(Bool(false), "expression is not PrefixExpression")
                continue
            }

            #expect(exp.operator_ == expectedOperator, "exp.operator is not '\(expectedOperator)'. got=\(exp.operator_)")
        }
    }

    @Test("Infix expression parsing")
    func testParsingInfixExpressions() {
        let tests: [(String, Any, String, Any)] = [
            ("5 + 5;", 5, "+", 5),
            ("5 - 5;", 5, "-", 5),
            ("5 * 5;", 5, "*", 5),
            ("5 / 5;", 5, "/", 5),
            ("5 > 5;", 5, ">", 5),
            ("5 < 5;", 5, "<", 5),
            ("5 == 5;", 5, "==", 5),
            ("5 != 5;", 5, "!=", 5),
            ("true == true", true, "==", true),
            ("true != false", true, "!=", false),
            ("false == false", false, "==", false),
        ]

        for (input, _, expectedOperator, _) in tests {
            let lexer = Lexer(input: input)
            var parser = Parser(lexer: lexer)
            let program = parser.parseProgram()

            checkParserErrors(parser)

            #expect(program.statements.count == 1, "program has not enough statements")

            guard let stmt = program.statements[0] as? ExpressionStatement else {
                #expect(Bool(false), "statement is not ExpressionStatement")
                continue
            }

            guard let exp = stmt.expression as? InfixExpression else {
                #expect(Bool(false), "expression is not InfixExpression")
                continue
            }

            #expect(exp.operator_ == expectedOperator, "exp.operator is not '\(expectedOperator)'. got=\(exp.operator_)")
        }
    }

    @Test("If expression parsing")
    func testIfExpression() {
        let input = "if (x < y) { x }"

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 1, "program has not enough statements")

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            #expect(Bool(false), "statement is not ExpressionStatement")
            return
        }

        guard let exp = stmt.expression as? IfExpression else {
            #expect(Bool(false), "expression is not IfExpression")
            return
        }

        #expect(exp.consequence.statements.count == 1, "consequence is not 1 statement")
    }

    @Test("Function literal parsing")
    func testFunctionLiteralParsing() {
        let input = "fn(x, y) { x + y; }"

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 1, "program has not enough statements")

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            #expect(Bool(false), "statement is not ExpressionStatement")
            return
        }

        guard let function = stmt.expression as? FunctionLiteral else {
            #expect(Bool(false), "expression is not FunctionLiteral")
            return
        }

        #expect(function.parameters.count == 2, "function literal parameters wrong. want 2, got=\(function.parameters.count)")

        #expect(function.parameters[0].value == "x", "parameter not 'x'")
        #expect(function.parameters[1].value == "y", "parameter not 'y'")

        #expect(function.body.statements.count == 1, "function.body.statements has not 1 statement")
    }

    @Test("Call expression parsing")
    func testCallExpressionParsing() {
        let input = "add(1, 2 * 3, 4 + 5);"

        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        checkParserErrors(parser)

        #expect(program.statements.count == 1, "program has not enough statements")

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            #expect(Bool(false), "statement is not ExpressionStatement")
            return
        }

        guard let exp = stmt.expression as? CallExpression else {
            #expect(Bool(false), "expression is not CallExpression")
            return
        }

        guard let ident = exp.function as? Identifier else {
            #expect(Bool(false), "exp.function is not Identifier")
            return
        }

        #expect(ident.value == "add", "ident.value is not 'add'. got=\(ident.value)")
        #expect(exp.arguments.count == 3, "wrong length of arguments. got=\(exp.arguments.count)")
    }

    func checkParserErrors(_ parser: Parser) {
        let errors = parser.errors
        if errors.isEmpty {
            return
        }

        print("parser has \(errors.count) errors")
        for msg in errors {
            print("parser error: \(msg)")
        }
        #expect(Bool(false), "parser has errors")
    }
}
