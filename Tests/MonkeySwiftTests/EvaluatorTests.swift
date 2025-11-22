import Testing

@testable import MonkeyCore
@testable import MonkeyLexer
@testable import MonkeyParser
@testable import MonkeyEvaluator

@Suite("Evaluator tests")
struct EvaluatorTests {
    @Test("Integer expression evaluation")
    func testEvalIntegerExpression() {
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
            testIntegerObject(evaluated, expected: expected)
        }
    }

    @Test("Boolean expression evaluation")
    func testEvalBooleanExpression() {
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
            testBooleanObject(evaluated, expected: expected)
        }
    }

    @Test("Bang operator evaluation")
    func testBangOperator() {
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
            testBooleanObject(evaluated, expected: expected)
        }
    }

    @Test("If/Else expression evaluation")
    func testIfElseExpressions() {
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
            if let intValue = expected as? Int {
                testIntegerObject(evaluated, expected: intValue)
            } else {
                testNullObject(evaluated)
            }
        }
    }

    @Test("Return statement evaluation")
    func testReturnStatements() {
        let tests: [(String, Int)] = [
            ("return 10;", 10),
            ("return 10; 9;", 10),
            ("return 2 * 5; 9;", 10),
            ("9; return 2 * 5; 9;", 10),
            ("""
                if (10 > 1) {
                    if (10 > 1) {
                        return 10;
                    }
                    return 1;
                }
                """, 10),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            testIntegerObject(evaluated, expected: expected)
        }
    }

    @Test("Error handling")
    func testErrorHandling() {
        let tests: [(String, String)] = [
            ("5 + true;", "type mismatch: INTEGER + BOOLEAN"),
            ("5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"),
            ("-true", "unknown operator: -BOOLEAN"),
            ("true + false;", "unknown operator: BOOLEAN + BOOLEAN"),
            ("5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"),
            ("if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"),
            ("""
                if (10 > 1) {
                    if (10 > 1) {
                        return true + false;
                    }
                    return 1;
                }
                """, "unknown operator: BOOLEAN + BOOLEAN"),
            ("foobar", "identifier not found: foobar"),
        ]

        for (input, expectedMessage) in tests {
            let evaluated = testEval(input)

            guard let errObj = evaluated as? ErrorObject else {
                #expect(Bool(false), "no error object returned. got=\(type(of: evaluated))")
                continue
            }

            #expect(errObj.message == expectedMessage,
                   "wrong error message. expected=\(expectedMessage), got=\(errObj.message)")
        }
    }

    @Test("Let statement evaluation")
    func testLetStatements() {
        let tests: [(String, Int)] = [
            ("let a = 5; a;", 5),
            ("let a = 5 * 5; a;", 25),
            ("let a = 5; let b = a; b;", 5),
            ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
        ]

        for (input, expected) in tests {
            let evaluated = testEval(input)
            testIntegerObject(evaluated, expected: expected)
        }
    }

    @Test("Function object evaluation")
    func testFunctionObject() {
        let input = "fn(x) { x + 2; };"

        let evaluated = testEval(input)

        guard let fn = evaluated as? FunctionObject else {
            #expect(Bool(false), "object is not FunctionObject. got=\(type(of: evaluated))")
            return
        }

        #expect(fn.parameters.count == 1, "function has wrong parameters. Parameters=\(fn.parameters)")

        #expect(fn.parameters[0].string() == "x", "parameter is not 'x'. got=\(fn.parameters[0])")

        let expectedBody = "(x + 2)"

        #expect(fn.body.string() == expectedBody, "body is not \(expectedBody). got=\(fn.body.string())")
    }

    @Test("Function application")
    func testFunctionApplication() {
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
            testIntegerObject(evaluated, expected: expected)
        }
    }

    @Test("Closures")
    func testClosures() {
        let input = """
            let newAdder = fn(x) {
                fn(y) { x + y };
            };

            let addTwo = newAdder(2);
            addTwo(2);
            """

        let evaluated = testEval(input)
        testIntegerObject(evaluated, expected: 4)
    }

    // MARK: - Helper Functions

    func testEval(_ input: String) -> Object {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()
        let env = Environment()

        return eval(node: program, env: env)
    }

    func testIntegerObject(_ obj: Object, expected: Int) {
        guard let result = obj as? IntegerObject else {
            #expect(Bool(false), "object is not IntegerObject. got=\(type(of: obj))")
            return
        }

        #expect(result.value == expected, "object has wrong value. got=\(result.value), want=\(expected)")
    }

    func testBooleanObject(_ obj: Object, expected: Bool) {
        guard let result = obj as? BooleanObject else {
            #expect(Bool(false), "object is not BooleanObject. got=\(type(of: obj))")
            return
        }

        #expect(result.value == expected, "object has wrong value. got=\(result.value), want=\(expected)")
    }

    func testNullObject(_ obj: Object) {
        #expect(obj is NullObject, "object is not NullObject. got=\(type(of: obj))")
    }
}
