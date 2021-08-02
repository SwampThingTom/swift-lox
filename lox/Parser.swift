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
    
    func parse() -> [Stmt] {
        var statements = [Stmt]()
        while !isAtEnd {
            if let declaration = declaration() {
                statements.append(declaration)
            }
        }
        return statements
    }
    
    private func declaration() -> Stmt? {
        do {
            if match(tokenType: .keywordVar) {
                return try varDeclaration()
            }
            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }
    
    private func varDeclaration() throws -> Stmt {
        let name = try consume(tokenType: .identifier, errorIfMissing: "Expect variable name.")
        let initializer = match(tokenType: .equal) ? try expression() : nil
        try consume(tokenType: .semicolon, errorIfMissing: "Expect ';' after variable declaration.")
        return Stmt.Var(name: name, initializer: initializer)
    }
    
    private func statement() throws -> Stmt {
        if match(tokenType: .keywordFor) {
            return try forStatement()
        }
        if match(tokenType: .keywordIf) {
            return try ifStatement()
        }
        if match(tokenType: .keywordPrint) {
            return try printStatement()
        }
        if match(tokenType: .keywordWhile) {
            return try whileStatement()
        }
        if match(tokenType: .leftBrace) {
            return Stmt.Block(statements: try block())
        }
        return try expressionStatement()
    }
    
    private func forStatement() throws -> Stmt {
        try consume(tokenType: .leftParen, errorIfMissing: "Expect '(' after 'for'.")
        let initializer = try forInitializer()
        
        let condition = !check(tokenType: .semicolon) ? try expression() : Expr.Literal(value: true)
        try consume(tokenType: .semicolon, errorIfMissing: "Expect ';' after loop condition.")
        
        let increment = !check(tokenType: .rightParen) ? try expression() : nil
        try consume(tokenType: .rightParen, errorIfMissing: "Expect ')' after for clauses.")
        
        let body = try statement()
        
        return try buildForStatement(initializer: initializer,
                                     condition: condition,
                                     increment: increment,
                                     body: body)
    }
    
    private func forInitializer() throws -> Stmt? {
        if match(tokenType: .semicolon) { return nil }
        if match(tokenType: .keywordVar) { return try varDeclaration() }
        return try expressionStatement()
    }
    
    private func buildForStatement(initializer: Stmt?,
                                   condition: Expr,
                                   increment: Expr?,
                                   body: Stmt) throws -> Stmt {
        var builder = body
        
        if let increment = increment {
            builder = Stmt.Block(statements: [builder, Stmt.Expression(expression: increment)])
        }
        
        builder = Stmt.While(condition: condition, body: builder)
        
        if let initializer = initializer {
            builder = Stmt.Block(statements: [initializer, builder])
        }
        
        return builder
    }
    
    private func ifStatement() throws -> Stmt {
        try consume(tokenType: .leftParen, errorIfMissing: "Expect '(' after 'if'.")
        let condition = try expression()
        try consume(tokenType: .rightParen, errorIfMissing: "Expect ')' after if condition.")
        
        let thenBranch = try statement()
        let elseBranch = match(tokenType: .keywordElse) ? try statement() : nil
        
        return Stmt.If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }
    
    private func printStatement() throws -> Stmt {
        let value = try expression()
        try consume(tokenType: .semicolon, errorIfMissing: "Expect ; after value.")
        return Stmt.Print(expression: value)
    }
    
    private func whileStatement() throws -> Stmt {
        try consume(tokenType: .leftParen, errorIfMissing: "Expect '(' after 'while'.")
        let condition = try expression()
        try consume(tokenType: .rightParen, errorIfMissing: "Expect ')' after condition.")
        let body = try statement()
        return Stmt.While(condition: condition, body: body)
    }
    
    private func expressionStatement() throws -> Stmt {
        let value = try expression()
        try consume(tokenType: .semicolon, errorIfMissing: "Expect ; after expression.")
        return Stmt.Expression(expression: value)
    }
    
    private func block() throws -> [Stmt] {
        var statements = [Stmt]()
        
        while !check(tokenType: .rightBrace) && !isAtEnd {
            if let declaration = declaration() {
                statements.append(declaration)
            }
        }
        
        try consume(tokenType: .rightBrace, errorIfMissing: "Expect '}' after block.")
        return statements
    }
    
    private func assignment() throws -> Expr {
        let expr = try or()
        
        if match(tokenType: .equal) {
            let equals = previous
            let value = try assignment()
            if let expr = expr as? Expr.Variable {
                return Expr.Assign(name: expr.name, value: value)
            }
            
            // report but don't throw
            _ = error(at: equals, message: "Invalid assignment target.")
        }
        
        return expr
    }
    
    private func or() throws -> Expr {
        try parseLogicalExpr(parseOperand: and, operations: .keywordOr)
    }
    
    private func and() throws -> Expr {
        try parseLogicalExpr(parseOperand: equality, operations: .keywordAnd)
    }
    
    private func expression() throws -> Expr {
        try assignment()
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
        if match(tokenType: .identifier) {
            return Expr.Variable(name: previous)
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
    
    private func parseLogicalExpr(parseOperand: () throws -> Expr, operations: TokenType...) throws -> Expr {
        var expr = try parseOperand()
        while match(any: operations) {
            let oper = previous
            let right = try parseOperand()
            expr = Expr.Logical(left: expr, oper: oper, right: right)
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
