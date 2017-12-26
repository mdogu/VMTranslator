//
//  Parser.swift
//  VMTranslator
//
//  Created by Murat Dogu on 27.12.2017.
//  Copyright © 2017 Murat Dogu. All rights reserved.
//

import Foundation

class Parser {
    
    let inputFile: FileHandle
    
    init(inputFileURL: URL) throws {
        self.inputFile = try FileHandle(forReadingFrom: inputFileURL)
    }
    
    func closeFile() {
        inputFile.closeFile()
    }
}
