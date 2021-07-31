//
//  main.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

let console = Console()
let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent

guard CommandLine.argc <= 2 else {
    console.printError("Usage: \(executableName) [script]")
    exit(EXIT_FAILURE)
}

let lox = Lox(console: console)
if CommandLine.argc == 2 {
    lox.runScript(CommandLine.arguments[1])
} else {
    lox.runPrompt()
}
