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
    var inputFileName: String!
    var nextUniqueNumber = 0
    var decoration: String {
        let value = "$\(nextUniqueNumber)"
        nextUniqueNumber += 1
        return value
    }
    var runningFunction: String?
    
    init(outputFileURL: URL) throws {
        if FileManager.default.fileExists(atPath: outputFileURL.path) == false {
            FileManager.default.createFile(atPath: outputFileURL.path, contents: nil, attributes: nil)
        }
        self.outputFile = try FileHandle(forUpdating: outputFileURL)
        writeInit()
    }
    
    func writeInit() {
        let bootstrapCode = """
                            // Bootstrap
                            @256
                            D=A
                            @SP
                            M=D
                            """
        outputFile.write(line: bootstrapCode)
        write(command: .functionCalling(.call("Sys.init", 0)))
    }
    
    func write(command: Command) {
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
        case let .memoryAccess(instruction, segment, index):
            switch instruction {
            case .push:
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
                                        @\(inputFileName!).\(index)
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
            case .pop:
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
                                        // pop \(segment.rawValue) \(index)
                                        @\(inputFileName!).\(index)
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
        case let .programFlow(instruction, label):
            let uniqueLabel: String
            if let functionName = runningFunction {
                uniqueLabel = "\(functionName)$\(label)"
            } else {
                uniqueLabel = label
            }
            switch instruction {
            case .label:
                let assemblyLabel = """
                                    // label \(label)
                                    (\(uniqueLabel))
                                    """
                assemblyCommands = assemblyLabel
            case .goto:
                let jmp = """
                            // goto \(label)
                            @\(uniqueLabel)
                            0;JMP
                            """
                assemblyCommands = jmp
            case .ifgoto:
                let jne = """
                            // if-goto \(label)
                            @SP
                            AM=M-1
                            D=M
                            @\(uniqueLabel)
                            D;JNE
                            """
                assemblyCommands = jne
            }
        case .functionCalling(let instruction):
            switch instruction {
            case let .function(functionName, numberOfLocalVariables):
                runningFunction = functionName
                var code = """
                            // function \(functionName) \(numberOfLocalVariables)
                            (\(functionName))
                            """
                let localVarInit = """
                                    @SP
                                    M=M+1
                                    A=M-1
                                    M=0
                                    """
                if numberOfLocalVariables > 0 {
                    for _ in 1...numberOfLocalVariables {
                        code.add(line: localVarInit)
                    }
                }
                assemblyCommands = code
            case let .call(functionName, numberOfArguments):
                let returnLabel = "RA\(decoration)"
                var code = """
                            // call \(functionName) \(numberOfArguments)
                            """
                let pushReturnAddress = """
                                        @\(returnLabel)
                                        D=A
                                        @SP
                                        M=M+1
                                        A=M-1
                                        M=D
                                        """
                code.add(line: pushReturnAddress)
                let pushSegmentTemplate = """
                                        @%@
                                        D=M
                                        @SP
                                        M=M+1
                                        A=M-1
                                        M=D
                                        """
                let pushLCL = String(format: pushSegmentTemplate, "LCL")
                code.add(line: pushLCL)
                let pushARG = String(format: pushSegmentTemplate, "ARG")
                code.add(line: pushARG)
                let pushTHIS = String(format: pushSegmentTemplate, "THIS")
                code.add(line: pushTHIS)
                let pushTHAT = String(format: pushSegmentTemplate, "THAT")
                code.add(line: pushTHAT)
                let repositionARG = """
                                    @SP
                                    D=M
                                    @\(numberOfArguments)
                                    D=D-A
                                    @5
                                    D=D-A
                                    @ARG
                                    M=D
                                    """
                code.add(line: repositionARG)
                let repositionLCL = """
                                    @SP
                                    D=M
                                    @LCL
                                    M=D
                                    """
                code.add(line: repositionLCL)
                let goto = """
                        @\(functionName)
                        0;JMP
                        """
                code.add(line: goto)
                let returnLabelDeclaration = "(\(returnLabel))"
                code.add(line: returnLabelDeclaration)
                
                assemblyCommands = code
            case .rturn:
                var code = """
                        // return
                        """
                let saveFrameAndReturnAddress = """
                                                @LCL
                                                D=M
                                                @R14
                                                M=D
                                                @5
                                                A=D-A
                                                D=M
                                                @R15
                                                M=D
                                                """
                code.add(line: saveFrameAndReturnAddress)
                let repositionReturnValue = """
                                            @SP
                                            A=M-1
                                            D=M
                                            @ARG
                                            A=M
                                            M=D
                                            """
                code.add(line: repositionReturnValue)
                let repositionSP = """
                                @ARG
                                D=M+1
                                @SP
                                M=D
                                """
                code.add(line: repositionSP)
                let restoreTHAT = """
                                @R14
                                A=M-1
                                D=M
                                @THAT
                                M=D
                                """
                code.add(line: restoreTHAT)
                let restoreTHIS = """
                                @R14
                                D=M
                                @2
                                A=D-A
                                D=M
                                @THIS
                                M=D
                                """
                code.add(line: restoreTHIS)
                let restoreARG = """
                                @R14
                                D=M
                                @3
                                A=D-A
                                D=M
                                @ARG
                                M=D
                                """
                code.add(line: restoreARG)
                let restoreLCL = """
                                @R14
                                D=M
                                @4
                                A=D-A
                                D=M
                                @LCL
                                M=D
                                """
                code.add(line: restoreLCL)
                let gotoReturnAddress = """
                                        @R15
                                        A=M
                                        0;JMP
                                        """
                code.add(line: gotoReturnAddress)
                
                assemblyCommands = code
            }
        }
        outputFile.write(line: assemblyCommands)
    }
    
    func closeFile() {
        outputFile.closeFile()
    }
}
