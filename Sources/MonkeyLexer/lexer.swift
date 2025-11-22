import MonkeyCore

typealias Position = Int

// MARK: - Lexer
public struct Lexer {
    let input: String
    var currentPosition: Position = 0  // input에서 현재 위치
    var readPosition: Position = 0  // input에서 다음 위치(읽기 시작 위치)
    var character: Character?  // 현재 위치의 문자

    public init(input: String) {
        self.input = input

        setNextCharacter()
    }

    public mutating func nextTokenType() -> TokenType {
        let tokenType: TokenType

        skipWhitespace()

        // ==, != 에 대해서는 peekCharacter()를 통해 다음 문자를 확인
        // Letter, Number에 대해서는 readCharacter()를 통해 문자열을 읽음
        switch character {
        case TokenSymbol.equal.rawValue where peekCharacter() == TokenSymbol.equal.rawValue:
            tokenType = .equal
        case TokenSymbol.equal.rawValue:
            tokenType = .assign
        case TokenSymbol.plus.rawValue:
            tokenType = .plus
        case TokenSymbol.minus.rawValue:
            tokenType = .minus
        case TokenSymbol.bang.rawValue where peekCharacter() == TokenSymbol.equal.rawValue:
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
        case let character? where isLetter(character):
            return TokenType(identifier: readIdentifier())
        case let character? where isDigit(character):
            return TokenType(number: readNumber())
        case nil:
            return .eof
        default:
            return .illegal
        }

        setNextCharacter()
        return tokenType
    }

    // character(currentPosition, readPosition) 업데이트
    private mutating func setNextCharacter() {
        if readPosition < input.count {
            let index = input.index(input.startIndex, offsetBy: readPosition)
            character = input[index]
        } else {
            character = nil
        }
        currentPosition = readPosition
        readPosition += 1
    }

    // currentPosition와 해당 위치에 해당하는 condition을 만족하는 문자열 반환(Identifier, Number)
    private mutating func readCharacter(while condition: ((Character) -> Bool)) -> String {
        let position = currentPosition

        while let character = self.character, condition(character) {
            setNextCharacter()
        }
        let startIndex = input.index(input.startIndex, offsetBy: position)
        let endIndex = input.index(startIndex, offsetBy: currentPosition - position)
        return String(input[startIndex..<endIndex])
    }

    private mutating func readIdentifier() -> String {
        return readCharacter(while: isLetter)
    }

    private mutating func readNumber() -> String {
        return readCharacter(while: isDigit)
    }

    // readPosition 위치의 문자 반환
    private func peekCharacter() -> Character? {
        guard readPosition <= input.count else {
            return nil
        }
        let index = input.index(input.startIndex, offsetBy: readPosition)
        return input[index]
    }

    private mutating func skipWhitespace() {
        while character == " " || character == "\t" || character == "\n" || character == "\r" {
            setNextCharacter()
        }
    }

    private func isLetter(_ character: Character) -> Bool {
        return ("a"..."z").contains(character) || ("A"..."Z").contains(character)
            || character == "_"
    }

    private func isDigit(_ character: Character) -> Bool {
        return ("0"..."9").contains(character)
    }
}
