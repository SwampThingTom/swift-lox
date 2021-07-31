//
//  ASTPrinter.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

class ASTPrinter: ExprVisitor {
    
    func print(expr: Expr) -> String {
        expr.accept(visitor: self)
    }
    
    func visitBinaryExpr(_ expr: Expr.Binary) -> String {
        parenthesize(name: expr.oper.lexeme, expressions: expr.left, expr.right)
    }
    
    func visitGroupingExpr(_ expr: Expr.Grouping) -> String {
        parenthesize(name: "group", expressions: expr.expression)
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) -> String {
        guard let value = expr.value else { return "nil" }
        return "\(value)"
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) -> String {
        parenthesize(name: expr.oper.lexeme, expressions: expr.right)
    }
    
    private func parenthesize(name: String, expressions: Expr...) -> String {
        let operands = expressions
            .map() { $0.accept(visitor: self) }
            .joined(separator: " ")
        return "(\(name) \(operands))"
    }
}
