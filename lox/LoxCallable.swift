//
//  LoxCallable.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/2/21.
//

import Foundation

protocol LoxCallable {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [Any?])
}
