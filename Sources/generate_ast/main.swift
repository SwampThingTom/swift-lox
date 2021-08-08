//
//  main.swift
//  generate-ast
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

guard CommandLine.argc == 2 else {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    print("Usage: \(executableName) <output directory>")
    exit(EXIT_FAILURE)
}

let astGenerator = ASTGenerator()
astGenerator.generate(outputDirectory: CommandLine.arguments[1])
