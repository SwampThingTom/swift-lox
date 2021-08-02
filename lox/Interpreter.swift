//
//  Interpreter.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

enum RuntimeError: Error {
    case functionArgumentMismatch(Token, String)
    case notCallable(Token, String)
    case typeMismatch(Token, String)
    case undefinedVariable(Token, String)
    case unexpected(String)
}

class Interpreter {

    private static let globals = { () -> Environment in
        var globalEnvironment = Environment()
        class ClockCallable: LoxCallable {
            let arity = 0
            func call(interpreter: Interpreter, arguments: [Any?]) throws -> Any? {
                return Date().timeIntervalSince1970 as Double
            }
        }
        globalEnvironment.define(name: "clock", value: ClockCallable())
        return globalEnvironment
    }()

    var errorReporter: ErrorReporting!
    
    private let io: LoxIO
    private var environment = globals
    
    init(io: LoxIO) {
        self.io = io
    }
    
    func interpret(_ statements: [Stmt]) {
        do {
            for statement in statements {
                try execute(statement)
            }
        } catch let error as RuntimeError {
            errorReporter.error(runtimeError: error)
        } catch {
            let unexpectedError = RuntimeError.unexpected("Unexpected runtime error: \(error.localizedDescription)")
            errorReporter.error(runtimeError: unexpectedError)
        }
    }
    
    private func execute(_ stmt: Stmt) throws {
        try stmt.accept(visitor: self)
    }
    
    private func execute(block: [Stmt], environment: Environment) throws {
        let previousEnvironment = self.environment
        self.environment = environment
        defer {
            self.environment = previousEnvironment
        }
        
        for statement in block {
            try execute(statement)
        }
    }
    
    private func evaluate(_ expr: Expr) throws -> Any? {
        try expr.accept(visitor: self)
    }
    
    private func stringify(_ value: Any?) -> String {
        guard let value = value else { return "nil" }
        if let numericValue = value as? Double {
            let text = String(numericValue)
            // print integral values as integers
            return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
        }
        return String(describing: value)
    }
}

// MARK: - ExprVisitor

extension Interpreter: ExprVisitor {
    
    func visitBinaryExpr(_ expr: Expr.Binary) throws -> Any? {
        let left = try evaluate(expr.left)
        let right = try evaluate(expr.right)
        
        switch expr.oper.tokenType {
        case .equalEqual:
            return isEqual(left, right)
            
        case .bangEqual:
            return !isEqual(left, right)
            
        case .greater:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l > r
            
        case .greaterEqual:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l >= r
            
        case .less:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l < r
            
        case .lessEqual:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l <= r
            
        case .minus:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l - r
            
        case .plus:
            if let l = left as? Double, let r = right as? Double {
                return l + r
            }
            if let l = left as? String, let r = right as? String {
                return l + r
            }
            throw RuntimeError.typeMismatch(expr.oper, "Operands must be two numbers or two strings.")
            
        case .slash:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l / r
            
        case .star:
            let (l, r) = try numericOperands(for: expr.oper, left: left, right: right)
            return l * r
            
        default:
            break
        }
        
        return nil
    }
    
    func visitCallExpr(_ expr: Expr.Call) throws -> Any? {
        let callee = try evaluate(expr.callee)
        let arguments = try expr.arguments.map() { try evaluate($0) }
        guard let function = callee as? LoxCallable else {
            throw RuntimeError.notCallable(expr.paren, "Can only call functions and classes.")
        }
        if arguments.count != function.arity {
            throw RuntimeError.functionArgumentMismatch(expr.paren,
                                                        "Expected \(function.arity) arguments but got \(arguments.count).")
        }
        return try function.call(interpreter: self, arguments: arguments)
    }
    
    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> Any? {
        try evaluate(expr.expression)
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) -> Any? {
        expr.value
    }
    
    func visitLogicalExpr(_ expr: Expr.Logical) throws -> Any? {
        let left = try evaluate(expr.left)
        
        if expr.oper.tokenType == .keywordOr {
            if isTruthy(left) { return left }
        } else {
            if !isTruthy(left) { return left }
        }
        
        return try evaluate(expr.right)
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) throws -> Any? {
        let right = try evaluate(expr.right)
        
        switch expr.oper.tokenType {
        case .bang:
            return !isTruthy(right)
        
        case .minus:
            let operand = try numericOperand(for: expr.oper, operand: right)
            return -operand
        
        default:
            break
        }
        
        return nil
    }
    
    func visitVariableExpr(_ expr: Expr.Variable) throws -> Any? {
        try environment.get(token: expr.name)
    }
    
    func visitAssignExpr(_ expr: Expr.Assign) throws -> Any? {
        var value: Any? = nil
        if let exprValue = expr.value {
            value = try evaluate(exprValue)
        }
        try environment.assign(token: expr.name, value: value)
        return value
    }
    
    private func numericOperand(for oper: Token, operand: Any?) throws -> Double {
        guard let operand = operand as? Double else {
            throw RuntimeError.typeMismatch(oper, "Operand must be a number.")
        }
        return operand
    }
    
    private func numericOperands(for oper: Token, left: Any?, right: Any?) throws -> (Double, Double) {
        guard let left = left as? Double, let right = right as? Double else {
            throw RuntimeError.typeMismatch(oper, "Operands must be numbers.")
        }
        return (left, right)
    }
    
    // TODO: Consider using our own type that wraps an equatable rather than using Any.
    // see https://forums.swift.org/t/anyequatable/12808
    private func isEqual(_ left: Any?, _ right: Any?) -> Bool {
        guard left != nil else {
            return right == nil
        }
        if let left = left as? Double, let right = right as? Double {
            return left == right
        }
        if let left = left as? String, let right = right as? String {
            return left == right
        }
        return false
    }
    
    private func isTruthy(_ value: Any?) -> Bool {
        if value == nil { return false }
        if let value = value as? Bool { return value }
        return true
    }
}

// MARK: - StmtVisitor

extension Interpreter: StmtVisitor {
    
    func visitBlockStmt(_ stmt: Stmt.Block) throws -> Void {
        try execute(block: stmt.statements, environment: Environment(enclosing: environment))
    }
    
    func visitExpressionStmt(_ stmt: Stmt.Expression) throws -> Void {
        _ = try evaluate(stmt.expression)
    }
    
    func visitFunctionStmt(_ stmt: Stmt.Function) throws -> Void {
        // TODO: implement
    }
    
    func visitIfStmt(_ stmt: Stmt.If) throws -> Void {
        if isTruthy(try evaluate(stmt.condition)) {
            try execute(stmt.thenBranch)
        } else if let elseBranch = stmt.elseBranch {
            try execute(elseBranch)
        }
    }
    
    func visitPrintStmt(_ stmt: Stmt.Print) throws -> Void {
        let value = try evaluate(stmt.expression)
        io.printLine(stringify(value))
    }
    
    func visitVarStmt(_ stmt: Stmt.Var) throws -> Void {
        var value: Any? = nil
        if let initializer = stmt.initializer {
            value = try evaluate(initializer)
        }
        environment.define(token: stmt.name, value: value)
    }
    
    func visitWhileStmt(_ stmt: Stmt.While) throws -> Void {
        while isTruthy(try evaluate(stmt.condition)) {
            try execute(stmt.body)
        }
    }
}
