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
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // d = a + b
            // RAM[SP-1] = d
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
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // d = a - b
            // RAM[SP - 1] = d
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
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // d = a - b
            // d = !d
            // RAM[SP-1] = d
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=M-D
            D=!D
            M=D
            """

        case .gt:
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // let res = a - b
            // if res > 0
            //     RAM[SP] = 1
            // else
            //     RAM[SP] = 0
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=M-D
            @TEST_GT
            D;JGT
            D=0
            @TEST_GT_END
            0;JMP
            (TEST_GT)
            D=-1
            (TEST_GT_END)
            @SP
            A=M-1
            M=D
            """
            
        case .lt:
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // let res = a - b
            // if res < 0
            //     RAM[SP] = 1
            // else
            //     RAM[SP] = 0
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=M-D
            @TEST_LT
            D;JLT
            D=0
            @TEST_LT_END
            0;JMP
            (TEST_LT)
            D=-1
            (TEST_LT_END)
            @SP
            A=M-1
            M=D
            """
            
        case .and:
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // d = a & d
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
            // let b = RAM[SP-1]
            // SP--
            // let a = RAM[SP-1]
            // d = a | d
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
