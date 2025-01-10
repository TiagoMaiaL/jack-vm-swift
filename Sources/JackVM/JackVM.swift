//
//  VMFileReader.swift
//  jackvm
//
//  Created by Tiago Lopes on 09/01/25.
//

import ArgumentParser

@main
struct JackVM: ParsableCommand {
    // TODO: Add description to each argument.
    @Argument var vmFilePath: String
    @Argument var asmOutputPath: String

    func run() throws {
        let fileReader = VMFileReader()
        let content = try fileReader.contents(fromFolderAt: vmFilePath)
        let commands = try Parser().parse(content: content)
        debugPrint(commands)
    }
}
