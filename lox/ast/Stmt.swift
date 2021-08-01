// Autogenerated by Lox generate_ast.

protocol StmtVisitor {
    associatedtype StmtVisitorReturnType
    func visitExpressionStmt(_ stmt: Stmt.Expression) throws -> StmtVisitorReturnType
    func visitPrintStmt(_ stmt: Stmt.Print) throws -> StmtVisitorReturnType
}

class Stmt {
    func accept<V: StmtVisitor, R>(visitor: V) throws -> R where R == V.StmtVisitorReturnType {
        fatalError()
    }

    class Expression: Stmt {
        let expression: Expr

        init(expression: Expr) {
            self.expression = expression
        }

        override func accept<V: StmtVisitor, R>(visitor: V) throws -> R where R == V.StmtVisitorReturnType {
            return try visitor.visitExpressionStmt(self)
        }
    }

    class Print: Stmt {
        let expression: Expr

        init(expression: Expr) {
            self.expression = expression
        }

        override func accept<V: StmtVisitor, R>(visitor: V) throws -> R where R == V.StmtVisitorReturnType {
            return try visitor.visitPrintStmt(self)
        }
    }
}