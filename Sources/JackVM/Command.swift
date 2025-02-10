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
    var operation: MemoryOperation { get }
    var segment: MemorySegment { get }
    var index: Int { get }
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
}

enum ProgramFlowOperation: String {
    case label
    case goTo   = "goto"
    case ifGoTo = "if-goto"
}

// MARK: Function

protocol FunctionCommand: Command {
    var operation: FunctionOperation { get }
    var name: String { get }
    /// The number of local variables (when the command is a declaration),
    /// or the number of arguments provided (when the command is an invocation),
    var count: Int { get }
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
    let operation: MemoryOperation
    let segment: MemorySegment
    let index: Int
}

struct ProgramFlow: ProgramFlowCommand {
    var operation: ProgramFlowOperation
    var symbol: String
    var description: String
}

struct Function: FunctionCommand {
    var operation: FunctionOperation
    var name: String
    var count: Int
    var description: String
}
