import Testing
@testable import MonkeySwift

@Suite("ParserTests")
struct MonkeySwiftParser {
    func parseProgram(_ input: String) -> (Program, [String]) {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()
        return (program, parser.errors)
    }

    func checkParserErrors(_ errors: [String]) {
        if errors.count == 0 {
            return
        }
        Issue.record("Parser has \(errors.count) errors")
        for error in errors {
            Issue.record("Parser error: \(error)")
        }
    }

    @Test func testLetStatements() {
        let input = """
        let x = 5;
        let y = 10;
        let foobar = 838383;
        """

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 3)

        let expectedIdentifiers = ["x", "y", "foobar"]

        for (index, expectedIdentifier) in expectedIdentifiers.enumerated() {
            let statement = program.statements[index]
            #expect(statement.tokenLiteral == "let")

            guard let letStmt = statement as? LetStatement else {
                Issue.record("Statement is not LetStatement")
                continue
            }

            #expect(letStmt.name.value == expectedIdentifier)
            #expect(letStmt.name.tokenLiteral == expectedIdentifier)
        }
    }

    @Test func testReturnStatements() {
        let input = """
        return 5;
        return 10;
        return 993322;
        """

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 3)

        for statement in program.statements {
            #expect(statement.tokenLiteral == "return")

            guard statement is ReturnStatement else {
                Issue.record("Statement is not ReturnStatement")
                continue
            }
        }
    }

    @Test func testIdentifierExpression() {
        let input = "foobar;"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 1)

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            Issue.record("Statement is not ExpressionStatement")
            return
        }

        guard let ident = stmt.expression as? Identifier else {
            Issue.record("Expression is not Identifier")
            return
        }

        #expect(ident.value == "foobar")
        #expect(ident.tokenLiteral == "foobar")
    }

    @Test func testIntegerLiteralExpression() {
        let input = "5;"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 1)

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            Issue.record("Statement is not ExpressionStatement")
            return
        }

        guard let literal = stmt.expression as? IntegerLiteral else {
            Issue.record("Expression is not IntegerLiteral")
            return
        }

        #expect(literal.value == 5)
        #expect(literal.tokenLiteral == "5")
    }

    @Test func testBooleanExpression() {
        let tests: [(String, Bool)] = [
            ("true;", true),
            ("false;", false)
        ]

        for (input, expectedValue) in tests {
            let (program, errors) = parseProgram(input)
            checkParserErrors(errors)

            #expect(program.statements.count == 1)

            guard let stmt = program.statements[0] as? ExpressionStatement else {
                Issue.record("Statement is not ExpressionStatement")
                continue
            }

            guard let boolean = stmt.expression as? BooleanLiteral else {
                Issue.record("Expression is not BooleanLiteral")
                continue
            }

            #expect(boolean.value == expectedValue)
        }
    }

    @Test func testPrefixExpressions() {
        let tests: [(String, String, Any)] = [
            ("!5;", "!", 5),
            ("-15;", "-", 15),
            ("!true;", "!", true),
            ("!false;", "!", false)
        ]

        for (input, expectedOperator, expectedValue) in tests {
            let (program, errors) = parseProgram(input)
            checkParserErrors(errors)

            #expect(program.statements.count == 1)

            guard let stmt = program.statements[0] as? ExpressionStatement else {
                Issue.record("Statement is not ExpressionStatement")
                continue
            }

            guard let prefixExpr = stmt.expression as? PrefixExpression else {
                Issue.record("Expression is not PrefixExpression")
                continue
            }

            #expect(prefixExpr.operatorSymbol == expectedOperator)

            if let intValue = expectedValue as? Int {
                guard let right = prefixExpr.right as? IntegerLiteral else {
                    Issue.record("Right expression is not IntegerLiteral")
                    continue
                }
                #expect(right.value == intValue)
            } else if let boolValue = expectedValue as? Bool {
                guard let right = prefixExpr.right as? BooleanLiteral else {
                    Issue.record("Right expression is not BooleanLiteral")
                    continue
                }
                #expect(right.value == boolValue)
            }
        }
    }

    @Test func testInfixExpressions() {
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
            ("false == false", false, "==", false)
        ]

        for (input, leftValue, operatorSymbol, rightValue) in tests {
            let (program, errors) = parseProgram(input)
            checkParserErrors(errors)

            #expect(program.statements.count == 1)

            guard let stmt = program.statements[0] as? ExpressionStatement else {
                Issue.record("Statement is not ExpressionStatement")
                continue
            }

            guard let infixExpr = stmt.expression as? InfixExpression else {
                Issue.record("Expression is not InfixExpression")
                continue
            }

            #expect(infixExpr.operatorSymbol == operatorSymbol)

            if let intLeft = leftValue as? Int, let intRight = rightValue as? Int {
                guard let left = infixExpr.left as? IntegerLiteral,
                      let right = infixExpr.right as? IntegerLiteral else {
                    Issue.record("Left or Right is not IntegerLiteral")
                    continue
                }
                #expect(left.value == intLeft)
                #expect(right.value == intRight)
            } else if let boolLeft = leftValue as? Bool, let boolRight = rightValue as? Bool {
                guard let left = infixExpr.left as? BooleanLiteral,
                      let right = infixExpr.right as? BooleanLiteral else {
                    Issue.record("Left or Right is not BooleanLiteral")
                    continue
                }
                #expect(left.value == boolLeft)
                #expect(right.value == boolRight)
            }
        }
    }

    @Test func testOperatorPrecedence() {
        let tests: [(String, String)] = [
            ("-a * b", "((-a) * b)"),
            ("!-a", "(!(-a))"),
            ("a + b + c", "((a + b) + c)"),
            ("a + b - c", "((a + b) - c)"),
            ("a * b * c", "((a * b) * c)"),
            ("a * b / c", "((a * b) / c)"),
            ("a + b / c", "(a + (b / c))"),
            ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
            ("3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"),
            ("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"),
            ("5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"),
            ("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
            ("true", "true"),
            ("false", "false"),
            ("3 > 5 == false", "((3 > 5) == false)"),
            ("3 < 5 == true", "((3 < 5) == true)"),
            ("1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"),
            ("(5 + 5) * 2", "((5 + 5) * 2)"),
            ("2 / (5 + 5)", "(2 / (5 + 5))"),
            ("-(5 + 5)", "(-(5 + 5))"),
            ("!(true == true)", "(!(true == true))")
        ]

        for (input, expected) in tests {
            let (program, errors) = parseProgram(input)
            checkParserErrors(errors)

            let actual = program.string()
            #expect(actual == expected, "Expected \(expected), got \(actual)")
        }
    }

    @Test func testIfExpression() {
        let input = "if (x < y) { x }"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 1)

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            Issue.record("Statement is not ExpressionStatement")
            return
        }

        guard let ifExpr = stmt.expression as? IfExpression else {
            Issue.record("Expression is not IfExpression")
            return
        }

        guard let condition = ifExpr.condition as? InfixExpression else {
            Issue.record("Condition is not InfixExpression")
            return
        }

        #expect(condition.operatorSymbol == "<")

        #expect(ifExpr.consequence.statements.count == 1)

        guard let consequenceStmt = ifExpr.consequence.statements[0] as? ExpressionStatement else {
            Issue.record("Consequence statement is not ExpressionStatement")
            return
        }

        guard let ident = consequenceStmt.expression as? Identifier else {
            Issue.record("Consequence expression is not Identifier")
            return
        }

        #expect(ident.value == "x")
        #expect(ifExpr.alternative == nil)
    }

    @Test func testIfElseExpression() {
        let input = "if (x < y) { x } else { y }"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 1)

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            Issue.record("Statement is not ExpressionStatement")
            return
        }

        guard let ifExpr = stmt.expression as? IfExpression else {
            Issue.record("Expression is not IfExpression")
            return
        }

        #expect(ifExpr.consequence.statements.count == 1)
        #expect(ifExpr.alternative != nil)
        #expect(ifExpr.alternative?.statements.count == 1)
    }

    @Test func testFunctionLiteral() {
        let input = "fn(x, y) { x + y; }"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 1)

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            Issue.record("Statement is not ExpressionStatement")
            return
        }

        guard let funcLiteral = stmt.expression as? FunctionLiteral else {
            Issue.record("Expression is not FunctionLiteral")
            return
        }

        #expect(funcLiteral.parameters.count == 2)
        #expect(funcLiteral.parameters[0].value == "x")
        #expect(funcLiteral.parameters[1].value == "y")

        #expect(funcLiteral.body.statements.count == 1)

        guard let bodyStmt = funcLiteral.body.statements[0] as? ExpressionStatement else {
            Issue.record("Body statement is not ExpressionStatement")
            return
        }

        guard let infixExpr = bodyStmt.expression as? InfixExpression else {
            Issue.record("Body expression is not InfixExpression")
            return
        }

        #expect(infixExpr.operatorSymbol == "+")
    }

    @Test func testFunctionParameters() {
        let tests: [(String, [String])] = [
            ("fn() {};", []),
            ("fn(x) {};", ["x"]),
            ("fn(x, y, z) {};", ["x", "y", "z"])
        ]

        for (input, expectedParams) in tests {
            let (program, errors) = parseProgram(input)
            checkParserErrors(errors)

            guard let stmt = program.statements[0] as? ExpressionStatement else {
                Issue.record("Statement is not ExpressionStatement")
                continue
            }

            guard let funcLiteral = stmt.expression as? FunctionLiteral else {
                Issue.record("Expression is not FunctionLiteral")
                continue
            }

            #expect(funcLiteral.parameters.count == expectedParams.count)

            for (index, expectedParam) in expectedParams.enumerated() {
                #expect(funcLiteral.parameters[index].value == expectedParam)
            }
        }
    }

    @Test func testCallExpression() {
        let input = "add(1, 2 * 3, 4 + 5);"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.statements.count == 1)

        guard let stmt = program.statements[0] as? ExpressionStatement else {
            Issue.record("Statement is not ExpressionStatement")
            return
        }

        guard let callExpr = stmt.expression as? CallExpression else {
            Issue.record("Expression is not CallExpression")
            return
        }

        guard let ident = callExpr.function as? Identifier else {
            Issue.record("Function is not Identifier")
            return
        }

        #expect(ident.value == "add")
        #expect(callExpr.arguments.count == 3)

        guard let arg1 = callExpr.arguments[0] as? IntegerLiteral else {
            Issue.record("Argument 0 is not IntegerLiteral")
            return
        }
        #expect(arg1.value == 1)

        guard let arg2 = callExpr.arguments[1] as? InfixExpression else {
            Issue.record("Argument 1 is not InfixExpression")
            return
        }
        #expect(arg2.operatorSymbol == "*")

        guard let arg3 = callExpr.arguments[2] as? InfixExpression else {
            Issue.record("Argument 2 is not InfixExpression")
            return
        }
        #expect(arg3.operatorSymbol == "+")
    }

    @Test func testCallExpressionPrecedence() {
        let tests: [(String, String)] = [
            ("a + add(b * c) + d", "((a + add((b * c))) + d)"),
            ("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))", "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
            ("add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))")
        ]

        for (input, expected) in tests {
            let (program, errors) = parseProgram(input)
            checkParserErrors(errors)

            let actual = program.string()
            #expect(actual == expected, "Expected \(expected), got \(actual)")
        }
    }

    @Test func testStringOutput() {
        let input = "let myVar = anotherVar;"

        let (program, errors) = parseProgram(input)
        checkParserErrors(errors)

        #expect(program.string() == "let myVar = anotherVar;")
    }
}
