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
    weak var codeWriter: CodeWriter? {
        didSet {
            codeWriter?.inputFileName = inputFileName
        }
    }
    
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
                guard let cmd = Command.ArithmeticLogical(rawValue: command) else { continue }
                codeWriter?.write(command: .arithmeticLogical(cmd))
            case "push", "pop":
                guard parts.count == 3,
                    let cmd = Command.MemoryAccess(rawValue: command),
                    let segment = Command.MemoryAccess.Segment(rawValue: parts[1]),
                    let index = Int(parts[2]) else { continue }
                codeWriter?.write(command: .memoryAccess(cmd, segment, index))
            case "label", "goto", "if-goto":
                guard parts.count == 2,
                    let cmd = Command.ProgramFlow(rawValue: command) else { continue }
                let label = parts[1]
                codeWriter?.write(command: .programFlow(cmd, label))
            case "function":
                guard parts.count == 3,
                    let numberOfLocalVariables = Int(parts[2]) else { continue }
                let functionName = parts[1]
                codeWriter?.write(command: .functionCalling(.function(functionName, numberOfLocalVariables)))
            case "call":
                guard parts.count == 3,
                    let numberOfArguments = Int(parts[2]) else { continue }
                let functionName = parts[1]
                codeWriter?.write(command: .functionCalling(.call(functionName, numberOfArguments)))
            case "return":
                guard parts.count == 1 else { continue }
                codeWriter?.write(command: .functionCalling(.rturn))
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
    
    enum MemoryAccess: String {
        enum Segment: String {
            case argument, local, statik = "static", constant, this, that, pointer, temp
        }
        
        case push, pop
    }
    
    enum ProgramFlow: String {
        case label, goto, ifgoto = "if-goto"
    }
    
    enum FunctionCalling {
        case function(String, Int)
        case call(String, Int)
        case rturn
    }
    
    case arithmeticLogical(ArithmeticLogical)
    case memoryAccess(MemoryAccess, MemoryAccess.Segment, Int)
    case programFlow(ProgramFlow, String)
    case functionCalling(FunctionCalling)
}
