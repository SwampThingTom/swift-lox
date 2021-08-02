//
//  LoxFunction.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/2/21.
//

import Foundation

class LoxFunction: LoxCallable {
    
    private let declaration: Stmt.Function
    
    var arity: Int {
        declaration.params.count
    }
    
    var description: String {
        "<fn \(declaration.name.lexeme)>"
    }
    
    init(_ declaration: Stmt.Function) {
        self.declaration = declaration
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let environment = Environment(enclosing: Interpreter.globals)
        for index in 0 ..< declaration.params.count {
            environment.define(token: declaration.params[index], value: arguments[index])
        }
        
        try interpreter.execute(block: declaration.body, environment: environment)
        return nil
    }
}
