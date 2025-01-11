//
//  Command.swift
//  jackvm
//
//  Created by Tiago Lopes on 10/01/25.
//

struct Command {
    enum `Type` {
        case arithmetic(operation: ArithmeticOperation)
        case memoryAccess(operation: MemoryOperation)
    }
    
    let type: Type
    let firstOperand: String?
    let secondOperand: String?
}

extension Command.`Type`: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .arithmetic(let operation):
            return operation.rawValue
        
        case .memoryAccess(let operation):
            return operation.rawValue
        }
    }
}

extension Command: CustomDebugStringConvertible {
    var debugDescription: String {
        var description = "\(type.debugDescription)"
        
        if let firstOperand { description += " \(firstOperand)"}
        if let secondOperand { description += " \(secondOperand)"}

        return description
    }
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
