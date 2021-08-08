//
//  Token.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

struct Token: CustomStringConvertible {
    
    let tokenType: TokenType
    let lexeme: String
    let literal: Any?
    let line: Int
    
    var description: String {
        "\(tokenType) \(lexeme) \(literal ?? "")"
    }
    
    init(tokenType: TokenType, lexeme: String = "", literal: Any? = nil, line: Int) {
        self.tokenType = tokenType
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
    }
}
