import Foundation

public func startRepl() {
    let env = Environment()

    print("Hello! This is the Monkey programming language!")
    print("Feel free to type in commands")

    while true {
        print(">> ", terminator: "")

        guard let line = readLine() else {
            return
        }

        if line.isEmpty {
            continue
        }

        // Exit commands
        if line == "exit" || line == "quit" {
            print("Goodbye!")
            return
        }

        let lexer = Lexer(input: line)
        var parser = Parser(lexer: lexer)
        let program = parser.parseProgram()

        if !parser.errors.isEmpty {
            printParserErrors(parser.errors)
            continue
        }

        let evaluated = eval(node: program, environment: env)
        print(evaluated.inspect())
    }
}

private func printParserErrors(_ errors: [String]) {
    print("Woops! We ran into some monkey business here!")
    print(" parser errors:")
    for error in errors {
        print("\t\(error)")
    }
}
