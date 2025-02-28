//
//  VMFileReader.swift
//  jackvm
//
//  Created by Tiago Lopes on 09/01/25.
//

import ArgumentParser

@main
struct JackVM: ParsableCommand {
    @Argument(
        help: "Path to a .vm file or to a directory containing multiple .vm files."
    )
    var vmFilePath: String
    
    @Argument(
        help: "Path to the .asm file being generated. If nil, output will be in out.asm file."
    )
    var asmOutputPath: String?

    func run() throws {
        let io = FileIO()
        let translator = Translator()
        
        let asm = try io.contents(at: vmFilePath)
            .map { try Parser(content: $0).parse() }
            .map { translator.translate(commands: $0) }
            .reduce("") { partialResult, translatedArm in
                partialResult + translatedArm
            }
        
        io.write(asm, to: asmOutputPath ?? "out.asm")
    }
}
