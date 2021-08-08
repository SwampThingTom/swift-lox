//
//  LoxIO.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

public protocol LoxIO {
    func printLine(_ message: String)
    func printErrorLine(_ message: String)
    func readLine() -> String?
}
