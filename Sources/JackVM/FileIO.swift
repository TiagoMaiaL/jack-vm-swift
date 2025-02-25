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
    
    public func contents(at path: String) throws(FileError) -> [VMContent] {
        if try isDirectory(filePath: path) {
            return try contents(fromDirectoryAt: path)
        } else {
            return [try contents(fromFileAt: path)]
        }
    }
}

extension FileIO {
    private func isDirectory(filePath: String) throws(FileError) -> Bool {
        let isDir = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        isDir.initialize(to: false)
        
        defer { isDir.deallocate() }
        
        guard fileManager.fileExists(atPath: filePath, isDirectory: isDir) else {
            throw .fileNotFound
        }
        
        return isDir.pointee.boolValue
    }
    
    private func files(at filePath: String) throws(FileError) -> [String] {
        guard try isDirectory(filePath: filePath) else {
            throw .notDirectory
        }
        
        do {
            return try fileManager
                .contentsOfDirectory(atPath: filePath)
                .map { "./\(filePath)/\($0)" }
        } catch {
            throw .invalidContent
        }
    }
    
    private func isVmFile(name: String) -> Bool {
        let nameComponents = name.components(separatedBy: ".")
        return !nameComponents.isEmpty && nameComponents.last == "vm"
    }
    
    private func contents(fromDirectoryAt path: String) throws(FileError) -> [VMContent] {
        let vmFiles = try files(at: path).filter { isVmFile(name: $0) }
        var dirContents = [VMContent]()
        
        for vmFilePath in vmFiles {
            dirContents.append(try contents(fromFileAt: vmFilePath))
        }
        
        return dirContents
    }
    
    private func contents(fromFileAt path: String) throws(FileError) -> VMContent {
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
