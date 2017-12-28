//
//  Parser.swift
//  VMTranslator
//
//  Created by Murat Dogu on 27.12.2017.
//  Copyright © 2017 Murat Dogu. All rights reserved.
//

import Foundation

class Parser {
    
    let inputFileName: String
    let inputFile: FileHandle
    weak var codeWriter: CodeWriter?
    
    init(inputFileURL: URL) throws {
        self.inputFileName = inputFileURL.lastPathComponent.replacingOccurrences(of: ".vm", with: "")
        self.inputFile = try FileHandle(forReadingFrom: inputFileURL)
    }
    
    func execute() {
        while let line = inputFile.readLine() {
            var commentLess = line
            if let range = line.range(of: "//") {
                commentLess.removeSubrange(range.lowerBound...)
            }
            let trimmed = commentLess.trimmingCharacters(in: .whitespaces)
            guard trimmed.count > 0 else { continue }
            
            let parts = trimmed.components(separatedBy: .whitespaces)
            guard parts.count > 0 else { continue }
            
            let command = parts.first!.lowercased()
            switch command {
            case "add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not":
                let al = Command.ArithmeticLogical(rawValue: command)!
                codeWriter?.write(command: .arithmeticLogical(al), fileName: inputFileName)
            case "push", "pop":
                guard parts.count == 3,
                    let segment = Command.MemoryAccess.Segment(rawValue: parts[1]),
                    let index = Int(parts[2]) else { continue }
                switch command {
                case "push":
                    codeWriter?.write(command: .memoryAccess(.push(segment, index)), fileName: inputFileName)
                case "pop":
                    codeWriter?.write(command: .memoryAccess(.pop(segment, index)), fileName: inputFileName)
                default:
                    break
                }
            case "label", "goto", "if-goto":
                break
            case "function", "call", "return":
                break
            default:
                break
            }
        }
        closeFile()
    }
    
    func closeFile() {
        inputFile.closeFile()
    }
}

enum Command {
    enum ArithmeticLogical: String {
        case add, sub, neg, eq, gt, lt, and, or, not
    }
    
    enum MemoryAccess {
        enum Segment: String {
            case argument, local, statik = "static", constant, this, that, pointer, temp
        }
        
        case push(Segment, Int)
        case pop(Segment, Int)
    }
    
    case arithmeticLogical(ArithmeticLogical)
    case memoryAccess(MemoryAccess)
    case programFlow
    case functionCalling
}
