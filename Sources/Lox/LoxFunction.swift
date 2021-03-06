//
//  LoxFunction.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/2/21.
//

import Foundation

class LoxFunction: LoxCallable {
    
    private let declaration: Stmt.Function
    private let closure: Environment
    private let isInitializer: Bool
    
    var arity: Int {
        declaration.params.count
    }
    
    var description: String {
        "<fn \(declaration.name.lexeme)>"
    }
    
    init(_ declaration: Stmt.Function, closure: Environment, isInitializer: Bool = false) {
        self.declaration = declaration
        self.closure = closure
        self.isInitializer = isInitializer
    }
    
    func bind(_ instance: LoxInstance) -> LoxFunction {
        let environment = Environment(enclosing: closure)
        environment.define(name: "this", value: instance)
        return LoxFunction(declaration, closure: environment, isInitializer: isInitializer)
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let environment = Environment(enclosing: closure)
        for index in 0 ..< declaration.params.count {
            environment.define(token: declaration.params[index], value: arguments[index])
        }
        
        var returnValue: Any? = nil
        do {
            try interpreter.execute(block: declaration.body, environment: environment)
        } catch ControlFlow.functionReturn(let value) {
            returnValue = value
        }
        
        return isInitializer ? try closure.get(at: 0, name: "this") : returnValue
    }
}

extension LoxFunction: Equatable {
    static func == (lhs: LoxFunction, rhs: LoxFunction) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
