//
//  Environment.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/1/21.
//

import Foundation

class Environment {
    
    private let enclosing: Environment?
    private var values = Dictionary<String, Any?>()
    
    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }
    
    func define(token: Token, value: Any?) {
        values[token.lexeme] = value
    }
    
    func assign(token: Token, value: Any?) throws {
        guard values.index(forKey: token.lexeme) != nil else {
            guard let enclosing = enclosing else {
                throw RuntimeError.undefinedVariable(token, "Undefined variable '\(token.lexeme)'.")
            }
            try enclosing.assign(token: token, value: value)
            return
        }
        values[token.lexeme] = value
    }
    
    func get(token: Token) throws -> Any? {
        guard let index = values.index(forKey: token.lexeme) else {
            guard let enclosing = enclosing else {
                throw RuntimeError.undefinedVariable(token, "Undefined variable '\(token.lexeme)'.")
            }
            return try enclosing.get(token: token)
        }
        return values[index].value
    }
}
