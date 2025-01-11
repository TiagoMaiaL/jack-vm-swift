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
        let fileReader = FileIO()
        let content = try fileReader.contents(fromFolderAt: vmFilePath)
        let commands = try Parser().parse(content: content)
        var translator = Translator()
        let asm = translator.translate(commands: commands)
        debugPrint(asm)
    }
}
