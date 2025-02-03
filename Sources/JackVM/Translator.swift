//
//  Translator.swift
//  jackvm
//
//  Created by Tiago Lopes on 11/01/25.
//

typealias ASM = String

struct Translator {
    nonisolated(unsafe) private static var labelId = 0
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
                let asmEquivalent: ASM
                
                switch command {
                case let memoryAccess as MemoryAccess:
                    asmEquivalent = translate(memoryAccess)
                    
                case let arithmetic as Arithmetic:
                    asmEquivalent = translate(arithmetic)
                    
                default:
                    preconditionFailure()
                }
                
                return asmEquivalent
            }
            .reduce("") { "\($0)\n\($1)" }
        
        return bootstrapCode + commandsCode + terminationCode
    }
    
    private func translate(_ memoryAccess: MemoryAccess) -> ASM {
        var asm = ""
        
        switch memoryAccess.operation {
        case .push:
            switch memoryAccess.segment {
            case .constant:
                // let c
                // RAM[SP] = c
                // SP++
                asm += """
                @\(memoryAccess.index)
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
    
    private func translate(_ arithmetic: Arithmetic) -> ASM {
        var asm: ASM = ""
        
        switch arithmetic.operation {
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
            // if d == 0
            //     RAM[SP-1] = -1
            // else
            //     RAM[SP-1] = 0
            asm += """
            @SP
            A=M-1
            D=M
            @SP
            M=M-1
            A=M-1
            D=M-D
            @TEST_EQ_\(Self.labelId)
            D;JEQ
            D=0
            @TEST_EQ_END_\(Self.labelId)
            0;JMP
            (TEST_EQ_\(Self.labelId))
            D=-1
            (TEST_EQ_END_\(Self.labelId))
            @SP
            A=M-1
            M=D
            """
            Self.labelId += 1

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
            @TEST_GT_\(Self.labelId)
            D;JGT
            D=0
            @TEST_GT_END_\(Self.labelId)
            0;JMP
            (TEST_GT_\(Self.labelId))
            D=-1
            (TEST_GT_END_\(Self.labelId))
            @SP
            A=M-1
            M=D
            """
            Self.labelId += 1
            
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
            @TEST_LT_\(Self.labelId)
            D;JLT
            D=0
            @TEST_LT_END_\(Self.labelId)
            0;JMP
            (TEST_LT_\(Self.labelId))
            D=-1
            (TEST_LT_END_\(Self.labelId))
            @SP
            A=M-1
            M=D
            """
            Self.labelId += 1
            
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
