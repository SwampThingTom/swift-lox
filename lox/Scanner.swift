//
//  Scanner.swift
//  lox
//
//  Created by Thomas Aylesworth on 7/30/21.
//

import Foundation

class Scanner {
    
    private static let keywords: [String: TokenType] = [
        "and": .keywordAnd,
        "class": .keywordClass,
        "else": .keywordElse,
        "false": .keywordFalse,
        "for": .keywordFor,
        "fun": .keywordFun,
        "if": .keywordIf,
        "nil": .keywordNil,
        "or": .keywordOr,
        "print": .keywordPrint,
        "return": .keywordReturn,
        "super": .keywordSuper,
        "this": .keywordThis,
        "true": .keywordTrue,
        "var": .keywordVar,
        "while": .keywordWhile
    ]
    
    private let source: String
    private let errorReporter: ErrorReporting
    
    private var tokens = [Token]()
    private var start = 0
    private var current = 0
    private var line = 1
    
    private var isAtEnd: Bool {
        current >= source.count
    }
    
    init(source: String, errorReporter: ErrorReporting) {
        self.source = source
        self.errorReporter = errorReporter
    }
    
    func scanTokens() -> [Token] {
        while !isAtEnd {
            start = current
            scanToken()
        }
        tokens.append(Token(tokenType: .eof, line: line))
        return tokens
    }
    
    private func scanToken() {
        let c = advance()
        switch c {
        case "(": addToken(.leftParen)
        case ")": addToken(.rightParen)
        case "{": addToken(.leftBrace)
        case "}": addToken(.rightBrace)
        case ",": addToken(.comma)
        case ".": addToken(.dot)
        case "-": addToken(.minus)
        case "+": addToken(.plus)
        case ";": addToken(.semicolon)
        case "*": addToken(.star)
        case "!": addToken(match("=") ? .bangEqual : .bang)
        case "=": addToken(match("=") ? .equalEqual : .equal)
        case "<": addToken(match("=") ? .lessEqual : .less)
        case ">": addToken(match("=") ? .greaterEqual : .greater)
        case "/":
            if match("/") {
                skipComment()
            } else {
                addToken(.slash)
            }
        case "\"": addStringToken()
        case " ", "\r", "\t":
            break
        case "\n":
            line += 1
        default:
            if c.isDigit {
                addNumberToken()
            } else if c.isAlpha {
                addIdentifierToken()
            } else {
                errorReporter.error(line: line, message: "Unexpected character.")
            }
        }
    }
    
    @discardableResult
    private func advance() -> Character {
        let c = source[current]
        current += 1
        return c
    }
    
    private func peek() -> Character {
        guard !isAtEnd else { return "\0" }
        return source[current]
    }
    
    private func peekNext() -> Character {
        let next = current + 1
        guard next < source.count else { return "\0" }
        return source[next]
    }
    
    private func match(_ expected: Character) -> Bool {
        guard !isAtEnd else { return false }
        guard source[current] == expected else { return false }
        current += 1
        return true
    }
    
    private func addToken(_ tokenType: TokenType, literal: Any? = nil) {
        let text = String(source[start ..< current])
        let token = Token(tokenType: tokenType,
                          lexeme: text,
                          literal: literal,
                          line: line)
        tokens.append(token)
    }
    
    private func addStringToken() {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" {
                line += 1
            }
            advance()
        }
        
        guard !isAtEnd else {
            errorReporter.error(line: line, message: "Unterminated string.")
            return
        }
        
        // Consume closing quote.
        advance()
        
        let value = String(source[start + 1 ..< current - 1])
        addToken(.string, literal: value)
    }
    
    private func addNumberToken() {
        while peek().isDigit {
            advance()
        }
        if peek() == "." && peekNext().isDigit {
            advance()
            while peek().isDigit {
                advance()
            }
        }
        let value = Double(source[start ..< current])
        addToken(.number, literal: value)
    }
    
    private func addIdentifierToken() {
        while peek().isAlphaNumeric {
            advance()
        }
        let text = String(source[start ..< current])
        let tokenType = Scanner.keywords[text] ?? .identifier
        addToken(tokenType)
    }
    
    private func skipComment() {
        while peek() != "\n" && !isAtEnd {
            advance()
        }
    }
}

extension Character {
    var isAlpha: Bool {
        "a"..."z" ~= self || "A"..."Z" ~= self || self == "_"
    }
    var isAlphaNumeric: Bool {
        self.isAlpha || self.isDigit
    }
    var isDigit: Bool {
        "0"..."9" ~= self
    }
}

// https://stackoverflow.com/a/38215613/2348392
extension StringProtocol {
    
    subscript(_ offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(_ range: Range<Int>) -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: ClosedRange<Int>) -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1))
    }
    
    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }
    
    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count-range.lowerBound))
    }
}
