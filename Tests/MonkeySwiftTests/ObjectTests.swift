import Testing

@testable import MonkeySwift

@Suite("ObjectTests")
struct MonkeySwiftObject {
    @Test func testIntegerObject() {
        let int = Integer(value: 5)

        #expect(int.type == .integer)
        #expect(int.value == 5)
        #expect(int.inspect() == "5")
    }

    @Test func testBooleanObject() {
        let trueObj = Boolean(value: true)
        let falseObj = Boolean(value: false)

        #expect(trueObj.type == .boolean)
        #expect(trueObj.value == true)
        #expect(trueObj.inspect() == "true")

        #expect(falseObj.type == .boolean)
        #expect(falseObj.value == false)
        #expect(falseObj.inspect() == "false")
    }

    @Test func testNullObject() {
        let null = Null()

        #expect(null.type == .null)
        #expect(null.inspect() == "null")
    }

    @Test func testReturnValueObject() {
        let returnValue = ReturnValue(value: Integer(value: 10))

        #expect(returnValue.type == .returnValue)
        #expect(returnValue.inspect() == "10")

        guard let intValue = returnValue.value as? Integer else {
            Issue.record("Return value is not Integer")
            return
        }
        #expect(intValue.value == 10)
    }

    @Test func testErrorObject() {
        let error = ErrorObject(message: "division by zero")

        #expect(error.type == .error)
        #expect(error.message == "division by zero")
        #expect(error.inspect() == "ERROR: division by zero")
    }

    @Test func testFunctionObject() {
        let param1Token = TokenType.identifier(name: "x")
        let param1 = Identifier(token: param1Token, value: "x")

        let param2Token = TokenType.identifier(name: "y")
        let param2 = Identifier(token: param2Token, value: "y")

        let bodyToken = TokenType.leftBrace
        let bodyStmtToken = TokenType.identifier(name: "x")
        let bodyStmt = ExpressionStatement(
            token: bodyStmtToken,
            expression: Identifier(token: bodyStmtToken, value: "x")
        )
        let body = BlockStatement(token: bodyToken, statements: [bodyStmt])

        let env = Environment()
        let function = Function(parameters: [param1, param2], body: body, environment: env)

        #expect(function.type == .function)
        #expect(function.parameters.count == 2)
        #expect(function.parameters[0].value == "x")
        #expect(function.parameters[1].value == "y")
        #expect(function.inspect().contains("fn(x, y)"))
    }

    @Test func testEnvironmentGetSet() {
        let env = Environment()

        env.set("x", Integer(value: 5))
        env.set("y", Boolean(value: true))

        guard let x = env.get("x") as? Integer else {
            Issue.record("Failed to get x from environment")
            return
        }
        #expect(x.value == 5)

        guard let y = env.get("y") as? Boolean else {
            Issue.record("Failed to get y from environment")
            return
        }
        #expect(y.value == true)

        let z = env.get("z")
        #expect(z == nil)
    }

    @Test func testEnvironmentOuterScope() {
        let outer = Environment()
        outer.set("x", Integer(value: 10))
        outer.set("y", Integer(value: 20))

        let inner = Environment(outer: outer)
        inner.set("x", Integer(value: 5))  // 내부 스코프에서 x 재정의

        // 내부 스코프에서 x 조회 (내부 값)
        guard let x = inner.get("x") as? Integer else {
            Issue.record("Failed to get x from inner environment")
            return
        }
        #expect(x.value == 5)

        // 내부 스코프에서 y 조회 (외부 값)
        guard let y = inner.get("y") as? Integer else {
            Issue.record("Failed to get y from inner environment")
            return
        }
        #expect(y.value == 20)

        // 외부 스코프에서 x 조회 (외부 값 유지)
        guard let outerX = outer.get("x") as? Integer else {
            Issue.record("Failed to get x from outer environment")
            return
        }
        #expect(outerX.value == 10)
    }

    @Test func testEnvironmentNestedScopes() {
        let global = Environment()
        global.set("a", Integer(value: 1))

        let first = Environment(outer: global)
        first.set("b", Integer(value: 2))

        let second = Environment(outer: first)
        second.set("c", Integer(value: 3))

        // second 스코프에서 모든 변수 접근 가능
        guard let a = second.get("a") as? Integer else {
            Issue.record("Failed to get a from second scope")
            return
        }
        #expect(a.value == 1)

        guard let b = second.get("b") as? Integer else {
            Issue.record("Failed to get b from second scope")
            return
        }
        #expect(b.value == 2)

        guard let c = second.get("c") as? Integer else {
            Issue.record("Failed to get c from second scope")
            return
        }
        #expect(c.value == 3)

        // first 스코프에서는 c 접근 불가
        let cFromFirst = first.get("c")
        #expect(cFromFirst == nil)

        // global 스코프에서는 b, c 접근 불가
        let bFromGlobal = global.get("b")
        let cFromGlobal = global.get("c")
        #expect(bFromGlobal == nil)
        #expect(cFromGlobal == nil)
    }

    @Test func testObjectTypeString() {
        #expect(ObjectType.integer.rawValue == "INTEGER")
        #expect(ObjectType.boolean.rawValue == "BOOLEAN")
        #expect(ObjectType.null.rawValue == "NULL")
        #expect(ObjectType.returnValue.rawValue == "RETURN_VALUE")
        #expect(ObjectType.error.rawValue == "ERROR")
        #expect(ObjectType.function.rawValue == "FUNCTION")
        #expect(ObjectType.hashMap.rawValue == "HASHMAP")
    }

    @Test func testStringHashKey() {
        let name1 = StringObject(value: "Hello World")
        let name2 = StringObject(value: "Hello World")
        let diff = StringObject(value: "My name is monkey")

        #expect(name1.hashKey() == name2.hashKey())
        #expect(name1.hashKey() != diff.hashKey())
    }

    @Test func testIntegerHashKey() {
        let int1 = Integer(value: 5)
        let int2 = Integer(value: 5)
        let diff = Integer(value: 10)

        #expect(int1.hashKey() == int2.hashKey())
        #expect(int1.hashKey() != diff.hashKey())
    }

    @Test func testBooleanHashKey() {
        let bool1 = Boolean(value: true)
        let bool2 = Boolean(value: true)
        let diff = Boolean(value: false)

        #expect(bool1.hashKey() == bool2.hashKey())
        #expect(bool1.hashKey() != diff.hashKey())
    }

    @Test func testHashObject() {
        let key = StringObject(value: "name")
        let value = StringObject(value: "monkey")

        let hashPair = HashPair(key: key, value: value)
        let hashMap = HashMap(pairs: [key.hashKey(): hashPair])

        #expect(hashMap.type == .hashMap)
        #expect(hashMap.inspect() == "{\"name\": \"monkey\"}")
    }
}
