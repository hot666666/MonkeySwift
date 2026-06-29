import Foundation

// Run from the repository root:
// swiftc -O -whole-module-optimization \
//   Sources/MonkeySwift/Token/Token.swift \
//   Sources/MonkeySwift/Lexer/Lexer.swift \
//   Benchmarks/LexerBenchmark.swift \
//   -o .build/release/LexerBenchmark
// .build/release/LexerBenchmark

private protocol BenchmarkLexer {
    init(input: String)
    mutating func nextTokenType() -> TokenType
}

extension Lexer: BenchmarkLexer {}

private struct OffsetByLexer: BenchmarkLexer {
    private let input: String
    private var currentPosition = 0
    private var readPosition = 0
    private var character: Character?

    init(input: String) {
        self.input = input
        setNextCharacter()
    }

    mutating func nextTokenType() -> TokenType {
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
            return TokenType(string: readString())
        case let character? where isLetter(character):
            return TokenType(word: readWord())
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

    private mutating func readCharacter(while condition: (Character) -> Bool) -> String {
        let position = currentPosition

        while let character = self.character, condition(character) {
            setNextCharacter()
        }

        let startIndex = input.index(input.startIndex, offsetBy: position)
        let endIndex = input.index(startIndex, offsetBy: currentPosition - position)
        return String(input[startIndex..<endIndex])
    }

    private mutating func readString() -> String {
        setNextCharacter()
        defer { setNextCharacter() }

        let position = currentPosition

        while let character = self.character, character != "\"" {
            setNextCharacter()
        }

        let startIndex = input.index(input.startIndex, offsetBy: position)
        let endIndex = input.index(startIndex, offsetBy: currentPosition - position)
        return String(input[startIndex..<endIndex])
    }

    private mutating func readWord() -> String {
        readCharacter(while: isLetterOrDigit)
    }

    private mutating func readNumber() -> String {
        readCharacter(while: isDigit)
    }

    private func peekCharacter() -> Character? {
        guard readPosition < input.count else {
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

    private func isString(_ character: Character) -> Bool {
        character == "\""
    }

    private func isLetter(_ character: Character) -> Bool {
        ("a"..."z").contains(character) || ("A"..."Z").contains(character) || character == "_"
    }

    private func isDigit(_ character: Character) -> Bool {
        ("0"..."9").contains(character)
    }

    private func isLetterOrDigit(_ character: Character) -> Bool {
        isLetter(character) || isDigit(character)
    }
}

private struct RunResult: Equatable {
    let tokenCount: Int
    let checksum: UInt64
}

private struct BenchmarkMetrics {
    let averageNanoseconds: Double
    let repetitions: Int
    let result: RunResult
}

// Keep token values observable so optimized builds cannot discard lexer work.
private var blackHole: UInt64 = 0

@main
private enum LexerBenchmark {
    static func main() {
        let cases = makeBenchmarkCases()
        print("Lexer benchmark, swiftc -O -whole-module-optimization")
        print("Input is generated Monkey-like ASCII source. Times are average milliseconds per full tokenization.")
        print("")
        print("| Input chars | Tokens | OffsetBy baseline | String.Index Lexer | Index speedup |")
        print("| ----------: | -----: | ---------------: | -----------: | ------------: |")

        for benchmarkCase in cases {
            let offsetBy = benchmark(OffsetByLexer.self, input: benchmarkCase.input, expected: nil)
            let index = benchmark(Lexer.self, input: benchmarkCase.input, expected: offsetBy.result)

            let offsetByMs = offsetBy.averageNanoseconds / 1_000_000
            let indexMs = index.averageNanoseconds / 1_000_000
            let indexSpeedup = offsetBy.averageNanoseconds / index.averageNanoseconds

            print(
                "| \(benchmarkCase.inputCount) | \(offsetBy.result.tokenCount) | "
                    + "\(format(offsetByMs)) ms (\(offsetBy.repetitions)x) | "
                    + "\(format(indexMs)) ms (\(index.repetitions)x) | "
                    + "\(format(indexSpeedup))x |"
            )
        }

        print("")
        print("checksum sink: \(blackHole)")
    }

    private struct BenchmarkCase {
        let inputCount: Int
        let input: String
    }

    private static func makeBenchmarkCases() -> [BenchmarkCase] {
        [16 * 1024, 64 * 1024, 128 * 1024].map { targetSize in
            let input = makeInput(minimumInputCount: targetSize)
            return BenchmarkCase(inputCount: input.count, input: input)
        }
    }

    private static func makeInput(minimumInputCount: Int) -> String {
        var input = ""
        var index = 0

        while input.count < minimumInputCount {
            input += """
            let value\(index) = \(index % 997);
            let text\(index) = "monkey lexer benchmark string \(index) with spaces";
            let add\(index) = fn(x, y) { x + y; };
            if (value\(index) < 1000) {
                return add\(index)(value\(index), 1);
            } else {
                return 0;
            }
            [1, 2, 3, value\(index)];
            {"one": 1, "two": 2, "value": value\(index)};
            !-/*5;
            10 == 10;
            10 != 9;

            """
            index += 1
        }

        return input
    }

    private static func benchmark<L: BenchmarkLexer>(
        _ lexerType: L.Type,
        input: String,
        expected: RunResult?
    ) -> BenchmarkMetrics {
        let warmupStart = DispatchTime.now().uptimeNanoseconds
        let warmupResult = tokenize(lexerType, input: input)
        let warmupNanoseconds = DispatchTime.now().uptimeNanoseconds - warmupStart

        if let expected, warmupResult != expected {
            fatalError("Mismatched lexer result for \(lexerType): \(warmupResult) != \(expected)")
        }

        if warmupNanoseconds > 750_000_000 {
            blackHole &+= warmupResult.checksum
            return BenchmarkMetrics(
                averageNanoseconds: Double(warmupNanoseconds),
                repetitions: 1,
                result: warmupResult
            )
        }

        let targetNanoseconds: UInt64 = 300_000_000
        let repetitions = max(3, min(5_000, Int(targetNanoseconds / max(warmupNanoseconds, 1))))

        let start = DispatchTime.now().uptimeNanoseconds
        var result = warmupResult

        for _ in 0..<repetitions {
            result = tokenize(lexerType, input: input)
        }

        let elapsed = DispatchTime.now().uptimeNanoseconds - start

        if result != warmupResult {
            fatalError("Unstable lexer result for \(lexerType): \(result) != \(warmupResult)")
        }

        blackHole &+= result.checksum
        return BenchmarkMetrics(
            averageNanoseconds: Double(elapsed) / Double(repetitions),
            repetitions: repetitions,
            result: result
        )
    }

    @inline(never)
    private static func tokenize<L: BenchmarkLexer>(_ lexerType: L.Type, input: String) -> RunResult {
        var lexer = lexerType.init(input: input)
        var checksum: UInt64 = 0xcbf2_9ce4_8422_2325
        var tokenCount = 0

        while true {
            let token = lexer.nextTokenType()
            tokenCount += 1
            mix(token, into: &checksum)

            if token == .eof {
                break
            }
        }

        blackHole &+= checksum &+ UInt64(tokenCount)
        return RunResult(tokenCount: tokenCount, checksum: checksum)
    }

    private static func mix(_ token: TokenType, into checksum: inout UInt64) {
        switch token {
        case .unknown:
            mix(0, into: &checksum)
        case .illegal:
            mix(1, into: &checksum)
        case .eof:
            mix(2, into: &checksum)
        case .identifier(let name):
            mix(3, into: &checksum)
            mix(name, into: &checksum)
        case .int(let value):
            mix(4, into: &checksum)
            mix(UInt64(value), into: &checksum)
        case .string(let value):
            mix(5, into: &checksum)
            mix(value, into: &checksum)
        case .assign:
            mix(6, into: &checksum)
        case .plus:
            mix(7, into: &checksum)
        case .minus:
            mix(8, into: &checksum)
        case .bang:
            mix(9, into: &checksum)
        case .asterisk:
            mix(10, into: &checksum)
        case .slash:
            mix(11, into: &checksum)
        case .lessThan:
            mix(12, into: &checksum)
        case .greaterThan:
            mix(13, into: &checksum)
        case .equal:
            mix(14, into: &checksum)
        case .notEqual:
            mix(15, into: &checksum)
        case .leftParen:
            mix(16, into: &checksum)
        case .rightParen:
            mix(17, into: &checksum)
        case .leftBrace:
            mix(18, into: &checksum)
        case .rightBrace:
            mix(19, into: &checksum)
        case .leftBracket:
            mix(20, into: &checksum)
        case .rightBracket:
            mix(21, into: &checksum)
        case .colon:
            mix(22, into: &checksum)
        case .comma:
            mix(23, into: &checksum)
        case .semicolon:
            mix(24, into: &checksum)
        case .function:
            mix(25, into: &checksum)
        case .let:
            mix(26, into: &checksum)
        case .true:
            mix(27, into: &checksum)
        case .false:
            mix(28, into: &checksum)
        case .if:
            mix(29, into: &checksum)
        case .else:
            mix(30, into: &checksum)
        case .return:
            mix(31, into: &checksum)
        }
    }

    private static func mix(_ value: String, into checksum: inout UInt64) {
        for scalar in value.unicodeScalars {
            mix(UInt64(scalar.value), into: &checksum)
        }
    }

    private static func mix(_ value: UInt64, into checksum: inout UInt64) {
        checksum ^= value &+ 0x9e37_79b9_7f4a_7c15
        checksum = checksum &* 0xbf58_476d_1ce4_e5b9
        checksum ^= checksum >> 27
    }

    private static func format(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.1f", value)
        }

        if value >= 10 {
            return String(format: "%.2f", value)
        }

        return String(format: "%.3f", value)
    }
}
