//
//  Resolver.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/2/21.
//

import Foundation

typealias Scope = Dictionary<String, Bool>

enum ClassType {
    case none, klass, subklass
}

enum FunctionType {
    case none, function, initializer, method
}

class Resolver {
    
    typealias ExprVisitorReturnType = Void
    typealias StmtVisitorReturnType = Void
    
    private let errorReporter: ErrorReporting
    private let interpreter: Interpreter
    
    private var scopes = [Scope]()
    private var currentFunction = FunctionType.none
    private var currentClass = ClassType.none
    
    init(errorReporter: ErrorReporting, interpreter: Interpreter) {
        self.errorReporter = errorReporter
        self.interpreter = interpreter
    }
    
    func resolve(_ statements: [Stmt]) {
        do {
            try statements.forEach() { try resolve($0) }
        } catch {
            // errors have already been reported
        }
    }
        
    private func resolve(_ stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }
    
    private func resolve(_ expr: Expr) throws {
        try expr.accept(visitor: self)
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
        
    private func resolve(local expr: Expr, token: Token) {
        for index in stride(from: scopes.count - 1, through: 0, by: -1) {
            if scopes[index].contains(key: token.lexeme) {
                interpreter.resolve(expr, depth: scopes.count - index - 1)
                return
            }
        }
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
}

extension Resolver: ExprVisitor {
    
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
        try resolve(expr.expression)
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) throws -> Void {
        // nothing to resolve
    }
    
    func visitLogicalExpr(_ expr: Expr.Logical) throws -> Void {
        try resolve(expr.left)
        try resolve(expr.right)
    }
    
    func visitSetExpr(_ expr: Expr.Set) throws -> Void {
        try resolve(expr.value)
        try resolve(expr.object)
    }
    
    func visitSuperExpr(_ expr: Expr.Super) throws -> Void {
        if currentClass == .none {
            lox.error(at: expr.keyword, message: "Can't use 'super' outside of a class.")
        } else if currentClass != .subklass {
            lox.error(at: expr.keyword, message: "Can't use 'super' in a class with no superclass.")
        }
        resolve(local: expr, token: expr.keyword)
    }
    
    func visitThisExpr(_ expr: Expr.This) throws -> Void {
        guard currentClass != .none else {
            lox.error(at: expr.keyword, message: "Can't use 'this' outside of a class.")
            return
        }
        resolve(local: expr, token: expr.keyword)
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
}

extension Resolver: StmtVisitor {
    
    func visitBlockStmt(_ stmt: Stmt.Block) throws -> Void {
        beginScope()
        try stmt.statements.forEach() { try resolve($0) }
        endScope()
    }
    
    func visitClassStmt(_ stmt: Stmt.Class) throws -> Void {
        let enclosingClass = currentClass
        currentClass = .klass
        
        declare(stmt.name)
        define(stmt.name)
        
        if let superclass = stmt.superclass {
            if stmt.name.lexeme == superclass.name.lexeme {
                lox.error(at: superclass.name, message: "A class can't inherit from itself.")
            }
            currentClass = .subklass
            try resolve(superclass)
            
            beginScope()
            scopes[scopes.count - 1]["super"] = true
        }
        
        beginScope()
        scopes[scopes.count - 1]["this"] = true
        stmt.methods.forEach() {
            let functionType: FunctionType = $0.name.lexeme == "init" ? .initializer : .method
            resolve(function: $0, functionType: functionType)
        }
        endScope()
        
        if stmt.superclass != nil {
            endScope()
        }
        
        currentClass = enclosingClass
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
            if currentFunction == .initializer {
                lox.error(at: stmt.keyword, message: "Can't return a value from an initializer.")
            }
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
}

extension Scope {
    func contains(key: String) -> Bool {
        self[key] != nil
    }
}
