import Testing
@testable import MonkeySwift

@Test func testTokenSymbolCreation() {
    let token1 = TokenType(symbol: "+")
    #expect(token1 == .plus)
    #expect(token1.literal == "+")

    let token2 = TokenType(symbol: "=")
    #expect(token2 == .assign)
    #expect(token2.literal == "=")

    let token3 = TokenType(symbol: "(")
    #expect(token3 == .leftParen)
}

@Test func testTokenNumberCreation() {
    let token = TokenType(number: "42")
    #expect(token == .int(value: 42))
    #expect(token.literal == "42")
}

@Test func testTokenIdentifierCreation() {
    let token1 = TokenType(identifier: "foobar")
    #expect(token1 == .identifier(name: "foobar"))
    #expect(token1.literal == "foobar")

    let token2 = TokenType(identifier: "let")
    #expect(token2 == .let)
    #expect(token2.literal == "let")

    let token3 = TokenType(identifier: "fn")
    #expect(token3 == .function)
    #expect(token3.literal == "fn")
}

@Test func testTokenLiterals() {
    #expect(TokenType.eof.literal == "EOF")
    #expect(TokenType.illegal.literal == "Illegal")
    #expect(TokenType.equal.literal == "==")
    #expect(TokenType.notEqual.literal == "!=")
    #expect(TokenType.lessThan.literal == "<")
    #expect(TokenType.greaterThan.literal == ">")
}
