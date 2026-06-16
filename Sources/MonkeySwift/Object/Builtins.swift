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
        case let arr as ArrayObject:
            return Integer(value: arr.elements.count)
        default:
            return ErrorObject(message: "argument to `len` not supported, got \(args[0].type.rawValue)")
        }
    }),
    "first": Builtin(fn: { args in
        guard args.count == 1 else {
            return ErrorObject(message: "wrong number of arguments. got=\(args.count), want=1")
        }
        guard let arr = args[0] as? ArrayObject else {
            return ErrorObject(message: "argument to `first` must be ARRAY, got \(args[0].type.rawValue)")
        }
        return arr.elements.first ?? Null()
    }),
    "last": Builtin(fn: { args in
        guard args.count == 1 else {
            return ErrorObject(message: "wrong number of arguments. got=\(args.count), want=1")
        }
        guard let arr = args[0] as? ArrayObject else {
            return ErrorObject(message: "argument to `last` must be ARRAY, got \(args[0].type.rawValue)")
        }
        return arr.elements.last ?? Null()
    }),
    "rest": Builtin(fn: { args in
        guard args.count == 1 else {
            return ErrorObject(message: "wrong number of arguments. got=\(args.count), want=1")
        }
        guard let arr = args[0] as? ArrayObject else {
            return ErrorObject(message: "argument to `rest` must be ARRAY, got \(args[0].type.rawValue)")
        }
        guard arr.elements.count > 0 else {
            return Null()
        }
        return ArrayObject(elements: Array(arr.elements.dropFirst()))
    }),
    "push": Builtin(fn: { args in
        guard args.count == 2 else {
            return ErrorObject(message: "wrong number of arguments. got=\(args.count), want=2")
        }
        guard let arr = args[0] as? ArrayObject else {
            return ErrorObject(message: "argument to `push` must be ARRAY, got \(args[0].type.rawValue)")
        }
        var newElements = arr.elements
        newElements.append(args[1])
        return ArrayObject(elements: newElements)
    }),
    "puts": Builtin(fn: { args in
        for arg in args {
            print(arg.inspect())
        }
        return Null()
    })
]
