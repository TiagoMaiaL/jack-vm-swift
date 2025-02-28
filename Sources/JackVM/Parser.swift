//
//  Parser.swift
//  jackvm
//
//  Created by Tiago Lopes on 09/01/25.
//

struct Parser {
    private let fileName: String
    private let lines: [String]
    
    init(content: FileIO.VMContent) {
        self.fileName = content.fileName
        self.lines = content.commands
    }
    
    func parse() throws -> [Command] {
        return try lines.map(makeCommand)
    }
    
    private func makeCommand(line: String) throws(Error) -> Command {
        let components = line
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
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
                fileName: fileName,
                operation: operation,
                segment: segment,
                index: memoryIndex
            )
            
        case .add, .sub, .neg, .eq, .gt, .lt, .and, .or, .not:
            guard let operation = ArithmeticOperation(rawValue: keyword.rawValue) else {
                preconditionFailure("Couldn't represent arithmetic operation.")
            }
            
            command = Arithmetic(operation: operation)
            
        case .label, .goTo, .ifGoTo:
            guard components.count == 2 else {
                throw .incompleteProgramFlowCommand(text: components.joined(separator: " "))
            }
            
            guard let operation = ProgramFlowOperation(rawValue: keyword.rawValue) else {
                preconditionFailure("Couldn't represent program-flow operation.")
            }
            
            let symbol = components[1]
            command = ProgramFlow(operation: operation, symbol: symbol)
            
        case .function, .call, .return:
            guard components.count == 1 || components.count == 3 else {
                throw .incompleteFunctionCommand(text: components.joined(separator: " "))
            }
            
            let operation: FunctionOperation
            
            switch keyword {
            case .function:
                operation = .declare
                
            case .call:
                operation = .invoke
                
            case .return:
                operation = .return
            
            default: preconditionFailure("Couldn't represent function operation.")
            }
            
            if operation == .return {
                command = Function(operation: operation)
                break
            }
            
            let name = components[1]
            
            guard let count = Int(components[2]) else {
                throw .unexpectedFunctionCount(text: components[2])
            }
            
            command = Function(
                operation: operation,
                name: name,
                count: count
            )
            
        default:
            preconditionFailure("Unexpected keyword at command specifier: \(keyword)")
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
        
        // Program Flow
        case label
        case goTo   = "goto"
        case ifGoTo = "if-goto"
        
        // Function
        case function
        case call
        case `return`
        
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
        case incompleteProgramFlowCommand(text: String)
        case incompleteFunctionCommand(text: String)
        case unexpectedFunctionCount(text: String)
    }
}
