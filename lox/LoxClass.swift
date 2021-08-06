//
//  LoxClass.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/3/21.
//

import Foundation

class LoxClass: LoxCallable, CustomStringConvertible {
    
    let name: String
    let superclass: LoxClass?
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
    
    init(name: String, superclass: LoxClass?,  methods: Dictionary<String, LoxFunction>) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
    }
    
    func find(method: String) -> LoxFunction? {
        if let method = methods[method] {
            return method
        }
        if let superclass = superclass {
            return superclass.find(method: method)
        }
        return nil
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        let instance = LoxInstance(self)
        if let initializer = initializer {
            _ = try initializer.bind(instance).call(interpreter: interpreter, arguments: arguments)
        }
        return instance
    }
}
