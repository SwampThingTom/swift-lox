//
//  PrintWriter.swift
//  generate_ast
//
//  Created by Thomas Aylesworth on 7/31/21.
//

import Foundation

class PrintWriter {
    
    private let fileManager = FileManager.default
    private let fileHandle: FileHandle
    private let encoding: String.Encoding
    
    init?(url: URL, encoding: String.Encoding) {
        guard fileManager.createFile(atPath: url.path, contents: nil) else {
            return nil
        }
        guard let fileHandle = FileHandle(forWritingAtPath: url.path) else {
            return nil
        }
        self.fileHandle = fileHandle
        self.encoding = encoding
    }
    
    deinit {
        fileHandle.closeFile()
    }
    
    func printLine(_ line: String = "") {
        guard let data = "\(line)\n".data(using: encoding) else { return }
        fileHandle.write(data)
    }
}
