//
//  Translator.swift
//  jackvm
//
//  Created by Tiago Lopes on 11/01/25.
//

typealias ASM = String

struct Translator {
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
    
    var terminationCode: ASM {
        """
        (END)
        @END
        0;JMP
        """
    }
    
    func translate(commands: [Command]) -> ASM {
        let commandsCode = commands
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
        
        return bootstrapCode + commandsCode + terminationCode
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
            // let d = RAM[SP-1]
            // SP--
            // d += RAM[SP-1]
            // RAM[SP] = d
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=D+M
            M=D
            """
            
        case .sub:
            // let d = RAM[SP-1]
            // SP--
            // d -= RAM[SP-1]
            // RAM[SP] = d
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=M-D
            M=D
            """
            
        case .neg:
            // RAM[SP-1] = -RAM[SP-1]
            asm += """
            @SP
            A=M-1
            M=-M
            """
            
        case .eq:
            // TODO:
            asm = ""
            
        case .gt:
            // TODO:
            asm = ""
            
        case .lt:
            // TODO:
            asm = ""
            
        case .and:
            // let d = RAM[SP-1]
            // SP--
            // d = RAM[SP-1] & d
            // RAM[SP-1] = d
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=D&M
            M=D
            """
            
        case .or:
            // let d = RAM[SP-1]
            // SP--
            // d = RAM[SP-1] | d
            // RAM[SP-1] = d
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=D|M
            M=D
            """
            
        case .not:
            // RAM[SP-1] = !RAM[SP-1]
            asm += """
            @SP
            A=M-1
            M=!M
            """
        }
        
        return asm
    }
}
