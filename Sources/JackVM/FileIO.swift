//
//  FileIO.swift
//  jackvm
//
//  Created by Tiago Lopes on 09/01/25.
//

import Foundation
import RegexBuilder

// MARK: - VM input

struct FileIO {
    typealias VMContent = Array<String>
    private let fileManager = FileManager.default
}

extension FileIO {
    func isDirectory(filePath: String) throws(FileError) -> Bool {
        let isDir = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        isDir.initialize(to: false)
        
        defer { isDir.deallocate() }
        
        guard fileManager.fileExists(atPath: filePath, isDirectory: isDir) else {
            throw .fileNotFound
        }
        
        return isDir.pointee.boolValue
    }
    
    func files(at filePath: String) throws(FileError) -> [String] {
        guard try isDirectory(filePath: filePath) else {
            throw .notDirectory
        }
        
        do {
            return try fileManager.contentsOfDirectory(atPath: filePath)
        } catch {
            throw .invalidContent
        }
    }
    
    func isVmFile(name: String) -> Bool {
        let nameComponents = name.components(separatedBy: ".")
        return !nameComponents.isEmpty && nameComponents.last == "vm"
    }
    
    func contents(fromDirectoryAt path: String) throws(FileError) -> [VMContent] {
        // TODO: Refactor to use map, filter, and map like so:
        //return try files(at: path)
        //    .filter { isVmFile(name: $0) }
        //    .map { try contents(fromFolderAt: $0) }
        
        let vmFiles = try files(at: path).filter { isVmFile(name: $0) }
        var dirContents = [VMContent]()
        
        for vmFilePath in vmFiles {
            let fileCommands = try contents(fromFolderAt: vmFilePath)
            dirContents.append(fileCommands)
        }
        
        return dirContents
    }
    
    func contents(fromFolderAt path: String) throws(FileError) -> VMContent {
        guard let data = fileManager.contents(atPath: path) else {
            throw .fileNotFound
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            throw .invalidContent
        }
        
        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { $0.trimmingCharacters(in: .controlCharacters) }
            .map(clearingComments)
            .filter { !$0.isEmpty }
    }
    
    private func clearingComments(from line: String) -> String {
        var line = line
        
        let commentRegex = Regex {
            Capture {
                OneOrMore {
                    "//"
                }
                ZeroOrMore(.anyNonNewline)
            }
        }
            
        if let match = line.firstMatch(of: commentRegex) {
            line.removeSubrange(match.range)
        }
        
        return line
    }
}

// MARK: - ASM output

extension FileIO {
    func write(_ asm: ASM, to path: String) {
        FileManager().createFile(atPath: path, contents: asm.data(using: .ascii))
    }
}

// MARK: - Errors

extension FileIO {
    enum FileError: Error {
        case fileNotFound
        case invalidContent
        case notDirectory
    }
}
