//
//  Environment.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/1/21.
//

import Foundation

class Environment {
    
    private var values = Dictionary<String, Any?>()
    
    func define(token: Token, value: Any?) {
        values[token.lexeme] = value
    }
    
    func assign(token: Token, value: Any?) throws {
        guard values.index(forKey: token.lexeme) != nil else {
            throw RuntimeError.undefinedVariable(token, "Undefined variable '\(token.lexeme)'.")
        }
        values[token.lexeme] = value
    }
    
    func get(token: Token) throws -> Any? {
        guard let index = values.index(forKey: token.lexeme) else {
            throw RuntimeError.undefinedVariable(token, "Undefined variable '\(token.lexeme)'.")
        }
        return values[index].value
    }
}
