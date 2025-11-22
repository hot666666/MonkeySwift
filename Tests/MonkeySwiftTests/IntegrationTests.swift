import Testing
@testable import MonkeySwift

@Suite("IntegrationTests")
struct MonkeySwiftIntegration {
    func executeCode(_ input: String) -> any Object {
        let env = Environment()
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        if !parser.errors.isEmpty {
            Issue.record("Parser errors: \(parser.errors)")
        }

        return eval(node: program, environment: env)
    }

    @Test func testCompleteProgram() {
        let input = """
        let x = 5;
        let y = 10;
        let add = fn(a, b) { a + b };
        add(x, y);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 15)
    }

    @Test func testFactorial() {
        let input = """
        let factorial = fn(n) {
            if (n == 0) {
                1
            } else {
                n * factorial(n - 1)
            }
        };
        factorial(5);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 120)
    }

    @Test func testHigherOrderFunction() {
        let input = """
        let twice = fn(f, x) {
            f(f(x))
        };
        let addTwo = fn(x) {
            x + 2
        };
        twice(addTwo, 1);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 5)
    }

    @Test func testClosureCounter() {
        let input = """
        let newCounter = fn() {
            let count = 0;
            fn() { count }
        };
        let counter = newCounter();
        counter();
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 0)
    }

    @Test func testComplexExpression() {
        let input = """
        let a = 5;
        let b = 10;
        let c = 15;
        (a + b) * c - (a * b);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 175) // (5 + 10) * 15 - (5 * 10) = 15 * 15 - 50 = 225 - 50 = 175
    }

    @Test func testNestedFunctions() {
        let input = """
        let outer = fn(x) {
            let inner = fn(y) {
                x + y
            };
            inner
        };
        let addFive = outer(5);
        addFive(3);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 8)
    }

    @Test func testConditionalLogic() {
        let input = """
        let max = fn(a, b) {
            if (a > b) {
                a
            } else {
                b
            }
        };
        max(10, 20);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 20)
    }

    @Test func testBooleanLogic() {
        let input = """
        let isPositive = fn(x) {
            if (x > 0) {
                true
            } else {
                false
            }
        };
        isPositive(5);
        """

        let result = executeCode(input)
        guard let boolean = result as? Boolean else {
            Issue.record("Result is not Boolean")
            return
        }
        #expect(boolean.value == true)
    }

    @Test func testEnvironmentPersistence() {
        let env = Environment()

        // First statement
        let lexer1 = Lexer(input: "let x = 10;")
        var parser1 = Parser(lexer: lexer1)
        let program1 = parser1.parseProgram()
        _ = eval(node: program1, environment: env)

        // Second statement using x
        let lexer2 = Lexer(input: "x + 5;")
        var parser2 = Parser(lexer: lexer2)
        let program2 = parser2.parseProgram()
        let result = eval(node: program2, environment: env)

        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 15)
    }

    @Test func testErrorPropagation() {
        let input = """
        let divide = fn(a, b) {
            if (b == 0) {
                return 0;
            } else {
                a / b
            }
        };
        divide(10, 2);
        """

        let result = executeCode(input)
        guard let integer = result as? Integer else {
            Issue.record("Result is not Integer")
            return
        }
        #expect(integer.value == 5)
    }
}
