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
    
    init(outputFileURL: URL) throws {
        if FileManager.default.fileExists(atPath: outputFileURL.path) == false {
            FileManager.default.createFile(atPath: outputFileURL.path, contents: nil, attributes: nil)
        }
        self.outputFile = try FileHandle(forUpdating: outputFileURL)
    }
    
    func write(command: Command) {
        switch command {
        case .arithmeticLogical(let instruction):
            switch instruction {
            case .add:
                break
            case .sub:
                break
            case .neg:
                break
            case .eq:
                break
            case .gt:
                break
            case .lt:
                break
            case .and:
                break
            case .or:
                break
            case .not:
                break
            }
        case .memoryAccess(let instruction):
            switch instruction {
            case let .push(segment, index):
                switch segment {
                case .argument:
                    break
                case .local:
                    break
                case .statik:
                    break
                case .constant:
                    break
                case .this:
                    break
                case .that:
                    break
                case .pointer:
                    break
                case .temp:
                    break
                }
            case let .pop(segment, index):
                switch segment {
                case .argument:
                    break
                case .local:
                    break
                case .statik:
                    break
                case .constant:
                    break
                case .this:
                    break
                case .that:
                    break
                case .pointer:
                    break
                case .temp:
                    break
                }
            }
        case .programFlow:
            break
        case .functionCalling:
            break
        }
    }
    
    func closeFile() {
        outputFile.closeFile()
    }
}
