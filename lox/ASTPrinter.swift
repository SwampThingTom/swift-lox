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
    
    func visitBinaryExpr(_ expr: Expr.Binary) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.left, expr.right)
    }
    
    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> String {
        try parenthesize(name: "group", expressions: expr.expression)
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) -> String {
        guard let value = expr.value else { return "nil" }
        return "\(value)"
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) throws -> String {
        try parenthesize(name: expr.oper.lexeme, expressions: expr.right)
    }
    
    private func parenthesize(name: String, expressions: Expr...) throws -> String {
        let operands = try expressions
            .map() { try $0.accept(visitor: self) }
            .joined(separator: " ")
        return "(\(name) \(operands))"
    }
}
