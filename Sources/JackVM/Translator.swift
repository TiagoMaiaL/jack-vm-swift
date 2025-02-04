//
//  Translator.swift
//  jackvm
//
//  Created by Tiago Lopes on 11/01/25.
//

typealias ASM = String

struct Translator {
    nonisolated(unsafe) private static var labelId = 0
    private let stackBase = 256 // To 2047
    private let tempSegmentBase = 5
    // FIXME: Arbitrary value used to complete 1st part.
    private let localSegmentBase = 300
    private let argumentSegmentBase = 400
    private let thisSegmentBase = 3000
    private let thatSegmentBase = 3010
    
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
                case let memoryAccess as MemoryCommand:
                    asmEquivalent = translate(memoryAccess)
                    
                case let arithmetic as ArithmeticCommand:
                    asmEquivalent = translate(arithmetic)
                    
                default:
                    preconditionFailure()
                }
                
                return asmEquivalent
            }
            .reduce("") { "\($0)\n\($1)" }
        
        return bootstrapCode + commandsCode + terminationCode
    }
    
    private func translate(_ memoryAccess: MemoryCommand) -> ASM {
        var asm = ""
        
        switch memoryAccess.operation {
        case .push:
            switch memoryAccess.segment {
            case .argument:
                // let a = ARGUMENT[index]
                // RAM[SP] = a
                // SP++
                asm += """
                @\(argumentSegmentBase + memoryAccess.index)
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .local:
                // let a = LOCAL[index]
                // RAM[SP] = a
                // SP++
                asm += """
                @\(localSegmentBase + memoryAccess.index)
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .this:
                // let a = THIS[index]
                // RAM[SP] = a
                // SP++
                asm += """
                @\(thisSegmentBase + memoryAccess.index)
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .that:
                // let a = THAT[index]
                // RAM[SP] = a
                // SP++
                asm += """
                @\(thatSegmentBase + memoryAccess.index)
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .constant:
                // let c
                // RAM[SP] = c
                // SP++
                asm += """
                @\(memoryAccess.constant)
                D=A
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .temp:
                // let d = TEMP[index]
                // RAM[SP] = d
                // SP++
                asm += """
                @R\(tempSegmentBase + memoryAccess.index)
                D=M
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
            switch memoryAccess.segment {
            case .argument:
                // D = RAM[SP-1]
                // ARGUMENT[index] = D
                // SP--
                asm += """
                @SP
                A=M-1
                D=M
                @\(argumentSegmentBase + memoryAccess.index)
                M=D
                @SP
                M=M-1
                """
                
            case .local:
                // D = RAM[SP-1]
                // LOCAL[index] = D
                // SP--
                asm += """
                @SP
                A=M-1
                D=M
                @\(localSegmentBase + memoryAccess.index)
                M=D
                @SP
                M=M-1
                """
                
            case .static:
                break
                
            case .this:
                // let d = RAM[SP-1]
                // THIS[index] = d
                // SP--
                asm += """
                @SP
                A=M-1
                D=M
                @\(thisSegmentBase + memoryAccess.index)
                M=D
                @SP
                M=M-1
                """
                
            case .that:
                // let d = RAM[SP-1]
                // THAT[index] = d
                // SP--
                asm += """
                @SP
                A=M-1
                D=M
                @\(thatSegmentBase + memoryAccess.index)
                M=D
                @SP
                M=M-1
                """
                
            case .pointer:
                break
                
            case .temp:
                // let d = RAM[SP-1]
                // TEMP[index] = d
                // SP--
                asm += """
                @SP
                A=M-1
                D=M
                @R\(tempSegmentBase + memoryAccess.index)
                M=D
                @SP
                M=M-1
                """

            case .constant:
                preconditionFailure() // TODO: Throw an error
            }
            
            break
        }
        
        return asm
    }
    
    private func translate(_ arithmetic: ArithmeticCommand) -> ASM {
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

fileprivate extension MemoryCommand {
    var constant: Int { index }
}
