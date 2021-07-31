//
//  Lox.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

class Lox {
    
    private static let quitCommand = "quit"
    
    private let console = Console.shared
    
    private var executableName: String {
        (CommandLine.arguments[0] as NSString).lastPathComponent
    }
    
    func run() {
        guard CommandLine.argc <= 2 else {
            printUsage()
            exit(EXIT_FAILURE)
        }
        if CommandLine.argc == 2 {
            runScript(CommandLine.arguments[1])
        } else {
            runPrompt()
        }
    }
    
    private func runScript(_ script: String) {
        do {
            let contents = try String(contentsOfFile: script)
            run(contents)
        } catch {
            console.printError("Unable to read file \"\(script)\": \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        }
    }
    
    private func runPrompt() {
        console.print("Running \(executableName) in interactive mode.")
        console.print("Type \"\(Lox.quitCommand)\" to exit.")
        while true {
            guard let line = console.readLine() else {
                console.printError("Unable to read input.")
                exit(EXIT_FAILURE)
            }
            guard line.lowercased() != Lox.quitCommand else {
                break
            }
            run(line)
        }
    }
    
    private func run(_ text: String) {
    }
    
    private func printUsage() {
        console.print("Usage: \(executableName) [script]")
    }
}
