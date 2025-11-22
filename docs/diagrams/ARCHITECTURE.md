# MonkeySwift Architecture

## Module Dependency Graph

```mermaid
graph TB
    A[MonkeySwift REPL] --> B[MonkeyLexer]
    A --> C[MonkeyParser]
    A --> D[MonkeyEvaluator]
    A --> E[MonkeyCore]

    B --> E
    C --> E
    C --> B
    D --> E

    E --> F[Token]
    E --> G[AST]
    E --> H[Object]
    E --> I[Environment]

    style A fill:#f9f,stroke:#333,stroke-width:4px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
    style C fill:#bfb,stroke:#333,stroke-width:2px
    style D fill:#bfb,stroke:#333,stroke-width:2px
```

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant REPL
    participant Lexer
    participant Parser
    participant Evaluator
    participant Environment

    User->>REPL: Input: "let x = 5;"
    REPL->>Lexer: Tokenize
    Lexer->>REPL: [LET, IDENT(x), ASSIGN, INT(5), SEMICOLON]
    REPL->>Parser: Parse tokens
    Parser->>REPL: AST (LetStatement)
    REPL->>Evaluator: Evaluate AST
    Evaluator->>Environment: Set("x", IntegerObject(5))
    Environment->>Evaluator: IntegerObject(5)
    Evaluator->>REPL: IntegerObject(5)
    REPL->>User: "5"
```

## Evaluation Flow

```mermaid
flowchart TD
    Start([Start: eval node]) --> Type{Node Type?}

    Type -->|Program| Program[evalProgram]
    Type -->|LetStatement| Let[Store in Environment]
    Type -->|ReturnStatement| Return[Wrap in ReturnValue]
    Type -->|ExpressionStatement| Expr[Evaluate Expression]

    Expr --> ExprType{Expression Type?}
    ExprType -->|Integer| Int[IntegerObject]
    ExprType -->|Boolean| Bool[BooleanObject]
    ExprType -->|Identifier| Ident[Lookup in Environment]
    ExprType -->|Prefix| Prefix[evalPrefixExpression]
    ExprType -->|Infix| Infix[evalInfixExpression]
    ExprType -->|If| If[evalIfExpression]
    ExprType -->|Function| Fn[FunctionObject]
    ExprType -->|Call| Call[applyFunction]

    Program --> Result([Return Object])
    Let --> Result
    Return --> Result
    Int --> Result
    Bool --> Result
    Ident --> Result
    Prefix --> Result
    Infix --> Result
    If --> Result
    Fn --> Result
    Call --> Result

    style Start fill:#bfb
    style Result fill:#bfb
    style Type fill:#fbb
    style ExprType fill:#fbb
```

## Parser State Machine

```mermaid
stateDiagram-v2
    [*] --> ParseProgram
    ParseProgram --> ParseStatement

    ParseStatement --> LetStatement: let
    ParseStatement --> ReturnStatement: return
    ParseStatement --> ExpressionStatement: other

    LetStatement --> ParseIdentifier
    ParseIdentifier --> ParseExpression
    ParseExpression --> [*]

    ReturnStatement --> ParseExpression
    ParseExpression --> [*]

    ExpressionStatement --> ParseExpression
    ParseExpression --> PrefixParsing: prefix token
    ParseExpression --> InfixParsing: infix token

    PrefixParsing --> Identifier: identifier
    PrefixParsing --> Integer: integer
    PrefixParsing --> Boolean: boolean
    PrefixParsing --> PrefixOperator: !, -
    PrefixParsing --> GroupedExpr: (
    PrefixParsing --> IfExpr: if
    PrefixParsing --> FunctionLiteral: fn

    InfixParsing --> InfixOperator: +, -, *, /, <, >, ==, !=
    InfixParsing --> CallExpr: (

    Identifier --> [*]
    Integer --> [*]
    Boolean --> [*]
    PrefixOperator --> [*]
    GroupedExpr --> [*]
    IfExpr --> [*]
    FunctionLiteral --> [*]
    InfixOperator --> [*]
    CallExpr --> [*]
```

## Object Type Hierarchy

```mermaid
classDiagram
    class Object {
        <<protocol>>
        +type() ObjectType
        +inspect() String
    }

    class IntegerObject {
        +value: Int
        +type() ObjectType
        +inspect() String
    }

    class BooleanObject {
        +value: Bool
        +type() ObjectType
        +inspect() String
    }

    class NullObject {
        +type() ObjectType
        +inspect() String
    }

    class ReturnValueObject {
        +value: Object
        +type() ObjectType
        +inspect() String
    }

    class ErrorObject {
        +message: String
        +type() ObjectType
        +inspect() String
    }

    class FunctionObject {
        +parameters: [Identifier]
        +body: BlockStatement
        +env: Environment
        +type() ObjectType
        +inspect() String
    }

    Object <|-- IntegerObject
    Object <|-- BooleanObject
    Object <|-- NullObject
    Object <|-- ReturnValueObject
    Object <|-- ErrorObject
    Object <|-- FunctionObject

    ReturnValueObject --> Object: wraps
    FunctionObject --> Environment: uses
```

## AST Node Hierarchy

```mermaid
classDiagram
    class Node {
        <<protocol>>
        +tokenLiteral() String
        +string() String
    }

    class Statement {
        <<protocol>>
        +statementNode()
    }

    class Expression {
        <<protocol>>
        +expressionNode()
    }

    Node <|-- Statement
    Node <|-- Expression

    class Program {
        +statements: [Statement]
    }

    class LetStatement {
        +token: TokenType
        +name: Identifier
        +value: Expression
    }

    class ReturnStatement {
        +token: TokenType
        +returnValue: Expression
    }

    class ExpressionStatement {
        +token: TokenType
        +expression: Expression
    }

    class BlockStatement {
        +token: TokenType
        +statements: [Statement]
    }

    Statement <|-- LetStatement
    Statement <|-- ReturnStatement
    Statement <|-- ExpressionStatement
    Statement <|-- BlockStatement

    class Identifier {
        +token: TokenType
        +value: String
    }

    class IntegerLiteral {
        +token: TokenType
        +value: Int
    }

    class BooleanLiteral {
        +token: TokenType
        +value: Bool
    }

    class PrefixExpression {
        +token: TokenType
        +operator: String
        +right: Expression
    }

    class InfixExpression {
        +token: TokenType
        +left: Expression
        +operator: String
        +right: Expression
    }

    class IfExpression {
        +token: TokenType
        +condition: Expression
        +consequence: BlockStatement
        +alternative: BlockStatement?
    }

    class FunctionLiteral {
        +token: TokenType
        +parameters: [Identifier]
        +body: BlockStatement
    }

    class CallExpression {
        +token: TokenType
        +function: Expression
        +arguments: [Expression]
    }

    Expression <|-- Identifier
    Expression <|-- IntegerLiteral
    Expression <|-- BooleanLiteral
    Expression <|-- PrefixExpression
    Expression <|-- InfixExpression
    Expression <|-- IfExpression
    Expression <|-- FunctionLiteral
    Expression <|-- CallExpression

    Node <|-- Program
    Program --> Statement: contains
    LetStatement --> Expression: has value
    ReturnStatement --> Expression: has returnValue
    ExpressionStatement --> Expression: has expression
    PrefixExpression --> Expression: has right
    InfixExpression --> Expression: has left and right
    IfExpression --> BlockStatement: has consequence and alternative
    FunctionLiteral --> BlockStatement: has body
    CallExpression --> Expression: has function and arguments
```

## Token Flow Through Lexer

```mermaid
flowchart LR
    Input["Input: 'let x = 5;'"] --> Lexer[Lexer]
    Lexer --> T1[LET]
    Lexer --> T2["IDENT(x)"]
    Lexer --> T3[ASSIGN]
    Lexer --> T4["INT(5)"]
    Lexer --> T5[SEMICOLON]
    Lexer --> T6[EOF]

    T1 --> Parser[Parser]
    T2 --> Parser
    T3 --> Parser
    T4 --> Parser
    T5 --> Parser
    T6 --> Parser

    style Input fill:#bfb
    style Lexer fill:#bbf
    style Parser fill:#fbb
```

## Environment Scoping

```mermaid
graph TD
    Global[Global Environment<br/>x = 10<br/>y = 20]

    Global --> Fn1[Function Call 1<br/>a = 5<br/>outer = Global]
    Global --> Fn2[Function Call 2<br/>b = 15<br/>outer = Global]

    Fn1 --> Closure1[Closure<br/>c = 3<br/>outer = Fn1]
    Fn2 --> Closure2[Closure<br/>d = 25<br/>outer = Fn2]

    style Global fill:#bbf
    style Fn1 fill:#bfb
    style Fn2 fill:#bfb
    style Closure1 fill:#fbb
    style Closure2 fill:#fbb
```
