// MARK: - Lexer
/// Lexer는 입력된 문자열을 토큰으로 변환하는 역할을 합니다.
/// - input: 입력된 문자열
/// - currentIndex: 현재 위치 / character: 현재 위치의 문자
/// - readIndex: 다음 읽을 위치
public struct Lexer: Sendable {
    let input: String
    var currentIndex: String.Index
    var character: Character?
    var readIndex: String.Index

    public init(input: String) {
        self.input = input
        self.currentIndex = input.startIndex
        self.character = nil
        self.readIndex = input.startIndex
        /// Lexer 상태 세팅
        /// - character = input[currentIndex]
        /// - readIndex는 다음 문자 위치로 이동
        self.setNextCharacter()
    }

    public mutating func nextTokenType() -> TokenType {
        let tokenType: TokenType

        skipWhitespace()

        switch character {
        case TokenSymbol.equal.rawValue where peekCharacter() == TokenSymbol.equal.rawValue:
            setNextCharacter()
            tokenType = .equal
        case TokenSymbol.equal.rawValue:
            tokenType = .assign
        case TokenSymbol.plus.rawValue:
            tokenType = .plus
        case TokenSymbol.minus.rawValue:
            tokenType = .minus
        case TokenSymbol.bang.rawValue where peekCharacter() == TokenSymbol.equal.rawValue:
            setNextCharacter()
            tokenType = .notEqual
        case TokenSymbol.bang.rawValue:
            tokenType = .bang
        case TokenSymbol.asterisk.rawValue:
            tokenType = .asterisk
        case TokenSymbol.slash.rawValue:
            tokenType = .slash
        case TokenSymbol.comma.rawValue:
            tokenType = .comma
        case TokenSymbol.semicolon.rawValue:
            tokenType = .semicolon
        case TokenSymbol.colon.rawValue:
            tokenType = .colon
        case TokenSymbol.lessThan.rawValue:
            tokenType = .lessThan
        case TokenSymbol.greaterThan.rawValue:
            tokenType = .greaterThan
        case TokenSymbol.leftParen.rawValue:
            tokenType = .leftParen
        case TokenSymbol.rightParen.rawValue:
            tokenType = .rightParen
        case TokenSymbol.leftBrace.rawValue:
            tokenType = .leftBrace
        case TokenSymbol.rightBrace.rawValue:
            tokenType = .rightBrace
        case TokenSymbol.leftBracket.rawValue:
            tokenType = .leftBracket
        case TokenSymbol.rightBracket.rawValue:
            tokenType = .rightBracket
        case let character? where isString(character):
            // String Literal
            return TokenType(string: readString())
        case let character? where isLetter(character):
            // Identifier or Keyword
            return TokenType(word: readWord())
        case let character? where isDigit(character):
            // Int Literal
            return TokenType(number: readNumber())
        case nil:
            return .eof
        default:
            return .illegal
        }

        setNextCharacter()
        return tokenType
    }

    private mutating func setNextCharacter() {
        guard readIndex < input.endIndex else {
            currentIndex = readIndex
            character = nil
            return
        }

        currentIndex = readIndex
        character = input[readIndex]
        readIndex = input.index(after: readIndex)
    }

    private mutating func readCharacter(while condition: ((Character) -> Bool)) -> String {
        let startIndex = currentIndex

        while let character = self.character, condition(character) {
            setNextCharacter()
        }

        return String(input[startIndex..<currentIndex])
    }

    private mutating func readString() -> String {
        // 시작과 끝 "\"" 제거
        setNextCharacter()
        let startIndex = currentIndex

        while let character = self.character, character != "\"" {
            setNextCharacter()
        }

        let string = String(input[startIndex..<currentIndex])
        setNextCharacter()
        return string
    }

    private mutating func readWord() -> String {
        return readCharacter(while: isLetterOrDigit)
    }

    private mutating func readNumber() -> String {
        return readCharacter(while: isDigit)
    }

    private func peekCharacter() -> Character? {
        guard readIndex < input.endIndex else {
            return nil
        }

        return input[readIndex]
    }

    private mutating func skipWhitespace() {
        while character == " " || character == "\t" || character == "\n" || character == "\r" {
            setNextCharacter()
        }
    }

    private func isString(_ character: Character) -> Bool {
        return character == "\""
    }

    private func isLetter(_ character: Character) -> Bool {
        return ("a"..."z").contains(character) || ("A"..."Z").contains(character)
            || character == "_"
    }

    private func isDigit(_ character: Character) -> Bool {
        return ("0"..."9").contains(character)
    }

    private func isLetterOrDigit(_ character: Character) -> Bool {
        return isLetter(character) || isDigit(character)
    }
}
