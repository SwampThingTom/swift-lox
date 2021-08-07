//
//  main.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

fileprivate let console = ConsoleIO()

guard CommandLine.argc <= 2 else {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    console.printErrorLine("Usage: \(executableName) [script]")
    exit(EXIT_ERROR_USAGE)
}

fileprivate let lox = Lox(io: console)
if CommandLine.argc == 2 {
    lox.runScript(CommandLine.arguments[1])
} else {
    lox.runPrompt()
}
