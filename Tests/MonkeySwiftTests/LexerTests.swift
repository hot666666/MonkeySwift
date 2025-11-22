import Testing

@testable import MonkeyCore
@testable import MonkeyLexer

@Suite("Lexer tests")
struct LexerTests {
    @Test("nextTokenType test")
    func testNextTokenType() {
        // given
        let input = """
                let five = 5;
                let ten = 10;

                let add = fn(x, y) {
                    x + y;
                };

                let result = add(five, ten);
                !-/*5;
                5 < 10 > 5;

                if (5 < 10) {
                    return true;
                } else {
                    return false;
                }

                10 == 10;
                10 != 9;
            """

        // when & then
        let expectedTokenTypes: [TokenType] = [
            .let, .identifier(name: "five"), .assign, .int(value: 5), .semicolon,
            .let, .identifier(name: "ten"), .assign, .int(value: 10), .semicolon,
            .let, .identifier(name: "add"), .assign, .function, .leftParen, .identifier(name: "x"),
            .comma, .identifier(name: "y"), .rightParen, .leftBrace,
            .identifier(name: "x"), .plus, .identifier(name: "y"), .semicolon,
            .rightBrace, .semicolon,
            .let, .identifier(name: "result"), .assign, .identifier(name: "add"), .leftParen,
            .identifier(name: "five"), .comma, .identifier(name: "ten"), .rightParen, .semicolon,
            .bang, .minus, .slash, .asterisk, .int(value: 5), .semicolon,
            .int(value: 5), .lessThan, .int(value: 10), .greaterThan, .int(value: 5), .semicolon,
        ]

        var lexer = Lexer(input: input)
        expectedTokenTypes.forEach { expectedTokenType in
            let tokenType = lexer.nextTokenType()

            #expect(
                tokenType == expectedTokenType,
                "tokenType wrong. expected=\(expectedTokenType), got=\(tokenType)")
        }

    }
}
