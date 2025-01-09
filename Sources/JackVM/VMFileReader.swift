//
//  VMFileReader.swift
//  jackvm
//
//  Created by Tiago Lopes on 09/01/25.
//

import Foundation
import RegexBuilder

struct VMFileReader {
    typealias Content = Array<String>
    
    func contents(fromFolderAt path: String) throws(FileError) -> Content {
        guard let data = FileManager().contents(atPath: path) else {
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
    
    // TODO: Add method to get the contents from all VM files within a folder.
    
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

extension VMFileReader {
    enum FileError: Error {
        case fileNotFound
        case invalidContent
    }
}
