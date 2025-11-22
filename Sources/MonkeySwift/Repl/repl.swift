private let prompt = ">> "

public struct Repl {

    public static func start(with input: String) {
        var lexer = Lexer(input: input)
        var tokenType = lexer.nextTokenType()

        while tokenType != .eof {
            print(tokenType.literal)
            tokenType = lexer.nextTokenType()
        }
    }
}
