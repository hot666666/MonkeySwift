// The Swift Programming Language
// https://docs.swift.org/swift-book

import MonkeyCore
import MonkeyLexer
import MonkeyParser
import MonkeyEvaluator

print("Hello! This is the MonkeySwift REPL! 🐒")
print("Feel free to type in commands")

let env = Environment()

while true {
    print(">> ", terminator: "")

    guard let input = readLine(), !input.isEmpty else {
        continue
    }

    if input == "exit" || input == "quit" {
        print("Goodbye! 🐒")
        break
    }

    Repl.start(with: input, env: env)
}
