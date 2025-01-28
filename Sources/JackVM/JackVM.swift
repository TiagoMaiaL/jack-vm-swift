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
        help: "The path to a .vm file or directory contaninig multiple ones."
    )
    var vmFilePath: String
    
    @Argument(
        help: "The path to .hack file being generated."
    )
    var asmOutputPath: String

    func run() throws {
        let io = FileIO()
        let parser = Parser()
        let translator = Translator()

        let content = try io.contents(fromFolderAt: vmFilePath)
        let commands = try parser.parse(content: content)
        let asm = translator.translate(commands: commands)
        
        io.write(asm, to: asmOutputPath)
    }
}
