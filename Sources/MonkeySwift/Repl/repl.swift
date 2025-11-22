import MonkeyCore
import MonkeyLexer
import MonkeyParser
import MonkeyEvaluator

private let prompt = ">> "

public struct Repl {

    public static func start(with input: String, env: Environment = Environment()) {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        if !parser.errors.isEmpty {
            printParserErrors(parser.errors)
            return
        }

        let evaluated = eval(node: program, env: env)
        print(evaluated.inspect())
    }

    private static func printParserErrors(_ errors: [String]) {
        print("Woops! We ran into some monkey business here!")
        print(" parser errors:")
        for msg in errors {
            print("\t\(msg)")
        }
    }
}
