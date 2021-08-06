//
//  LoxClass.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/3/21.
//

import Foundation

struct LoxClass: LoxCallable, CustomStringConvertible {
    
    let name: String
    let methods: Dictionary<String, LoxFunction>

    var arity: Int {
        initializer?.arity ?? 0
    }

    var description: String {
        name
    }
    
    private var initializer: LoxFunction? {
        find(method: "init")
    }
    
    init(name: String, methods: Dictionary<String, LoxFunction>) {
        self.name = name
        self.methods = methods
    }
    
    func find(method: String) -> LoxFunction? {
        methods[method]
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let instance = LoxInstance(self)
        if let initializer = initializer {
            _ = try initializer.bind(instance).call(interpreter: interpreter, arguments: arguments)
        }
        return instance
    }
}
