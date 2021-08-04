//
//  LoxClass.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/3/21.
//

import Foundation

class LoxClass: LoxCallable, CustomStringConvertible {
        
    let name: String
    
    var arity: Int {
        0
    }

    var description: String {
        name
    }
    
    init(name: String) {
        self.name = name
    }
    
    func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
        return LoxInstance(self)
    }
}
