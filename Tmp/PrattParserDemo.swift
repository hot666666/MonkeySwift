/*
 Pratt Parsing(Top-Down Operator Precedence Parsing)은
 복잡한 문법 규칙(EBNF) 대신, **우선순위(Precedence)**를 기반으로
 **Prefix(전위)**와 **Infix(중위)** 파싱 함수를 재귀적으로 호출하여 구조를 만드는 방식

 핵심 로직:
 1. 현재 토큰에 맞는 **Prefix 함수**를 호출하여 식의 '좌측(Left)'을 생성
 2. 뒤따라오는 연산자(토큰)의 **우선순위**가 현재보다 높다면,
    **Infix 함수**를 호출하여 식을 결합 -> leftExp = infixExp
 3. 우선순위가 낮거나 같은 연산자를 만나면 확장을 멈추고 반환
 */

import Foundation

enum Demo {

    // MARK: - Token

    struct Token {
        let type: TokenType
        let literal: String

        enum TokenType {
            case integer
            case plus, minus, mult, div
            case eof
        }
    }

    // MARK: - Precedence

    enum Precedence: Int, Comparable {
        /// 우선순위 정의 (높을수록 힘이 쎔 = 먼저 묶임)
        case lowest = 0
        case sum = 1  // +, -
        case product = 2  // *, /
        case prefix = 3  // -N

        static func < (lhs: Precedence, rhs: Precedence) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - AST Nodes

    protocol Node: CustomStringConvertible {}

    struct IntegerLiteral: Node {
        let value: Int
        var description: String { "\(value)" }
    }

    struct PrefixExpression: Node {
        let op: String
        let right: any Node
        var description: String { "(\(op)\(right))" }
    }

    struct InfixExpression: Node {
        let left: any Node
        let op: String
        let right: any Node
        var description: String { "(\(left) \(op) \(right))" }
    }

    // MARK: - Parser

    class Parser {
        var tokens: [Token]
        var position = 0

        init(tokens: [Token]) {
            self.tokens = tokens
        }

        var currentToken: Token {
            guard position < tokens.count else {
                return Token(type: .eof, literal: "")
            }
            return tokens[position]
        }

        var peekToken: Token {
            guard position + 1 < tokens.count else {
                return Token(type: .eof, literal: "")
            }
            return tokens[position + 1]
        }

        func nextToken() {
            position += 1
        }

        // MARK: - Parse Expression

        func parseExpression(_ precedence: Precedence) -> (any Node)? {
            print("➡️ 진입: parseExpression(우선순위: \(precedence)) | 현재토큰: \(currentToken.literal)")
            guard var leftExp = parsePrefix() else { return nil }

            print("⚙️ Prefix 완성: \(leftExp.description)")
            while peekToken.type != .eof && precedence < getPrecedence(peekToken) {
                guard isInfixToken(peekToken) else {
                    return leftExp
                }

                nextToken()

                guard let infixExp = parseInfix(left: leftExp) else {
                    return leftExp
                }

                leftExp = infixExp
            }

            print("⬅️ 반환: \(leftExp.description)")
            return leftExp
        }

        func parsePrefix() -> (any Node)? {
            let token = currentToken

            switch token.type {
            case .integer:
                return IntegerLiteral(value: Int(token.literal)!)

            case .minus:
                let prefixOp = token.literal
                nextToken()
                guard let right = parseExpression(.prefix) else { return nil }
                return PrefixExpression(op: prefixOp, right: right)

            default:
                return nil
            }
        }

        func parseInfix(left: any Node) -> (any Node)? {
            let precedence = getPrecedence(currentToken)
            let infixOp = currentToken.literal

            nextToken()

            guard let right = parseExpression(precedence) else { return nil }
            return InfixExpression(left: left, op: infixOp, right: right)
        }

        // MARK: - Helper

        func getPrecedence(_ token: Token) -> Precedence {
            switch token.type {
            case .plus, .minus: return .sum
            case .mult, .div: return .product
            default: return .lowest
            }
        }

        func isInfixToken(_ token: Token) -> Bool {
            switch token.type {
            case .plus, .minus, .mult, .div: return true
            default: return false
            }
        }
    }

    // MARK: - Test Runner

    static func runTest(_ description: String, tokens: [Token], expected: String) {
        print("\n---------------------------------------------------")
        print("✅ 테스트: \(description)")
        let parser = Parser(tokens: tokens)

        if let ast = parser.parseExpression(.lowest) {
            let result = "\(ast)"
            print("   결과 AST: \(result)")

            if result == expected {
                print("🎉 성공! (Expected matches Result)")
            } else {
                print("❌ 실패! (Expected: \(expected), Got: \(result))")
                exit(1)
            }
        } else {
            print("❌ 파싱 실패 (AST 생성 불가)")
            exit(1)
        }
    }

    // MARK: - Main Entry Point

    static func main() {
        runTest(
            "-5 + 10 * 2",
            tokens: [
                Token(type: .minus, literal: "-"),
                Token(type: .integer, literal: "5"),
                Token(type: .plus, literal: "+"),
                Token(type: .integer, literal: "10"),
                Token(type: .mult, literal: "*"),
                Token(type: .integer, literal: "2"),
                Token(type: .eof, literal: ""),
            ], expected: "((-5) + (10 * 2))")

        runTest(
            "10 - 5 - 2",
            tokens: [
                Token(type: .integer, literal: "10"),
                Token(type: .minus, literal: "-"),
                Token(type: .integer, literal: "5"),
                Token(type: .minus, literal: "-"),
                Token(type: .integer, literal: "2"),
                Token(type: .eof, literal: ""),
            ], expected: "((10 - 5) - 2)")

        runTest(
            "-10 + 20 / 2",
            tokens: [
                Token(type: .minus, literal: "-"),
                Token(type: .integer, literal: "10"),
                Token(type: .plus, literal: "+"),
                Token(type: .integer, literal: "20"),
                Token(type: .div, literal: "/"),
                Token(type: .integer, literal: "2"),
                Token(type: .eof, literal: ""),
            ], expected: "((-10) + (20 / 2))")
    }
}

// 실행
Demo.main()
