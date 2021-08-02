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
    
    var arity: Int {
        declaration.params.count
    }
    
    var description: String {
        "<fn \(declaration.name.lexeme)>"
    }
    
    init(_ declaration: Stmt.Function, closure: Environment) {
        self.declaration = declaration
        self.closure = closure
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let environment = Environment(enclosing: closure)
        for index in 0 ..< declaration.params.count {
            environment.define(token: declaration.params[index], value: arguments[index])
        }
        
        do {
            try interpreter.execute(block: declaration.body, environment: environment)
        } catch ControlFlow.functionReturn(let value) {
            return value
        }
        return nil
    }
}
