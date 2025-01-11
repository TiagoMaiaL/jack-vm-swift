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
        let command: Command
        let type: Command.`Type`
        var firstOperand: String?
        var secondOperand: String?
        
        let components = line.components(separatedBy: .whitespaces)
        
        guard !components.isEmpty else { throw .emptyLine }
        
        guard let keyword = Keyword(rawValue: components[0]) else {
            throw .unexpectedKeyword(text: components[0])
        }
        
        switch keyword {
        case .push, .pop:
            guard components.count == 3 else {
                throw .incompleteMemoryCommand(text: components.joined(separator: " "))
            }
            
            guard let operation = MemoryOperation(rawValue: keyword.rawValue) else {
                preconditionFailure("Couldn't represent memory operation.")
            }
            
            type = .memoryAccess(operation: operation)

            guard let segment = Keyword(rawValue: components[1]),
                  Keyword.memorySegments.contains(segment) else {
                throw .unexpectedMemorySegment(text: components[1])
            }
            
            firstOperand = segment.rawValue
            
            guard let memoryIndex = Int(components[2]) else {
                throw .unexpectedMemoryIndex(text: components[2])
            }
            
            secondOperand = memoryIndex.description
            
        case .add, .sub, .neg, .eq, .gt, .lt, .and, .or, .not:
            guard let operation = ArithmeticOperation(rawValue: keyword.rawValue) else {
                preconditionFailure("Couldn't represent arithmetic operation.")
            }
            
            type = .arithmetic(operation: operation)

        default:
            throw .unexpectedCommand(text: keyword.rawValue)
        }
        
        command = .init(
            type: type,
            firstOperand: firstOperand,
            secondOperand: secondOperand
        )
        
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
