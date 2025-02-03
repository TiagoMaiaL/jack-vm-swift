//
//  Parser.swift
//  jackvm
//
//  Created by Tiago Lopes on 09/01/25.
//

struct Parser {
    func parse(content: FileIO.VMContent) throws -> [Command] {
        try content.map(makeCommand)
    }
    
    private func makeCommand(from line: String) throws(Error) -> Command {
        let components = line.components(separatedBy: .whitespaces)
        
        guard !components.isEmpty else { throw .emptyLine }
        
        guard let keyword = Keyword(rawValue: components[0]) else {
            throw .unexpectedKeyword(text: components[0])
        }
        
        let command: Command
        
        switch keyword {
        case .push, .pop:
            guard components.count == 3 else {
                throw .incompleteMemoryCommand(text: components.joined(separator: " "))
            }
            
            guard let operation = MemoryOperation(rawValue: keyword.rawValue) else {
                preconditionFailure("Couldn't represent memory operation.")
            }
            
            guard let segmentKeyword = Keyword(rawValue: components[1]),
                  Keyword.memorySegments.contains(segmentKeyword),
                  let segment = MemorySegment(rawValue: segmentKeyword.rawValue) else {
                throw .unexpectedMemorySegment(text: components[1])
            }
            
            guard let memoryIndex = Int(components[2]) else {
                throw .unexpectedMemoryIndex(text: components[2])
            }
            
            command = MemoryAccess(
                operation: operation,
                segment: segment,
                index: memoryIndex
            )
            
        case .add, .sub, .neg, .eq, .gt, .lt, .and, .or, .not:
            guard let operation = ArithmeticOperation(rawValue: keyword.rawValue) else {
                preconditionFailure("Couldn't represent arithmetic operation.")
            }
            
            command = Arithmetic(operation: operation)
            
        default:
            throw .unexpectedCommand(text: keyword.rawValue)
        }
        
        return command
    }
    
    fileprivate enum Keyword: String {
        // Memory
        case push
        case pop
        
        // Memory Segments
        case argument
        case local
        case `static`
        case constant
        case this
        case that
        case pointer
        case temp
        
        // Arithmetic
        case add
        case sub
        case neg
        case eq
        case gt
        case lt
        case and
        case or
        case not
        
        static var memorySegments: [Self] {
            [
                .argument,
                .local,
                .static,
                .constant,
                .this,
                .that,
                .pointer,
                .temp
            ]
        }
    }
    
    enum Error: Swift.Error {
        case emptyLine
        case unexpectedKeyword(text: String)
        case unexpectedCommand(text: String)
        case incompleteMemoryCommand(text: String)
        case unexpectedMemorySegment(text: String)
        case unexpectedMemoryIndex(text: String)
    }
}
