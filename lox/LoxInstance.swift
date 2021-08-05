//
//  LoxInstance.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/3/21.
//

import Foundation

typealias Fields = Dictionary<String, Any?>

class LoxInstance: CustomStringConvertible {
    
    private var klass: LoxClass
    private var fields = Fields()
    
    var description: String {
        "\(klass.name) instance"
    }
    
    init(_ klass: LoxClass) {
        self.klass = klass
    }
    
    func get(property token: Token) throws -> Any? {
        if fields.contains(key: token.lexeme) {
            return fields[token.lexeme] as Any?
        }
        
        if let method = klass.find(method: token.lexeme) {
            return method.bind(self)
        }
        
        throw RuntimeError.undefinedProperty(token, "Undefined property '\(token.lexeme)'.")
    }
    
    func set(property token: Token, value: Any?) {
        fields[token.lexeme] = value
    }
}

extension Fields {
    func contains(key: String) -> Bool {
        self.contains(where: { $0.key == key })
    }
}
