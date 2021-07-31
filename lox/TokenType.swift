//
//  TokenType.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

enum TokenType {
    
    // Single-character tokens
    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case comma
    case dot
    case minus
    case plus
    case semicolon
    case slash
    case star
    
    // One or two character tokens
    case bang
    case bangEqual
    case equal
    case equalEqual
    case greater
    case greaterEqual
    case less
    case lessEqual
    
    // Literals
    case identifier
    case string
    case number
    
    // Keywords
    case keywordAnd
    case keywordClass
    case keywordElse
    case keywordFalse
    case keywordFun
    case keywordFor
    case keywordIf
    case keywordNil
    case keywordOr
    case keywordPrint
    case keywordReturn
    case keywordSuper
    case keywordThis
    case keywordTrue
    case keywordVar
    case keywordWhile
    
    case eof
}
