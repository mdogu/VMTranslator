//
//  main.swift
//  VMTranslator
//
//  Created by Murat Dogu on 26.12.2017.
//  Copyright © 2017 Murat Dogu. All rights reserved.
//

import Foundation

guard CommandLine.argc == 2 else {
    Console.error("Usage: VMTranslator source")
    exit(0)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let inputFiles: [URL]
let outputFileName: String

if inputURL.lastPathComponent.ends(with: ".vm") {
    guard FileManager.default.fileExists(atPath: inputURL.path) else {
        Console.error("File does not exist")
        exit(0)
    }
    inputFiles = [inputURL]
    outputFileName = inputURL.lastPathComponent.replacingOccurrences(of: ".vm", with: "")
} else {
    if FileManager.default.isDirectory(url: inputURL) {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: [])
            guard files.count > 0 else {
                Console.error("Empty Directory")
                exit(0)
            }
            let inputs = files.filter { $0.lastPathComponent.ends(with: ".vm") }
            guard inputs.count > 0 else {
                Console.error("Directory contains no .vm files")
                exit(0)
            }
            inputFiles = inputs
            outputFileName = inputURL.lastPathComponent
        } catch {
            Console.error(error.localizedDescription)
            exit(0)
        }
    } else {
        Console.error("Argument should be .vm file or a directory containing .vm file(s)")
        exit(0)
    }
}


