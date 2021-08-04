//
//  ASTPrinter.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

class ASTPrinter: ExprVisitor {
    
    func print(expr: Expr) -> String {
        do {
            return try expr.accept(visitor: self)
        } catch {
            return error.localizedDescription
        }
    }
    
    func visitAssignExpr(_ expr: Expr.Assign) throws -> String {
        try parenthesize(name: "=", expressions: expr)
    }
    
    func visitBinaryExpr(_ expr: Expr.Binary) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.left, expr.right)
    }
    
    func visitCallExpr(_ expr: Expr.Call) throws -> String {
        try parenthesize(name: "call", expressions: expr)
    }
    
    func visitGetExpr(_ expr: Expr.Get) throws -> String {
        try parenthesize(name: "get", expressions: expr)
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
        try parenthesize(name: "set", expressions: expr)
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.right)
    }
    
    func visitVariableExpr(_ expr: Expr.Variable) throws -> String {
        expr.name.lexeme
    }
    
    private func parenthesize(name: String, expressions: Expr...) throws -> String {
        let operands = try expressions
            .map() { try $0.accept(visitor: self) }
            .joined(separator: " ")
        return "(\(name) \(operands))"
    }
}
