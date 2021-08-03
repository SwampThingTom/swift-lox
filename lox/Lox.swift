//
//  Lox.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

protocol ErrorReporting {
    var hadError: Bool { get }
    func error(line: Int, message: String)
    func error(at token: Token, message: String)
    func error(runtimeError: RuntimeError)
}

class Lox: ErrorReporting {
    
    private static let quitCommand = "quit"
    
    private let io: LoxIO
    var hadError = false
    
    private let interpreter: Interpreter
    
    init(io: LoxIO) {
        self.io = io
        self.interpreter = Interpreter(io: io)
        interpreter.errorReporter = self
    }
    
    func runScript(_ script: String) {
        do {
            let contents = try String(contentsOfFile: script)
            run(contents)
            if hadError {
                exit(EXIT_FAILURE)
            }
        } catch {
            io.printErrorLine("Unable to read file \"\(script)\": \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        }
    }
    
    func runPrompt() {
        io.printLine("Running Lox in interactive mode.")
        io.printLine("Type \"\(Lox.quitCommand)\" to exit.")
        while true {
            guard let line = io.readLine() else {
                io.printErrorLine("Unable to read input.")
                exit(EXIT_FAILURE)
            }
            guard line.lowercased() != Lox.quitCommand else {
                break
            }
            run(line)
            hadError = false
        }
    }
    
    private func run(_ text: String) {
        let scanner = Scanner(source: text, errorReporter: self)
        let tokens = scanner.scanTokens()
        
        let parser = Parser(tokens: tokens, errorReporter: self)
        let statements = parser.parse()
        guard !hadError else { return }
        
        let resolver = Resolver(lox: self, interpreter: interpreter)
        resolver.resolve(statements)
        guard !hadError else { return }
        
        interpreter.interpret(statements)
    }
    
    func error(at token: Token, message: String) {
        if token.tokenType == .eof {
            reportParserError(at: token.line, lexeme: " at end", message: message)
        } else {
            reportParserError(at: token.line, lexeme: " at \(token.lexeme)", message: message)
        }
    }

    func error(line: Int, message: String) {
        reportParserError(at: line, lexeme: "", message: message)
    }
    
    private func reportParserError(at line: Int, lexeme: String, message: String) {
        io.printErrorLine("[line \(line)] Error\(lexeme): \(message)")
        hadError = true
    }

    func error(runtimeError: RuntimeError) {
        switch runtimeError {
        case .functionArgumentMismatch(let token, let message): fallthrough
        case .notCallable(let token, let message): fallthrough
        case .typeMismatch(let token, let message): fallthrough
        case .undefinedVariable(let token, let message):
            io.printErrorLine("\(message)\n[line \(token.line)]")
        case .unexpected(let message):
            io.printErrorLine(message)
        }
        hadError = true
    }
}
