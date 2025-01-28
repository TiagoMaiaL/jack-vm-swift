//
//  Translator.swift
//  jackvm
//
//  Created by Tiago Lopes on 11/01/25.
//

struct Translator {
    typealias ASM = String
    
    private let stackBase = 256
    
    var bootstrapCode: ASM {
        """
        @\(stackBase)
        D=A
        @SP
        M=D
        """
        // TODO: initialize local and arg memory segments.
    }
    
    func translate(commands: [Command]) -> ASM {
        bootstrapCode + commands
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
        
        switch operation {
        case .push:
            switch fOperand {
            case "constant":
                // let c
                // RAM[SP] = c
                // SP++
                asm += """
                @\(sOperand)
                D=A
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            default:
                preconditionFailure()
            }
            
        case .pop:
            preconditionFailure()
            break
        }
        
        return asm
    }
    
    private func translateArithmetic(operation: ArithmeticOperation) -> ASM {
        var asm: ASM = ""
        
        switch operation {
        case .add:
            // let d = RAM[SP]
            // SP--
            // d += RAM[SP]
            // RAM[SP] = d
            asm += """
            @SP
            A=M
            D=M
            @SP
            M=M-1
            A=M
            D=D+M
            M=D
            """
            
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
