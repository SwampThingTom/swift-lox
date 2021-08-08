//
//  Console.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation
import Lox

class ConsoleIO: LoxIO {
    
    func printLine(_ message: String) {
        Swift.print(message)
    }
    
    func printErrorLine(_ message: String) {
        var stderr = FileHandle.standardError
        Swift.print("\(message)", to: &stderr)
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
