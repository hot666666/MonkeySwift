import Foundation

// MARK: - BuiltinFunction
public typealias BuiltinFunction = @Sendable ([any Object]) -> any Object

// MARK: - Builtin
public struct Builtin: Object {
    public let fn: BuiltinFunction
    
    public init(fn: @escaping BuiltinFunction) {
        self.fn = fn
    }
    
    public var type: ObjectType { .builtin }
    
    public func inspect() -> String {
        return "builtin function"
    }
}

public let builtins: [String: Builtin] = [
    "len": Builtin(fn: { args in
        guard args.count == 1 else {
            return ErrorObject(message: "wrong number of arguments. got=\(args.count), want=1")
        }
        
        switch args[0] {
        case let str as StringObject:
            return Integer(value: str.value.count)
        default:
            return ErrorObject(message: "argument to `len` not supported, got \(args[0].type.rawValue)")
        }
    })
]
