// MARK: - TokenSymbol
public enum TokenSymbol: Character {
    case equal = "="
    case plus = "+"
    case minus = "-"
    case bang = "!"
    case asterisk = "*"
    case slash = "/"
    case comma = ","
    case semicolon = ";"
    case leftParen = "("
    case rightParen = ")"
    case leftBrace = "{"
    case rightBrace = "}"
    case lessThan = "<"
    case greaterThan = ">"
    case leftBracket = "["
    case rightBracket = "]"
    case colon = ":"
}

// MARK: - TokenKeyword
public enum TokenKeyword: String {
    case fn = "fn"
    case `let` = "let"
    case `true` = "true"
    case `false` = "false"
    case `if` = "if"
    case `else` = "else"
    case `return` = "return"
}

// MARK: - TokenType
public enum TokenType: Equatable, Sendable {
    case unknown, illegal, eof

    // Identifiers + literals
    case identifier(name: String)
    case int(value: Int)
    case string(value: String)

    // Operators
    case assign, plus, minus, bang, asterisk, slash, lessThan, greaterThan, equal, notEqual

    case leftParen, rightParen, leftBrace, rightBrace, leftBracket, rightBracket
    case colon, comma, semicolon

    // Keywords
    case function, `let`, `true`, `false`, `if`, `else`, `return`

    public var literal: String {
        switch self {
        case .illegal: return "Illegal"
        case .eof: return "EOF"
        case .identifier(let name): return name
        case .int(let value): return "\(value)"
        case .string(let value): return value
        case .assign: return String(TokenSymbol.equal.rawValue)
        case .plus: return String(TokenSymbol.plus.rawValue)
        case .minus: return String(TokenSymbol.minus.rawValue)
        case .bang: return String(TokenSymbol.bang.rawValue)
        case .asterisk: return String(TokenSymbol.asterisk.rawValue)
        case .slash: return String(TokenSymbol.slash.rawValue)
        case .comma: return String(TokenSymbol.comma.rawValue)
        case .semicolon: return String(TokenSymbol.semicolon.rawValue)
        case .lessThan: return String(TokenSymbol.lessThan.rawValue)
        case .greaterThan: return String(TokenSymbol.greaterThan.rawValue)
        case .equal: return "=="
        case .notEqual: return "!="
        case .leftParen: return String(TokenSymbol.leftParen.rawValue)
        case .rightParen: return String(TokenSymbol.rightParen.rawValue)
        case .leftBrace: return String(TokenSymbol.leftBrace.rawValue)
        case .rightBrace: return String(TokenSymbol.rightBrace.rawValue)
        case .leftBracket: return String(TokenSymbol.leftBracket.rawValue)
        case .rightBracket: return String(TokenSymbol.rightBracket.rawValue)
        case .colon: return String(TokenSymbol.colon.rawValue)
        case .function: return TokenKeyword.fn.rawValue
        case .let: return TokenKeyword.let.rawValue
        case .true: return TokenKeyword.true.rawValue
        case .false: return TokenKeyword.false.rawValue
        case .if: return TokenKeyword.if.rawValue
        case .else: return TokenKeyword.else.rawValue
        case .return: return TokenKeyword.return.rawValue
        case .unknown: return ""
        }
    }

    // Character -> TokenSymbol
    public init(symbol: Character) {
        guard let symbol = TokenSymbol(rawValue: symbol) else {
            self = .unknown
            return
        }

        switch symbol {
        case .equal: self = .assign
        case .plus: self = .plus
        case .minus: self = .minus
        case .bang: self = .bang
        case .asterisk: self = .asterisk
        case .slash: self = .slash
        case .comma: self = .comma
        case .semicolon: self = .semicolon
        case .colon: self = .colon
        case .lessThan: self = .lessThan
        case .greaterThan: self = .greaterThan
        case .leftParen: self = .leftParen
        case .rightParen: self = .rightParen
        case .leftBrace: self = .leftBrace
        case .rightBrace: self = .rightBrace
        case .leftBracket: self = .leftBracket
        case .rightBracket: self = .rightBracket
        }
    }

    // String -> Int
    public init(number: String) {
        let value = Int(number)
        assert(value != nil)
        self = .int(value: value ?? 0)
    }

    // String -> Identifier or TokenKeyword
    public init(word: String) {
        guard let keyword = TokenKeyword(rawValue: word) else {
            self = .identifier(name: word)
            return
        }

        switch keyword {
        case .fn: self = .function
        case .let: self = .let
        case .true: self = .true
        case .false: self = .false
        case .if: self = .if
        case .else: self = .else
        case .return: self = .return
        }
    }

    // String -> String
    public init(string: String) {
        self = .string(value: string)
    }
}
