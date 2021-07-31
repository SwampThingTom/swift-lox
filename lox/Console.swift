//
//  Console.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

class Console {
    
    func print(_ message: String, terminator: String = "\n") {
        Swift.print(message, terminator: terminator)
    }
    
    func printError(_ message: String, terminator: String = "\n") {
        var stderr = FileHandle.standardError
        Swift.print("\(message)", terminator: terminator, to: &stderr)
    }
    
    func readLine() -> String? {
        Swift.print("| ", terminator: "")
        return Swift.readLine()
    }
}

// https://stackoverflow.com/a/59357395/2348392
extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        write(data)
    }
}
