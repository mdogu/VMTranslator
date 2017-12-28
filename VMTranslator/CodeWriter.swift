//
//  CodeWriter.swift
//  VMTranslator
//
//  Created by Murat Dogu on 27.12.2017.
//  Copyright © 2017 Murat Dogu. All rights reserved.
//

import Foundation

class CodeWriter {
    
    let outputFile: FileHandle
    var nextUniqueNumber = 0
    var decoration: String {
        let value = "$\(nextUniqueNumber)"
        nextUniqueNumber += 1
        return value
    }
    
    init(outputFileURL: URL) throws {
        if FileManager.default.fileExists(atPath: outputFileURL.path) == false {
            FileManager.default.createFile(atPath: outputFileURL.path, contents: nil, attributes: nil)
        }
        self.outputFile = try FileHandle(forUpdating: outputFileURL)
    }
    
    func write(command: Command, fileName: String) {
        let assemblyCommands: String
        switch command {
        case .arithmeticLogical(let instruction):
            let binary = """
                    // %@
                    @SP
                    AM=M-1
                    D=M
                    @SP
                    A=M-1
                    %@
                    """
            let unary = """
                    // %@
                    @SP
                    A=M-1
                    %@
                    """
            let comp = """
                    D=M-D
                    @TRUE%@
                    D;%@
                    D=0
                    @THEN%@
                    0;JMP
                    (TRUE%@)
                    D=-1
                    (THEN%@)
                    @SP
                    A=M-1
                    M=D
                    """
            switch instruction {
            case .add:
                assemblyCommands = String(format: binary, instruction.rawValue, "M=D+M")
            case .sub:
                assemblyCommands = String(format: binary, instruction.rawValue, "M=M-D")
            case .neg:
                assemblyCommands = String(format: unary, instruction.rawValue, "M=-M")
            case .eq:
                let trueDecoration = decoration
                let thenDecoration = decoration
                let followup = String(format: comp, trueDecoration, "JEQ", thenDecoration, trueDecoration, thenDecoration)
                assemblyCommands = String(format: binary, instruction.rawValue, followup)
            case .gt:
                let trueDecoration = decoration
                let thenDecoration = decoration
                let followup = String(format: comp, trueDecoration, "JGT", thenDecoration, trueDecoration, thenDecoration)
                assemblyCommands = String(format: binary, instruction.rawValue, followup)
            case .lt:
                let trueDecoration = decoration
                let thenDecoration = decoration
                let followup = String(format: comp, trueDecoration, "JLT", thenDecoration, trueDecoration, thenDecoration)
                assemblyCommands = String(format: binary, instruction.rawValue, followup)
            case .and:
                assemblyCommands = String(format: binary, instruction.rawValue, "M=D&M")
            case .or:
                assemblyCommands = String(format: binary, instruction.rawValue, "M=D|M")
            case .not:
                assemblyCommands = String(format: unary, instruction.rawValue, "M=!M")
            }
        case .memoryAccess(let instruction):
            switch instruction {
            case let .push(segment, index):
                let pushTemplate = """
                                %@
                                @SP
                                M=M+1
                                A=M-1
                                M=D
                                """
                let dynamicTemplate = """
                                // push \(segment.rawValue) \(index)
                                @%@
                                D=M
                                @\(index)
                                A=D+A
                                D=M
                                """
                let fixedTemplate = """
                                // push \(segment.rawValue) \(index)
                                @%d
                                D=A
                                @\(index)
                                A=D+A
                                D=M
                                """
                switch segment {
                case .argument:
                    let beginning = String(format: dynamicTemplate, "ARG")
                    assemblyCommands = String(format: pushTemplate, beginning)
                case .local:
                    let beginning = String(format: dynamicTemplate, "LCL")
                    assemblyCommands = String(format: pushTemplate, beginning)
                case .statik:
                    let staticTemplate = """
                                        // push \(segment.rawValue) \(index)
                                        @\(fileName).\(index)
                                        D=M
                                        """
                    assemblyCommands = String(format: pushTemplate, staticTemplate)
                case .constant:
                    let constantTemplate = """
                                        // push \(segment.rawValue) \(index)
                                        @\(index)
                                        D=A
                                        """
                    assemblyCommands = String(format: pushTemplate, constantTemplate)
                case .this:
                    let beginning = String(format: dynamicTemplate, "THIS")
                    assemblyCommands = String(format: pushTemplate, beginning)
                case .that:
                    let beginning = String(format: dynamicTemplate, "THAT")
                    assemblyCommands = String(format: pushTemplate, beginning)
                case .pointer:
                    let beginning = String(format: fixedTemplate, 3)
                    assemblyCommands = String(format: pushTemplate, beginning)
                case .temp:
                    let beginning = String(format: fixedTemplate, 5)
                    assemblyCommands = String(format: pushTemplate, beginning)
                }
            case let .pop(segment, index):
                let popTemplate = """
                                %@
                                @R13
                                M=D
                                @SP
                                AM=M-1
                                D=M
                                @R13
                                A=M
                                M=D
                                """
                let dynamicTemplate = """
                                // pop \(segment) \(index)
                                @%@
                                D=M
                                @\(index)
                                D=D+A
                                """
                let fixedTemplate = """
                                // pop \(segment) \(index)
                                @%d
                                D=A
                                @\(index)
                                D=D+A
                                """
                switch segment {
                case .argument:
                    let beginning = String(format: dynamicTemplate, "ARG")
                    assemblyCommands = String(format: popTemplate, beginning)
                case .local:
                    let beginning = String(format: dynamicTemplate, "LCL")
                    assemblyCommands = String(format: popTemplate, beginning)
                case .statik:
                    let staticTemplate = """
                                        // pop \(segment) \(index)
                                        @\(fileName).\(index)
                                        D=A
                                        """
                    assemblyCommands = String(format: popTemplate, staticTemplate)
                case .constant:
                    assemblyCommands = ""
                case .this:
                    let beginning = String(format: dynamicTemplate, "THIS")
                    assemblyCommands = String(format: popTemplate, beginning)
                case .that:
                    let beginning = String(format: dynamicTemplate, "THAT")
                    assemblyCommands = String(format: popTemplate, beginning)
                case .pointer:
                    let beginning = String(format: fixedTemplate, 3)
                    assemblyCommands = String(format: popTemplate, beginning)
                case .temp:
                    let beginning = String(format: fixedTemplate, 5)
                    assemblyCommands = String(format: popTemplate, beginning)
                }
            }
        case .programFlow:
            assemblyCommands = ""
        case .functionCalling:
            assemblyCommands = ""
        }
        outputFile.write(line: assemblyCommands)
    }
    
    func closeFile() {
        outputFile.closeFile()
    }
}
