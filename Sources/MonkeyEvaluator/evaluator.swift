import MonkeyCore

// MARK: - Evaluator

public func eval(node: any Node, env: Environment) -> any Object {
    switch node {
    // Program
    case let program as Program:
        return evalProgram(program, env: env)

    // Statements
    case let stmt as ExpressionStatement:
        return eval(node: stmt.expression, env: env)

    case let stmt as BlockStatement:
        return evalBlockStatement(stmt, env: env)

    case let stmt as ReturnStatement:
        let val = eval(node: stmt.returnValue, env: env)
        if isError(val) {
            return val
        }
        return ReturnValueObject(value: val)

    case let stmt as LetStatement:
        let val = eval(node: stmt.value, env: env)
        if isError(val) {
            return val
        }
        return env.set(stmt.name.value, val)

    // Expressions
    case let expr as IntegerLiteral:
        return IntegerObject(value: expr.value)

    case let expr as BooleanLiteral:
        return nativeBoolToBooleanObject(expr.value)

    case let expr as PrefixExpression:
        let right = eval(node: expr.right, env: env)
        if isError(right) {
            return right
        }
        return evalPrefixExpression(operator_: expr.operator_, right: right)

    case let expr as InfixExpression:
        let left = eval(node: expr.left, env: env)
        if isError(left) {
            return left
        }

        let right = eval(node: expr.right, env: env)
        if isError(right) {
            return right
        }

        return evalInfixExpression(operator_: expr.operator_, left: left, right: right)

    case let expr as IfExpression:
        return evalIfExpression(expr, env: env)

    case let expr as Identifier:
        return evalIdentifier(expr, env: env)

    case let expr as FunctionLiteral:
        return FunctionObject(parameters: expr.parameters, body: expr.body, env: env)

    case let expr as CallExpression:
        let function = eval(node: expr.function, env: env)
        if isError(function) {
            return function
        }

        let args = evalExpressions(expr.arguments, env: env)
        if args.count == 1 && isError(args[0]) {
            return args[0]
        }

        return applyFunction(function, args: args)

    default:
        return NULL
    }
}

func evalProgram(_ program: Program, env: Environment) -> any Object {
    var result: Object = NULL

    for statement in program.statements {
        result = eval(node: statement, env: env)

        if let returnValue = result as? ReturnValueObject {
            return returnValue.value
        }

        if result is ErrorObject {
            return result
        }
    }

    return result
}

func evalBlockStatement(_ block: BlockStatement, env: Environment) -> any Object {
    var result: Object = NULL

    for statement in block.statements {
        result = eval(node: statement, env: env)

        if result.type() == .returnValue || result.type() == .error {
            return result
        }
    }

    return result
}

func evalPrefixExpression(operator_: String, right: any Object) -> any Object {
    switch operator_ {
    case "!":
        return evalBangOperatorExpression(right)
    case "-":
        return evalMinusPrefixOperatorExpression(right)
    default:
        return ErrorObject(message: "unknown operator: \(operator_)\(right.type().rawValue)")
    }
}

func evalBangOperatorExpression(_ right: any Object) -> any Object {
    switch right {
    case is BooleanObject where (right as! BooleanObject).value == true:
        return FALSE
    case is BooleanObject where (right as! BooleanObject).value == false:
        return TRUE
    case is NullObject:
        return TRUE
    default:
        return FALSE
    }
}

func evalMinusPrefixOperatorExpression(_ right: any Object) -> any Object {
    guard right.type() == .integer else {
        return ErrorObject(message: "unknown operator: -\(right.type().rawValue)")
    }

    let value = (right as! IntegerObject).value
    return IntegerObject(value: -value)
}

func evalInfixExpression(operator_: String, left: Object, right: any Object) -> any Object {
    if left.type() == .integer && right.type() == .integer {
        return evalIntegerInfixExpression(operator_: operator_, left: left, right: right)
    }

    if operator_ == "==" {
        return nativeBoolToBooleanObject(objectsEqual(left, right))
    }

    if operator_ == "!=" {
        return nativeBoolToBooleanObject(!objectsEqual(left, right))
    }

    if left.type() != right.type() {
        return ErrorObject(message: "type mismatch: \(left.type().rawValue) \(operator_) \(right.type().rawValue)")
    }

    return ErrorObject(message: "unknown operator: \(left.type().rawValue) \(operator_) \(right.type().rawValue)")
}

func evalIntegerInfixExpression(operator_: String, left: Object, right: any Object) -> any Object {
    let leftVal = (left as! IntegerObject).value
    let rightVal = (right as! IntegerObject).value

    switch operator_ {
    case "+":
        return IntegerObject(value: leftVal + rightVal)
    case "-":
        return IntegerObject(value: leftVal - rightVal)
    case "*":
        return IntegerObject(value: leftVal * rightVal)
    case "/":
        return IntegerObject(value: leftVal / rightVal)
    case "<":
        return nativeBoolToBooleanObject(leftVal < rightVal)
    case ">":
        return nativeBoolToBooleanObject(leftVal > rightVal)
    case "==":
        return nativeBoolToBooleanObject(leftVal == rightVal)
    case "!=":
        return nativeBoolToBooleanObject(leftVal != rightVal)
    default:
        return ErrorObject(message: "unknown operator: \(left.type().rawValue) \(operator_) \(right.type().rawValue)")
    }
}

func evalIfExpression(_ expr: IfExpression, env: Environment) -> any Object {
    let condition = eval(node: expr.condition, env: env)

    if isError(condition) {
        return condition
    }

    if isTruthy(condition) {
        return eval(node: expr.consequence, env: env)
    } else if let alternative = expr.alternative {
        return eval(node: alternative, env: env)
    } else {
        return NULL
    }
}

func evalIdentifier(_ node: Identifier, env: Environment) -> any Object {
    if let val = env.get(node.value) {
        return val
    }

    return ErrorObject(message: "identifier not found: \(node.value)")
}

func evalExpressions(_ exps: [any Expression], env: Environment) -> [any Object] {
    var result: [any Object] = []

    for exp in exps {
        let evaluated = eval(node: exp, env: env)
        if isError(evaluated) {
            return [evaluated]
        }
        result.append(evaluated)
    }

    return result
}

func applyFunction(_ fn: any Object, args: [any Object]) -> any Object {
    guard let function = fn as? FunctionObject else {
        return ErrorObject(message: "not a function: \(fn.type().rawValue)")
    }

    let extendedEnv = extendFunctionEnv(function, args: args)
    let evaluated = eval(node: function.body, env: extendedEnv)
    return unwrapReturnValue(evaluated)
}

func extendFunctionEnv(_ fn: FunctionObject, args: [any Object]) -> Environment {
    let env = Environment(outer: fn.env)

    for (paramIdx, param) in fn.parameters.enumerated() {
        env.set(param.value, args[paramIdx])
    }

    return env
}

func unwrapReturnValue(_ obj: any Object) -> any Object {
    if let returnValue = obj as? ReturnValueObject {
        return returnValue.value
    }
    return obj
}

// MARK: - Helper Functions

func isTruthy(_ obj: any Object) -> Bool {
    switch obj {
    case is NullObject:
        return false
    case let bool as BooleanObject:
        return bool.value
    default:
        return true
    }
}

func nativeBoolToBooleanObject(_ input: Bool) -> BooleanObject {
    return input ? TRUE : FALSE
}

func isError(_ obj: any Object) -> Bool {
    return obj.type() == .error
}

func objectsEqual(_ left: any Object, _ right: any Object) -> Bool {
    if let leftInt = left as? IntegerObject, let rightInt = right as? IntegerObject {
        return leftInt.value == rightInt.value
    }

    if let leftBool = left as? BooleanObject, let rightBool = right as? BooleanObject {
        return leftBool.value == rightBool.value
    }

    if left is NullObject && right is NullObject {
        return true
    }

    return false
}
