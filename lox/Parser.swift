//
//  Parser.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

enum ParseError: Error {
    case unexpectedToken
}

class Parser {
    
    private let errorReporter: ErrorReporting
    private let tokens: [Token]
    private var current: Int = 0
    
    private var isAtEnd: Bool {
        peek.tokenType == .eof
    }
    
    private var peek: Token {
        tokens[current]
    }
    
    private var previous: Token {
        tokens[current - 1]
    }
    
    init(tokens: [Token], errorReporter: ErrorReporting) {
        self.errorReporter = errorReporter
        self.tokens = tokens
    }
    
    func parse() -> Expr? {
        try? expression()
    }
    
    private func expression() throws -> Expr {
        try equality()
    }
    
    private func equality() throws -> Expr {
        try parseBinaryExpr(parseOperand: comparison, operations: .bangEqual, .equalEqual)
    }
    
    private func comparison() throws -> Expr {
        try parseBinaryExpr(parseOperand: term, operations: .greater, .greaterEqual, .less, .lessEqual)
    }
    
    private func term() throws -> Expr {
        try parseBinaryExpr(parseOperand: factor, operations: .minus, .plus)
    }
    
    private func factor() throws -> Expr {
        try parseBinaryExpr(parseOperand: unary, operations: .slash, .star)
    }
    
    private func unary() throws -> Expr {
        if match(any: [.bang, .minus]) {
            let oper = previous
            let right = try unary()
            return Expr.Unary(oper: oper, right: right)
        }
        return try primary()
    }
    
    private func primary() throws -> Expr {
        if match(tokenType: .keywordFalse) {
            return Expr.Literal(value: false)
        }
        if match(tokenType: .keywordTrue) {
            return Expr.Literal(value: true)
        }
        if match(tokenType: .keywordNil) {
            return Expr.Literal(value: nil)
        }
        if match(any: [.number, .string]) {
            return Expr.Literal(value: previous.literal)
        }
        if match(tokenType: .leftParen) {
            let expr = try expression()
            try consume(tokenType: .rightParen, errorIfMissing: "Expect ')' after expression.")
            return Expr.Grouping(expression: expr)
        }
        throw error(at: peek, message: "Expect expression.");
    }
    
    @discardableResult
    private func consume(tokenType: TokenType, errorIfMissing errorMessage: String) throws -> Token {
        if check(tokenType: tokenType) {
            return advance()
        }
        throw error(at: peek, message: errorMessage)
    }
    
    private func error(at token: Token, message: String) -> ParseError {
        errorReporter.error(at: token, message: message)
        return ParseError.unexpectedToken
    }
    
    private func synchronize() {
        advance()
        
        while !isAtEnd {
            guard previous.tokenType != .semicolon else { return }
            
            switch peek.tokenType {
            case .keywordClass,
                 .keywordFor,
                 .keywordFun,
                 .keywordIf,
                 .keywordPrint,
                 .keywordReturn,
                 .keywordVar,
                 .keywordWhile:
                return
            default:
                break
            }
            
            advance()
        }
    }
    
    private func parseBinaryExpr(parseOperand: () throws -> Expr, operations: TokenType...) throws -> Expr {
        var expr = try parseOperand()
        while match(any: operations) {
            let oper = previous
            let right = try parseOperand()
            expr = Expr.Binary(left: expr, oper: oper, right: right)
        }
        return expr
    }
    
    private func match(tokenType: TokenType) -> Bool {
        match(any: [tokenType])
    }
    
    private func match(any matchingTypes: [TokenType]) -> Bool {
        if matchingTypes.contains(where: { check(tokenType: $0) }) {
            advance()
            return true
        }
        return false
    }
    
    private func check(tokenType: TokenType) -> Bool {
        guard !isAtEnd else { return false }
        return peek.tokenType == tokenType
    }
    
    @discardableResult
    private func advance() -> Token {
        if !isAtEnd {
            current += 1
        }
        return previous
    }
}
