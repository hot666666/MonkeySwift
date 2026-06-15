import Testing

@testable import MonkeySwift

@Suite("LexerTests")
struct MonkeySwiftLexer {
	@Test func testLexerTokenization() async throws {
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
			"foobar"
			"foo bar"
			{a: 1, b: 2}
			"""

		let expectedTokens: [TokenType] = [
			.let, .identifier(name: "five"), .assign, .int(value: 5), .semicolon,

			.let, .identifier(name: "ten"), .assign, .int(value: 10), .semicolon,

			.let, .identifier(name: "add"), .assign, .function, .leftParen,
			.identifier(name: "x"), .comma, .identifier(name: "y"), .rightParen, .leftBrace,
			.identifier(name: "x"), .plus, .identifier(name: "y"), .semicolon,
			.rightBrace, .semicolon,

			.let, .identifier(name: "result"), .assign, .identifier(name: "add"), .leftParen,

			.identifier(name: "five"), .comma, .identifier(name: "ten"), .rightParen, .semicolon,

			.bang, .minus, .slash, .asterisk, .int(value: 5), .semicolon,

			.int(value: 5), .lessThan, .int(value: 10), .greaterThan, .int(value: 5), .semicolon,
			.if, .leftParen, .int(value: 5), .lessThan, .int(value: 10), .rightParen, .leftBrace,
			.return, .true, .semicolon,
			.rightBrace, .else, .leftBrace,
			.return, .false, .semicolon,
			.rightBrace,

			.int(value: 10), .equal, .int(value: 10), .semicolon,

			.int(value: 10), .notEqual, .int(value: 9), .semicolon,

			.string(value: "foobar"),

			.string(value: "foo bar"),

			.leftBrace, .identifier(name: "a"), .colon, .int(value: 1), .comma,
			.identifier(name: "b"), .colon, .int(value: 2), .rightBrace,

			.eof,
		]

		var lexer = Lexer(input: input)

		for (index, expected) in expectedTokens.enumerated() {
			let token = lexer.nextTokenType()
			#expect(
				token == expected,
				"Token \(index): expected \(expected.literal), got \(token.literal)")
		}
	}

	@Test func testLexerString() async throws {
		let input = "\"Hello, world!\""
		var lexer = Lexer(input: input)

		#expect(lexer.nextTokenType() == .string(value: "Hello, world!"))
		#expect(lexer.nextTokenType() == .eof)
	}

	@Test func testLexerNumbers() async throws {
		let input = "0 1 42 999"
		var lexer = Lexer(input: input)

		#expect(lexer.nextTokenType() == .int(value: 0))
		#expect(lexer.nextTokenType() == .int(value: 1))
		#expect(lexer.nextTokenType() == .int(value: 42))
		#expect(lexer.nextTokenType() == .int(value: 999))
		#expect(lexer.nextTokenType() == .eof)
	}

	@Test func testLexerIdentifiers() async throws {
		let input = "foo bar baz_123 _test"
		var lexer = Lexer(input: input)

		#expect(lexer.nextTokenType() == .identifier(name: "foo"))
		#expect(lexer.nextTokenType() == .identifier(name: "bar"))
		#expect(lexer.nextTokenType() == .identifier(name: "baz_123"))
		#expect(lexer.nextTokenType() == .identifier(name: "_test"))
		#expect(lexer.nextTokenType() == .eof)
	}

	@Test func testLexerKeywords() async throws {
		let input = "let fn true false if else return"
		var lexer = Lexer(input: input)

		#expect(lexer.nextTokenType() == .let)
		#expect(lexer.nextTokenType() == .function)
		#expect(lexer.nextTokenType() == .true)
		#expect(lexer.nextTokenType() == .false)
		#expect(lexer.nextTokenType() == .if)
		#expect(lexer.nextTokenType() == .else)
		#expect(lexer.nextTokenType() == .return)
		#expect(lexer.nextTokenType() == .eof)
	}

	@Test func testLexerOperators() async throws {
		let input = "= + - ! * / < > == !="
		var lexer = Lexer(input: input)

		#expect(lexer.nextTokenType() == .assign)
		#expect(lexer.nextTokenType() == .plus)
		#expect(lexer.nextTokenType() == .minus)
		#expect(lexer.nextTokenType() == .bang)
		#expect(lexer.nextTokenType() == .asterisk)
		#expect(lexer.nextTokenType() == .slash)
		#expect(lexer.nextTokenType() == .lessThan)
		#expect(lexer.nextTokenType() == .greaterThan)
		#expect(lexer.nextTokenType() == .equal)
		#expect(lexer.nextTokenType() == .notEqual)
		#expect(lexer.nextTokenType() == .eof)
	}

	@Test func testLexerDelimiters() async throws {
		let input = "( ) { } [ ] , ;"
		var lexer = Lexer(input: input)

		#expect(lexer.nextTokenType() == .leftParen)
		#expect(lexer.nextTokenType() == .rightParen)
		#expect(lexer.nextTokenType() == .leftBrace)
		#expect(lexer.nextTokenType() == .rightBrace)
		#expect(lexer.nextTokenType() == .leftBracket)
		#expect(lexer.nextTokenType() == .rightBracket)
		#expect(lexer.nextTokenType() == .comma)
		#expect(lexer.nextTokenType() == .semicolon)
		#expect(lexer.nextTokenType() == .eof)
	}
}
