//
//  Resolver.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/2/21.
//

import Foundation

typealias Scope = Dictionary<String, Bool>

enum FunctionType {
    case none, function
}

class Resolver: ExprVisitor, StmtVisitor {
    
    typealias ExprVisitorReturnType = Void
    typealias StmtVisitorReturnType = Void
    
    private let lox: Lox
    private let interpreter: Interpreter
    
    private var scopes = [Scope]()
    private var currentFunction: FunctionType = .none
    
    init(lox: Lox, interpreter: Interpreter) {
        self.lox = lox
        self.interpreter = interpreter
    }
    
    func resolve(_ statements: [Stmt]) {
        do {
            try statements.forEach() { try resolve($0) }
        } catch {
            // errors have already been reported
        }
    }
    
    func visitBlockStmt(_ stmt: Stmt.Block) throws -> Void {
        beginScope()
        try stmt.statements.forEach() { try resolve($0) }
        endScope()
    }
    
    func visitClassStmt(_ stmt: Stmt.Class) throws -> Void {
        declare(stmt.name)
        define(stmt.name)
    }
    
    func visitExpressionStmt(_ stmt: Stmt.Expression) throws -> Void {
        try resolve(stmt.expression)
    }
    
    func visitFunctionStmt(_ stmt: Stmt.Function) throws -> Void {
        declare(stmt.name)
        define(stmt.name)
        resolve(function: stmt, functionType: .function)
    }
    
    func visitIfStmt(_ stmt: Stmt.If) throws -> Void {
        try resolve(stmt.condition)
        try resolve(stmt.thenBranch)
        if let elseBranch = stmt.elseBranch {
            try resolve(elseBranch)
        }
    }
    
    func visitPrintStmt(_ stmt: Stmt.Print) throws -> Void {
        try resolve(stmt.expression)
    }
    
    func visitReturnStmt(_ stmt: Stmt.Return) throws -> Void {
        guard currentFunction != .none else {
            lox.error(at: stmt.keyword, message: "Can't return from top-level code.")
            return
        }
        
        if let stmtValue = stmt.value {
            try resolve(stmtValue)
        }
    }
    
    func visitVarStmt(_ stmt: Stmt.Var) throws -> Void {
        declare(stmt.name)
        if let initializer = stmt.initializer {
            try resolve(initializer)
        }
        define(stmt.name)
    }
    
    func visitWhileStmt(_ stmt: Stmt.While) throws -> Void {
        try resolve(stmt.condition)
        try resolve(stmt.body)
    }
    
    func visitAssignExpr(_ expr: Expr.Assign) throws -> Void {
        if let exprValue = expr.value {
            try resolve(exprValue)
        }
        resolve(local: expr, token: expr.name)
    }
    
    func visitBinaryExpr(_ expr: Expr.Binary) throws -> Void {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    func visitCallExpr(_ expr: Expr.Call) throws -> Void {
        try resolve(expr.callee)
        try expr.arguments.forEach { try resolve($0) }
    }
    
    func visitGetExpr(_ expr: Expr.Get) throws -> Void {
        try resolve(expr.object)
    }
    
    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> Void {
        try resolve(expr)
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) throws -> Void {
        // nothing to resolve
    }
    
    func visitLogicalExpr(_ expr: Expr.Logical) throws -> Void {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    func visitSetExpr(_ expr: Expr.Set) throws -> Void {
        // TODO: Implement
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) throws -> Void {
        try resolve(expr.right)
    }
    
    func visitVariableExpr(_ expr: Expr.Variable) throws -> Void {
        if let scope = scopes.last, let defined = scope[expr.name.lexeme], !defined {
            lox.error(at: expr.name, message: "Can't read local variable in its own initializer.")
            return
        }
        resolve(local: expr, token: expr.name)
    }
    
    private func resolve(_ stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }
    
    private func resolve(_ expr: Expr) throws {
        try expr.accept(visitor: self)
    }
    
    private func beginScope() {
        scopes.append(Scope())
    }
    
    private func endScope() {
        _ = scopes.popLast()
    }
    
    private func declare(_ token: Token) {
        guard !scopes.isEmpty else { return }
        if scopes[scopes.count - 1].contains(key: token.lexeme) {
            lox.error(at: token, message: "Already a variable with this name in this scope.")
        }
        scopes[scopes.count - 1][token.lexeme] = false
    }
    
    private func define(_ token: Token) {
        guard !scopes.isEmpty else { return }
        scopes[scopes.count - 1][token.lexeme] = true
    }
    
    private func resolve(local expr: Expr, token: Token) {
        for index in 0 ..< scopes.count {
            if scopes[index].contains(key: token.lexeme) {
                interpreter.resolve(expr, depth: scopes.count - index - 1)
                return
            }
        }
    }
    
    private func resolve(function: Stmt.Function, functionType: FunctionType) {
        let enclosingFunction = currentFunction
        currentFunction = functionType
        defer { currentFunction = enclosingFunction }
        
        beginScope()
        for param in function.params {
            declare(param)
            define(param)
        }
        resolve(function.body)
        endScope()
    }
}

extension Scope {
    func contains(key: String) -> Bool {
        self[key] != nil
    }
}
