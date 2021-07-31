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
}

class Lox: ErrorReporting {
    
    private static let quitCommand = "quit"
    
    private let io: LoxIO
    var hadError = false
    
    init(io: LoxIO) {
        self.io = io
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
        for token in tokens {
            console.printLine("\(token)")
        }
    }
    
    func error(line: Int, message: String) {
        report(line: line, component: "", message: message)
    }
    
    private func report(line: Int, component: String, message: String) {
        io.printErrorLine("[line \(line)] Error\(component): \(message)")
        hadError = true
    }
}
