//
//  ASTPrinter.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

class ASTPrinter {
    
    func print(expr: Expr) -> String {
        do {
            return try expr.accept(visitor: self)
        } catch {
            return error.localizedDescription
        }
    }
    
    func print(stmt: Stmt) -> String {
        do {
            return try stmt.accept(visitor: self)
        } catch {
            return error.localizedDescription
        }
    }
    
    private func parenthesize(name: String, expressions: Expr...) throws -> String {
        let operands = try expressions
            .map() { try $0.accept(visitor: self) }
            .joined(separator: " ")
        return "(\(name) \(operands))"
    }
    
    private func parenthesize(name: String, parts: Any...) throws -> String {
        let operands = try parts
            .map() { try transform($0) }
            .joined(separator: " ")
        return "(\(name) \(operands))"
    }
    
    private func transform(_ part: Any) throws -> String {
        if let expr = part as? Expr {
            return try expr.accept(visitor: self)
        } else if let stmt = part as? Stmt {
            return try stmt.accept(visitor: self)
        } else if let token = part as? Token {
            return token.lexeme
        } else if let list = part as? [Any] {
            return try list.map() { try transform($0) }.joined(separator: " ")
        }
        return part as? String ?? "(unknown)"
    }
}

extension ASTPrinter: ExprVisitor {
    
    func visitAssignExpr(_ expr: Expr.Assign) throws -> String {
        try parenthesize(name: "=", parts: expr.name.lexeme, expr.value as Any)
    }
    
    func visitBinaryExpr(_ expr: Expr.Binary) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.left, expr.right)
    }
    
    func visitCallExpr(_ expr: Expr.Call) throws -> String {
        try parenthesize(name: "call", parts: expr.callee, expr.arguments)
    }
    
    func visitGetExpr(_ expr: Expr.Get) throws -> String {
        try parenthesize(name: "get", parts: expr.object, expr.name.lexeme)
    }
    
    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> String {
        try parenthesize(name: "group", expressions: expr.expression)
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) -> String {
        guard let value = expr.value else { return "nil" }
        return "\(value)"
    }
    
    func visitLogicalExpr(_ expr: Expr.Logical) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.left, expr.right)
    }
    
    func visitSetExpr(_ expr: Expr.Set) throws -> String {
        try parenthesize(name: "set", parts: expr.name.lexeme, expr.value)
    }
    
    func visitSuperExpr(_ expr: Expr.Super) throws -> String {
        try parenthesize(name: "super", parts: expr.method)
    }
    
    func visitThisExpr(_ expr: Expr.This) throws -> String {
        "this"
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.right)
    }
    
    func visitVariableExpr(_ expr: Expr.Variable) throws -> String {
        expr.name.lexeme
    }
}

extension ASTPrinter: StmtVisitor {
    
    func visitBlockStmt(_ stmt: Stmt.Block) throws -> String {
        let statements = try stmt.statements
            .map() { try $0.accept(visitor: self) }
            .joined(separator: " ")
        return "(block \(statements))"
    }
    
    func visitClassStmt(_ stmt: Stmt.Class) throws -> String {
        var superclassDecl = ""
        if let superclass = stmt.superclass {
            superclassDecl = " < \(print(expr: superclass))"
        }
        
        let methods = stmt.methods.map() { " \(print(stmt: $0))" }
        
        return "(class \(superclassDecl) \(methods))"
    }
    
    func visitExpressionStmt(_ stmt: Stmt.Expression) throws -> String {
        try parenthesize(name: ";", expressions: stmt.expression)
    }
    
    func visitFunctionStmt(_ stmt: Stmt.Function) throws -> String {
        let params = stmt.params.map() { $0.lexeme }.joined(separator: " ")
        let body = try stmt.body.map() { try $0.accept(visitor: self) }
        return "(fun \(stmt.name.lexeme)(\(params)) \(body))"
    }
    
    func visitIfStmt(_ stmt: Stmt.If) throws -> String {
        guard let elseBranch = stmt.elseBranch else {
            return try parenthesize(name: "if", parts: stmt.condition, stmt.thenBranch)
        }
        return try parenthesize(name: "if-else", parts: stmt.condition, stmt.thenBranch, elseBranch)
    }
    
    func visitPrintStmt(_ stmt: Stmt.Print) throws -> String {
        try parenthesize(name: "print", expressions: stmt.expression)
    }
    
    func visitReturnStmt(_ stmt: Stmt.Return) throws -> String {
        guard let returnValue = stmt.value else {
            return "(return)"
        }
        return try parenthesize(name: "return", expressions: returnValue)
    }
    
    func visitVarStmt(_ stmt: Stmt.Var) throws -> String {
        guard let initializer = stmt.initializer else {
            return try parenthesize(name: "var", parts: stmt.name)
        }
        return try parenthesize(name: "var", parts: stmt.name, "=", initializer)
    }
    
    func visitWhileStmt(_ stmt: Stmt.While) throws -> String {
        return try parenthesize(name: "while", parts: stmt.condition, stmt.body)
    }
}
