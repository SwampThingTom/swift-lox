//
//  ASTGenerator.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

typealias Field = (name: String, type: String)

class ASTGenerator {
    
    func generate(outputDirectory: String) {
        defineAst(outputDirectoryURL: URL(fileURLWithPath: outputDirectory),
                  baseName: "Expr",
                  types: [
                    "Assign   : Token name, Expr? value",
                    "Binary   : Expr left, Token oper, Expr right",
                    "Call     : Expr callee, Token paren, [Expr] arguments",
                    "Get      : Expr object, Token name",
                    "Grouping : Expr expression",
                    "Literal  : Any? value",
                    "Logical  : Expr left, Token oper, Expr right",
                    "Set      : Expr object, Token name, Expr value",
                    "Super    : Token keyword, Token method",
                    "This     : Token keyword",
                    "Unary    : Token oper, Expr right",
                    "Variable : Token name"
                  ])
        
        defineAst(outputDirectoryURL: URL(fileURLWithPath: outputDirectory),
                  baseName: "Stmt",
                  types: [
                    "Block      : [Stmt] statements",
                    "Class      : Token name, Expr.Variable? superclass, [Stmt.Function] methods",
                    "Expression : Expr expression",
                    "Function   : Token name, [Token] params, [Stmt] body",
                    "If         : Expr condition, Stmt thenBranch, Stmt? elseBranch",
                    "Print      : Expr expression",
                    "Return     : Token keyword, Expr? value",
                    "Var        : Token name, Expr? initializer",
                    "While      : Expr condition, Stmt body"
                  ])
    }
    
    private func defineAst(outputDirectoryURL: URL,
                           baseName: String,
                           types: [String]) {
        let fileURL = outputDirectoryURL.appendingPathComponent("\(baseName).swift")
        guard let writer = PrintWriter(url: fileURL, encoding: .utf8) else {
            print("Unable to create file '\(fileURL)'.")
            return
        }
        
        writer.printLine("// Autogenerated by Lox generate_ast.")
        writer.printLine()
        defineVisitor(writer: writer, baseName: baseName, types: types)
        
        writer.printLine()
        writer.printLine("class \(baseName) {")
        
        writer.printLine("    \(acceptVisitorFunc(for: baseName)) {")
        writer.printLine("        fatalError()")
        writer.printLine("    }")
        
        for astType in types {
            let components = astType.components(separatedBy: ":")
            let className = components[0].trimmingCharacters(in: .whitespaces)
            let fields = components[1].trimmingCharacters(in: .whitespaces)
            defineType(writer: writer,
                       baseName: baseName,
                       className: className,
                       fieldList: fields)
        }
        
        writer.printLine("}")
        
        writer.printLine()
        writer.printLine("extension \(baseName): Hashable {")
        writer.printLine("    static func ==(lhs: \(baseName), rhs: \(baseName)) -> Bool {")
        writer.printLine("        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)")
        writer.printLine("    }")
        writer.printLine()
        writer.printLine("    func hash(into hasher: inout Hasher) {")
        writer.printLine("        return ObjectIdentifier(self).hash(into: &hasher)")
        writer.printLine("    }")
        writer.printLine("}")
    }
    
    func defineVisitor(writer: PrintWriter,
                       baseName: String,
                       types: [String]) {
        writer.printLine("protocol \(baseName)Visitor {")
        writer.printLine("    associatedtype \(baseName)VisitorReturnType")
        
        for type in types {
            let typeName = type.split(separator: ":")[0].trimmingCharacters(in: .whitespaces)
            let funcName = "visit\(typeName)\(baseName)"
            let arguments = "_ \(baseName.lowercased()): \(baseName).\(typeName)"
            writer.printLine("    func \(funcName)(\(arguments)) throws -> \(baseName)VisitorReturnType")
        }
        
        writer.printLine("}")
    }
    
    private func defineType(writer: PrintWriter,
                            baseName: String,
                            className: String,
                            fieldList: String) {
        let fields = fields(from: fieldList)
        
        writer.printLine()
        writer.printLine("    class \(className): \(baseName) {")
        
        // Define properties.
        for field in fields {
            writer.printLine("        let \(field.name): \(field.type)")
        }
        
        // Define initializer.
        writer.printLine()
        writer.printLine("        init(\(arguments(for: fields))) {")
        for field in fields {
            writer.printLine("            self.\(field.name) = \(field.name)")
        }
        writer.printLine("        }")
        
        // Define accept visitor.
        writer.printLine()
        writer.printLine("        override \(acceptVisitorFunc(for: baseName)) {")
        writer.printLine("            return try visitor.visit\(className)\(baseName)(self)")
        writer.printLine("        }")
        
        writer.printLine("    }")
    }
    
    private func fields(from fieldList: String) -> [Field] {
        fieldList.components(separatedBy: ", ").map() {
            let fieldAndType = $0.split(separator: " ")
            let type = fieldAndType[0].trimmingCharacters(in: .whitespaces)
            let name = fieldAndType[1].trimmingCharacters(in: .whitespaces)
            return (name: name, type: type)
        }
    }
    
    private func arguments(for fields: [Field]) -> String {
        fields.map() { "\($0.name): \($0.type)" }
              .joined(separator: ", ")
    }
    
    private func acceptVisitorFunc(for baseName: String) -> String {
        "func accept<V: \(baseName)Visitor, R>(visitor: V) throws -> R where R == V.\(baseName)VisitorReturnType"
    }
}
