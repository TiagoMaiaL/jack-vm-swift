//
//  Translator.swift
//  jackvm
//
//  Created by Tiago Lopes on 11/01/25.
//

struct Translator {
    typealias ASM = String
    
    func translate(commands: [Command]) -> ASM {
        // For each command
        commands
            .map { command in
                switch command.type {
                case .memoryAccess(let operation):
                    return translateMemoryAccess(
                        command: command,
                        operation: operation
                    )
                    
                case .arithmetic(let operation):
                    return translateArithmetic(operation: operation)
                }
            }
            .reduce("") { "\($0)\n\($1)" }
    }
    
    private func translateMemoryAccess(
        command: Command,
        operation: MemoryOperation
    ) -> ASM {
        guard let fOperand = command.firstOperand,
              let sOperand = command.secondOperand else {
            preconditionFailure("Operands must be set when translating memory access.")
        }
        
        var asm = ""
        
        switch fOperand {
        case "constant":
            asm += "@\(sOperand)\n"
            asm += "D=A"
            // TODO: Determine how not to override registers
            
        default:
            preconditionFailure("Unexpected memory segment: \(fOperand)")
        }
        
        return asm
    }
    
    private func translateArithmetic(operation: ArithmeticOperation) -> ASM {
        let asm: ASM
        
        switch operation {
        case .add:
            asm = "D=D+A"
            
        case .sub:
            asm = "D=D-A"
            
        case .neg:
            asm = "D=-D"
            
        case .eq:
            // subtract a - b, if result is 0, they are eq
            // if result is != 0, they are not eq
            // How to compare numbers in this case?
            // Consider JMP
            asm = ""
            
        case .gt:
            asm = ""
            
        case .lt:
            asm = ""
            
        case .and:
            asm = "D=D&A"
            
        case .or:
            asm = "D=D|A"
            
        case .not:
            asm = "D=!D"
        }

        return asm
    }
}
