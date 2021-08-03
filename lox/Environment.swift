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
    
    func define(name: String, value: Any?) {
        values[name] = value
    }
    
    func define(token: Token, value: Any?) {
        define(name: token.lexeme, value: value)
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
    
    func assign(at distance: Int, token: Token, value: Any?) throws {
        try ancestor(at: distance).values[token.lexeme] = value
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
    
    func get(at distance: Int, token: Token) throws -> Any? {
        try ancestor(at: distance).values[token.lexeme] as Any?
    }
    
    private func ancestor(at distance: Int) throws -> Environment {
        var environment = self
        for _ in 0 ..< distance {
            guard let enclosing = enclosing else {
                throw RuntimeError.unexpected("Unable to find scope for variable.")
            }
            environment = enclosing
        }
        return environment
    }
}
