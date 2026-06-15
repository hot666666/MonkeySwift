// MARK: - Constants
private let TRUE = Boolean(value: true)
private let FALSE = Boolean(value: false)
private let NULL = Null()

// MARK: - Evaluator
/// Evaluator는 AST를 받아서 Object를 만드는 역할을 합니다.
/// 방문은 Pre-order이고, 값의 평가는 재귀 호출이 모두 끝난 뒤 Post-order에 확정
public func eval(node: Node, environment: Environment) -> any Object {
    switch node {
    // Program
    case let program as Program:
        return evalProgram(program, environment: environment)

    // Statements
    case let stmt as ExpressionStatement:
        return eval(node: stmt.expression, environment: environment)

    case let stmt as LetStatement:
        let value = eval(node: stmt.value, environment: environment)
        if isError(value) {
            return value
        }
        environment.set(stmt.name.value, value)
        return value

    case let stmt as ReturnStatement:
        let value = eval(node: stmt.returnValue, environment: environment)
        if isError(value) {
            return value
        }
        return ReturnValue(value: value)

    case let stmt as BlockStatement:
        return evalBlockStatement(stmt, environment: environment)

    // Expressions
    case let expr as IntegerLiteral:
        return Integer(value: expr.value)

    case let expr as StringLiteral:
        return StringObject(value: expr.value)

    case let expr as BooleanLiteral:
        return nativeBoolToBooleanObject(expr.value)

    case let expr as PrefixExpression:
        let right = eval(node: expr.right, environment: environment)
        if isError(right) {
            return right
        }
        return evalPrefixExpression(operatorSymbol: expr.operatorSymbol, right: right)

    case let expr as InfixExpression:
        let left = eval(node: expr.left, environment: environment)
        if isError(left) {
            return left
        }
        let right = eval(node: expr.right, environment: environment)
        if isError(right) {
            return right
        }
        return evalInfixExpression(operatorSymbol: expr.operatorSymbol, left: left, right: right)

    case let expr as IfExpression:
        return evalIfExpression(expr, environment: environment)

    case let expr as Identifier:
        return evalIdentifier(expr, environment: environment)

    case let expr as FunctionLiteral:
        return Function(parameters: expr.parameters, body: expr.body, environment: environment)

    case let expr as CallExpression:
        let function = eval(node: expr.function, environment: environment)
        if isError(function) {
            return function
        }
        let args = evalExpressions(expr.arguments, environment: environment)
        if args.count == 1 && isError(args[0]) {
            return args[0]
        }
        return applyFunction(function, args: args)

    case let expr as ArrayLiteral:
        let elements = evalExpressions(expr.elements, environment: environment)
        if elements.count == 1 && isError(elements[0]) {
            return elements[0]
        }
        return ArrayObject(elements: elements)

    case let expr as IndexExpression:
        let left = eval(node: expr.left, environment: environment)
        if isError(left) {
            return left
        }
        let index = eval(node: expr.index, environment: environment)
        if isError(index) {
            return index
        }
        return evalIndexExpression(left: left, index: index)

    default:
        return NULL
    }
}

// MARK: - Program Evaluation
private func evalProgram(_ program: Program, environment: Environment) -> any Object {
    var result: any Object = NULL

    for statement in program.statements {
        result = eval(node: statement, environment: environment)

        if let returnValue = result as? ReturnValue {
            return returnValue.value
        }
        if let error = result as? ErrorObject {
            return error
        }
    }

    return result
}

// MARK: - Statement Evaluation
private func evalBlockStatement(_ block: BlockStatement, environment: Environment) -> any Object {
    var result: any Object = NULL

    for statement in block.statements {
        result = eval(node: statement, environment: environment)

        if result.type == .returnValue || result.type == .error {
            return result
        }
    }

    return result
}

// MARK: - Expression Evaluation
private func evalPrefixExpression(operatorSymbol: String, right: any Object) -> any Object {
    switch operatorSymbol {
    case "!":
        return evalBangOperatorExpression(right)
    case "-":
        return evalMinusPrefixOperatorExpression(right)
    default:
        return ErrorObject(message: "unknown operator: \(operatorSymbol)\(right.type.rawValue)")
    }
}

private func evalBangOperatorExpression(_ right: any Object) -> any Object {
    switch right {
    case is Boolean where (right as! Boolean).value == true:
        return FALSE
    case is Boolean where (right as! Boolean).value == false:
        return TRUE
    case is Null:
        return TRUE
    default:
        return FALSE
    }
}

private func evalMinusPrefixOperatorExpression(_ right: any Object) -> any Object {
    guard let integer = right as? Integer else {
        return ErrorObject(message: "unknown operator: -\(right.type.rawValue)")
    }
    return Integer(value: -integer.value)
}

private func evalInfixExpression(operatorSymbol: String, left: any Object, right: any Object)
    -> any Object
{
    if let leftInt = left as? Integer, let rightInt = right as? Integer {
        return evalIntegerInfixExpression(
            operatorSymbol: operatorSymbol, left: leftInt, right: rightInt)
    }

    if let leftBool = left as? Boolean, let rightBool = right as? Boolean {
        switch operatorSymbol {
        case "==":
            return nativeBoolToBooleanObject(leftBool.value == rightBool.value)
        case "!=":
            return nativeBoolToBooleanObject(leftBool.value != rightBool.value)
        default:
            return ErrorObject(
                message:
                    "unknown operator: \(left.type.rawValue) \(operatorSymbol) \(right.type.rawValue)"
            )
        }
    }

    if left.type != right.type {
        return ErrorObject(
            message: "type mismatch: \(left.type.rawValue) \(operatorSymbol) \(right.type.rawValue)"
        )
    }

    return ErrorObject(
        message: "unknown operator: \(left.type.rawValue) \(operatorSymbol) \(right.type.rawValue)")
}

private func evalIntegerInfixExpression(operatorSymbol: String, left: Integer, right: Integer)
    -> any Object
{
    switch operatorSymbol {
    case "+":
        return Integer(value: left.value + right.value)
    case "-":
        return Integer(value: left.value - right.value)
    case "*":
        return Integer(value: left.value * right.value)
    case "/":
        return Integer(value: left.value / right.value)
    case "<":
        return nativeBoolToBooleanObject(left.value < right.value)
    case ">":
        return nativeBoolToBooleanObject(left.value > right.value)
    case "==":
        return nativeBoolToBooleanObject(left.value == right.value)
    case "!=":
        return nativeBoolToBooleanObject(left.value != right.value)
    default:
        return ErrorObject(
            message:
                "unknown operator: \(left.type.rawValue) \(operatorSymbol) \(right.type.rawValue)")
    }
}

private func evalIfExpression(_ expr: IfExpression, environment: Environment) -> any Object {
    let condition = eval(node: expr.condition, environment: environment)
    if isError(condition) {
        return condition
    }

    if isTruthy(condition) {
        return eval(node: expr.consequence, environment: environment)
    } else if let alternative = expr.alternative {
        return eval(node: alternative, environment: environment)
    } else {
        return NULL
    }
}

private func evalIdentifier(_ node: Identifier, environment: Environment) -> any Object {
    if let value = environment.get(node.value) {
        return value
    }
    return ErrorObject(message: "identifier not found: \(node.value)")
}

private func evalIndexExpression(left: any Object, index: any Object) -> any Object {
    if left.type == .array && index.type == .integer {
        return evalArrayIndexExpression(array: left, index: index)
    }
    return ErrorObject(message: "index operator not supported: \(left.type.rawValue)")
}

private func evalArrayIndexExpression(array: any Object, index: any Object) -> any Object {
    guard let arrayObject = array as? ArrayObject else {
        return ErrorObject(message: "not an array: \(array.type.rawValue)")
    }
    guard let integerObject = index as? Integer else {
        return ErrorObject(message: "index is not integer: \(index.type.rawValue)")
    }

    let idx = integerObject.value
    let max = arrayObject.elements.count - 1

    if idx < 0 || idx > max {
        return NULL
    }

    return arrayObject.elements[idx]
}

// MARK: - Function Evaluation
private func evalExpressions(_ expressions: [any Expression], environment: Environment)
    -> [any Object]
{
    var result: [any Object] = []

    for expr in expressions {
        let evaluated = eval(node: expr, environment: environment)
        if isError(evaluated) {
            return [evaluated]
        }
        result.append(evaluated)
    }

    return result
}

private func applyFunction(_ function: any Object, args: [any Object]) -> any Object {
    guard let fn = function as? Function else {
        return ErrorObject(message: "not a function: \(function.type.rawValue)")
    }

    let extendedEnv = extendFunctionEnv(fn, args: args)
    let evaluated = eval(node: fn.body, environment: extendedEnv)
    return unwrapReturnValue(evaluated)
}

private func extendFunctionEnv(_ function: Function, args: [any Object]) -> Environment {
    let env = Environment(outer: function.environment)

    for (index, param) in function.parameters.enumerated() {
        env.set(param.value, args[index])
    }

    return env
}

private func unwrapReturnValue(_ obj: any Object) -> any Object {
    if let returnValue = obj as? ReturnValue {
        return returnValue.value
    }
    return obj
}

// MARK: - Helper Functions
private func nativeBoolToBooleanObject(_ value: Bool) -> Boolean {
    return value ? TRUE : FALSE
}

private func isTruthy(_ obj: any Object) -> Bool {
    switch obj {
    case is Null:
        return false
    case let boolean as Boolean:
        return boolean.value
    default:
        return true
    }
}

private func isError(_ obj: any Object) -> Bool {
    return obj.type == .error
}
