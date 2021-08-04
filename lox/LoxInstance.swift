//
//  LoxInstance.swift
//  lox
//
//  Created by Thomas Aylesworth on 8/3/21.
//

import Foundation

class LoxInstance: CustomStringConvertible {
    
    private var klass: LoxClass
    
    var description: String {
        "\(klass.name) instance"
    }
    
    init(_ klass: LoxClass) {
        self.klass = klass
    }
}
