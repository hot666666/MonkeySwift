import Testing

@testable import MonkeySwift

@Suite("EvaluatorTests")
struct MonkeySwiftEvaluator {
    func testEval(_ input: String) -> any Object {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()
        let env = Environment()
        return eval(node: program, environment: env)
    }

    @Test func testIntegerExpression() {
        let tests: [(String, Int)] = [
            ("5", 5),
            ("10", 10),
            ("-5", -5),
            ("-10", -10),
            ("5 + 5 + 5 + 5 - 10", 10),
            ("2 * 2 * 2 * 2 * 2", 32),
            ("-50 + 100 + -50", 0),
            ("5 * 2 + 10", 20),
            ("5 + 2 * 10", 25),
            ("20 + 2 * -10", 0),
            ("50 / 2 * 2 + 10", 60),
            ("2 * (5 + 10)", 30),
            ("3 * 3 * 3 + 10", 37),
            ("3 * (3 * 3) + 10", 37),
            ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            guard let integer = evaluated as? Integer else {
                Issue.record("Object is not Integer. got=\(type(of: evaluated))")
                continue
            }
            #expect(integer.value == expected, "Expected \(expected), got \(integer.value)")
        }
    }

    @Test func testBooleanExpression() {
        let tests: [(String, Bool)] = [
            ("true", true),
            ("false", false),
            ("1 < 2", true),
            ("1 > 2", false),
            ("1 < 1", false),
            ("1 > 1", false),
            ("1 == 1", true),
            ("1 != 1", false),
            ("1 == 2", false),
            ("1 != 2", true),
            ("true == true", true),
            ("false == false", true),
            ("true == false", false),
            ("true != false", true),
            ("false != true", true),
            ("(1 < 2) == true", true),
            ("(1 < 2) == false", false),
            ("(1 > 2) == true", false),
            ("(1 > 2) == false", true),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            guard let boolean = evaluated as? Boolean else {
                Issue.record("Object is not Boolean. got=\(type(of: evaluated))")
                continue
            }
            #expect(boolean.value == expected, "Expected \(expected), got \(boolean.value)")
        }
    }

    @Test func testBangOperator() {
        let tests: [(String, Bool)] = [
            ("!true", false),
            ("!false", true),
            ("!5", false),
            ("!!true", true),
            ("!!false", false),
            ("!!5", true),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            guard let boolean = evaluated as? Boolean else {
                Issue.record("Object is not Boolean. got=\(type(of: evaluated))")
                continue
            }
            #expect(boolean.value == expected, "Expected \(expected), got \(boolean.value)")
        }
    }

    @Test func testIfElseExpressions() {
        let tests: [(String, Any?)] = [
            ("if (true) { 10 }", 10),
            ("if (false) { 10 }", nil),
            ("if (1) { 10 }", 10),
            ("if (1 < 2) { 10 }", 10),
            ("if (1 > 2) { 10 }", nil),
            ("if (1 > 2) { 10 } else { 20 }", 20),
            ("if (1 < 2) { 10 } else { 20 }", 10),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)

            if let expectedInt = expected as? Int {
                guard let integer = evaluated as? Integer else {
                    Issue.record("Object is not Integer. got=\(type(of: evaluated))")
                    continue
                }
                #expect(integer.value == expectedInt)
            } else {
                #expect(evaluated is Null, "Expected Null, got \(type(of: evaluated))")
            }
        }
    }

    @Test func testReturnStatements() {
        let tests: [(String, Int)] = [
            ("return 10;", 10),
            ("return 10; 9;", 10),
            ("return 2 * 5; 9;", 10),
            ("9; return 2 * 5; 9;", 10),
            (
                """
                if (10 > 1) {
                    if (10 > 1) {
                        return 10;
                    }
                    return 1;
                }
                """, 10
            ),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            guard let integer = evaluated as? Integer else {
                Issue.record("Object is not Integer. got=\(type(of: evaluated))")
                continue
            }
            #expect(integer.value == expected)
        }
    }

    @Test func testErrorHandling() {
        let tests: [(String, String)] = [
            ("5 + true;", "type mismatch: INTEGER + BOOLEAN"),
            ("5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"),
            ("-true", "unknown operator: -BOOLEAN"),
            ("true + false;", "unknown operator: BOOLEAN + BOOLEAN"),
            ("5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"),
            ("if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"),
            (
                """
                if (10 > 1) {
                    if (10 > 1) {
                        return true + false;
                    }
                    return 1;
                }
                """, "unknown operator: BOOLEAN + BOOLEAN"
            ),
            ("foobar", "identifier not found: foobar"),
        ]

        for (input, expectedMessage) in tests {
            let evaluated = testEval(input)
            guard let error = evaluated as? ErrorObject else {
                Issue.record("Object is not ErrorObject. got=\(type(of: evaluated))")
                continue
            }
            #expect(
                error.message == expectedMessage,
                "Expected '\(expectedMessage)', got '\(error.message)'")
        }
    }

    @Test func testLetStatements() {
        let tests: [(String, Int)] = [
            ("let a = 5; a;", 5),
            ("let a = 5 * 5; a;", 25),
            ("let a = 5; let b = a; b;", 5),
            ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            guard let integer = evaluated as? Integer else {
                Issue.record("Object is not Integer. got=\(type(of: evaluated))")
                continue
            }
            #expect(integer.value == expected)
        }
    }

    @Test func testFunctionObject() {
        let input = "fn(x) { x + 2; };"

        let evaluated = testEval(input)
        guard let function = evaluated as? Function else {
            Issue.record("Object is not Function. got=\(type(of: evaluated))")
            return
        }

        #expect(function.parameters.count == 1)
        #expect(function.parameters[0].value == "x")
        #expect(function.body.string() == "(x + 2)")
    }

    @Test func testFunctionApplication() {
        let tests: [(String, Int)] = [
            ("let identity = fn(x) { x; }; identity(5);", 5),
            ("let identity = fn(x) { return x; }; identity(5);", 5),
            ("let double = fn(x) { x * 2; }; double(5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
            ("fn(x) { x; }(5)", 5),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            guard let integer = evaluated as? Integer else {
                Issue.record("Object is not Integer. got=\(type(of: evaluated))")
                continue
            }
            #expect(integer.value == expected)
        }
    }

    @Test func testClosures() {
        let input = """
            let newAdder = fn(x) {
                fn(y) { x + y };
            };
            let addTwo = newAdder(2);
            addTwo(2);
            """

        let evaluated = testEval(input)
        guard let integer = evaluated as? Integer else {
            Issue.record("Object is not Integer. got=\(type(of: evaluated))")
            return
        }
        #expect(integer.value == 4)
    }

    @Test func testRecursiveFunction() {
        let input = """
            let fibonacci = fn(x) {
                if (x == 0) {
                    0
                } else {
                    if (x == 1) {
                        1
                    } else {
                        fibonacci(x - 1) + fibonacci(x - 2)
                    }
                }
            };
            fibonacci(10);
            """

        let evaluated = testEval(input)
        guard let integer = evaluated as? Integer else {
            Issue.record("Object is not Integer. got=\(type(of: evaluated))")
            return
        }
        #expect(integer.value == 55)
    }
}
