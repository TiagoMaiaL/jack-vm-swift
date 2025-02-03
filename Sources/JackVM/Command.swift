//
//  Command.swift
//  jackvm
//
//  Created by Tiago Lopes on 10/01/25.
//

protocol Command: CustomStringConvertible {}

protocol ArithmeticCommand: Command {
    var operation: ArithmeticOperation { get }
}

protocol MemoryCommand: Command {
    var operation: MemoryOperation { get }
    var segment: MemorySegment { get }
    var index: Int { get }
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
