//
//  Command.swift
//  jackvm
//
//  Created by Tiago Lopes on 10/01/25.
//

// MARK: - Command Protocols

protocol Command: CustomStringConvertible {}

// MARK: Arithmetic

protocol ArithmeticCommand: Command {
    var operation: ArithmeticOperation { get }
}

enum ArithmeticOperation: String {
    case add
    case sub
    case neg
    case eq
    case gt
    case lt
    case and
    case or
    case not
}

// MARK: Memory

protocol MemoryCommand: Command {
    var fileName: String? { get }
    var operation: MemoryOperation { get }
    var segment: MemorySegment { get }
    var index: Int { get }
}

extension MemoryCommand {
    var staticSymbol: String? {
        guard segment == .constant, let fileName else {
            return nil
        }
        return "\(fileName).\(index)"
    }
}

enum MemoryOperation: String {
    case push
    case pop
}

enum MemorySegment: String {
    case argument
    case local
    case `static`
    case constant
    case this
    case that
    case pointer
    case temp
}

// MARK: ProgramFlow

protocol ProgramFlowCommand: Command {
    var operation: ProgramFlowOperation { get }
    var symbol: String { get }
    var wrappingFunctionName: String? { get }
}

extension ProgramFlowCommand {
    var uniqueSymbol: String? {
        guard let wrappingFunctionName else {
            return nil
        }
        return "\(wrappingFunctionName)$\(symbol)"
    }
}

enum ProgramFlowOperation: String {
    case label
    case goTo   = "goto"
    case ifGoTo = "if-goto"
}

// MARK: Function

protocol FunctionCommand: Command {
    var operation: FunctionOperation { get }
    var name: String? { get }
    /// The number of local variables (when the command is a declaration),
    /// or the number of arguments provided (when the command is an invocation),
    /// or nil, if this is a return command.
    var count: Int? { get }
}

enum FunctionOperation: String {
    case declare    = "function"
    case invoke     = "call"
    case `return`   = "return"
}

// MARK: - Concrete types

struct Arithmetic: ArithmeticCommand {
    var description: String { operation.rawValue }
    let operation: ArithmeticOperation
}

struct MemoryAccess: MemoryCommand {
    var description: String { "\(operation.rawValue) \(segment.rawValue) \(index)" }
    let fileName: String?
    let operation: MemoryOperation
    let segment: MemorySegment
    let index: Int
}

struct ProgramFlow: ProgramFlowCommand {
    var description: String { "\(operation.rawValue) \(symbol)"}
    let operation: ProgramFlowOperation
    let symbol: String
    let wrappingFunctionName: String?
}

struct Function: FunctionCommand {
    var description: String {
        var description = operation.rawValue
        
        if let name {
            description += " \(name)"
        }
        
        if let count {
            description += " \(count)"
        }
        
        return description
    }
    var operation: FunctionOperation
    var name: String?
    var count: Int?
}
