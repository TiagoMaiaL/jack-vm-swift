//
//  Translator.swift
//  jackvm
//
//  Created by Tiago Lopes on 11/01/25.
//

typealias ASM = String

struct Translator {
    nonisolated(unsafe) private static var labelId = 0
    nonisolated(unsafe) private static var shouldIncludeBoostrapCode = true
    private let stackBase = 256 // To 2047
    private let pointerSegmentBase = 3
    private let tempSegmentBase = 5
        
    var bootstrapCode: ASM {
        """
        // bootstrap block
        @\(stackBase)
        D=A
        @SP
        M=D
        \(translate(SynteticFunction.callSysInit))
        """
    }
    
    func translate(commands: [Command]) -> ASM {
        let commandsCode = commands
            .map { command in
                var asmEquivalent: ASM = "// \(command)\n"
                
                switch command {
                case let memoryAccess as MemoryCommand:
                    asmEquivalent += translate(memoryAccess)
                    
                case let arithmetic as ArithmeticCommand:
                    asmEquivalent += translate(arithmetic)
                    
                case let programFlow as ProgramFlowCommand:
                    asmEquivalent += translate(programFlow)
                    
                case let function as FunctionCommand:
                    asmEquivalent += translate(function)
                    
                default:
                    preconditionFailure("Unhandled type of command.")
                }
                
                return asmEquivalent
            }
            .reduce("") { "\($0)\n\($1)" }
        
        if Self.shouldIncludeBoostrapCode {
            Self.shouldIncludeBoostrapCode = false
            return bootstrapCode + commandsCode
        } else {
            return commandsCode
        }
    }
    
    private func translate(_ memoryAccess: MemoryCommand) -> ASM {
        var asm = ""
        
        switch memoryAccess.operation {
        case .push:
            switch memoryAccess.segment {
            case .argument:
                // let d = RAM[ARG + index]
                // RAM[SP] = d
                // SP++
                asm += """
                @ARG
                D=M
                @\(memoryAccess.index)
                A=D+A
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .local:
                // let c = RAM[LCL + index]
                // RAM[SP] = d
                // SP++
                asm += """
                @LCL
                D=M
                @\(memoryAccess.index)
                A=D+A
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .this:
                // let thisBase = RAM[THIS]
                // let addr = thisBase + index
                // let val = RAM[addr]
                // RAM[SP] = val
                // SP++
                asm += """
                @THIS
                D=M
                @\(memoryAccess.index)
                A=D+A
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .that:
                // let thatBase = RAM[THAT]
                // let addr = thatBase + index
                // let val = RAM[addr]
                // RAM[SP] = val
                // SP++
                asm += """
                @THAT
                D=M
                @\(memoryAccess.index)
                A=D+A
                D=M
                @SP
                A=M
                M=D
                @SP
                M=M+1
                """
                
            case .static:
                asm += """
                @static.\(memoryAccess.index)
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
            
            case .pointer:
                // let d = POINTER[index]
                // RAM[SP] = d
                // SP++
                asm += """
                @\(pointerSegmentBase + memoryAccess.index)
                D=M
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
            }
            
        case .pop:
            switch memoryAccess.segment {
            case .argument:
                // let argBase = RAM[ARG]
                // let addr = argBase + index
                // RAM[13] = addr // R13 points to the address
                // SP--
                // let d = RAM[SP]
                // RAM[RAM[13]] = d
                asm += """
                @ARG
                D=M
                @\(memoryAccess.index)
                D=D+A
                @R13
                M=D
                @SP
                M=M-1
                A=M
                D=M
                @R13
                A=M
                M=D
                """
                
            case .local:
                // let lclBase = RAM[LCL]
                // let addr = lclBase + index
                // RAM[13] = addr // R13 points to the address
                // SP--
                // let d = RAM[SP]
                // RAM[RAM[13]] = d
                asm += """
                @LCL
                D=M
                @\(memoryAccess.index)
                D=D+A
                @R13
                M=D
                @SP
                M=M-1
                A=M
                D=M
                @R13
                A=M
                M=D
                """
                
            case .static:
                // D = RAM[SP-1]
                // RAM[static_addr] = D
                // SP--
                // TODO: Use the file name and var as the label
                asm += """
                @SP
                M=M-1
                A=M
                D=M
                @static.\(memoryAccess.index)
                M=D
                """
                
            case .this:
                // let thisBase = RAM[THIS]
                // let addr = thisBase + index
                // RAM[13] = addr // R13 points to the address
                // SP--
                // let d = RAM[SP]
                // RAM[RAM[13]] = d
                asm += """
                @THIS
                D=M
                @\(memoryAccess.index)
                D=D+A
                @R13
                M=D
                @SP
                M=M-1
                A=M
                D=M
                @R13
                A=M
                M=D
                """
                
            case .that:
                // let thisBase = RAM[THIS]
                // let addr = thisBase + index
                // RAM[13] = addr // R13 points to the address
                // SP--
                // let d = RAM[SP]
                // RAM[RAM[13]] = d
                asm += """
                @THAT
                D=M
                @\(memoryAccess.index)
                D=D+A
                @R13
                M=D
                @SP
                M=M-1
                A=M
                D=M
                @R13
                A=M
                M=D
                """
                
            case .pointer:
                asm += """
                @SP
                M=M-1
                A=M
                D=M
                @\(pointerSegmentBase + memoryAccess.index)
                M=D
                """
                
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
                preconditionFailure("Popping a constant is unsupported.")
            }
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
    
    private func translate(_ programFlow: ProgramFlowCommand) -> ASM {
        var asm = ""
        
        switch programFlow.operation {
        case .label:
            asm += """
            (\(programFlow.symbol))
            """
            
        case .goTo:
            asm += """
            @\(programFlow.symbol)
            0;JMP
            """
            
        case .ifGoTo:
            asm += """
            @SP
            M=M-1
            A=M
            D=M
            @\(programFlow.symbol)
            D;JNE
            """
        }
        
        return asm
    }
    
    private func translate(_ function: FunctionCommand) -> ASM {
        let asm: ASM
        
        switch function.operation {
        case .declare:
            guard let name = function.name, let lclCount = function.count else {
                preconditionFailure("func decl: name must be set.")
            }
            
            // TODO: Determine how to setup THIS/THAT segments
            
            // (LABEL)
            // LCL[0..<nLocals] = 0
            // SP = SP + nLocals (working function stack)
            
            var _asm: ASM = translate(SynteticProgramFlow(label: name))
            
            for localIndex in 0 ..< lclCount {
                _asm += translate(SynteticMemoryAccess(pushConstant: 0)) + "\n"
                _asm += translate(
                    SynteticMemoryAccess(
                        operation: .pop,
                        segment: .local,
                        index: localIndex
                    )
                ) + "\n"
            }
            
            for _ in 0 ..< lclCount {
                _asm += """
                @SP
                M=M+1\n
                """
            }
            
            asm = _asm
            
        case .invoke:
            // let return-addr
            // store return-addr
            // store LCL
            // store ARG
            // store THIS
            // store THAT
            // ARG = SP - nArgs - 5
            // LCL = SP
            // go-to func-label
            // (return-addr)
            
            guard let name = function.name, let argCount = function.count else {
                preconditionFailure("func call: name, count must be set.")
            }
            
            let returnAddressLabel = "RETURN_\(name)_\(Self.labelId)"
            Self.labelId += 1
            
            var _asm = """
            @\(returnAddressLabel)
            D=A
            @SP
            A=M
            M=D
            @SP
            M=M+1
            @LCL
            D=M
            @SP
            A=M
            M=D
            @SP
            M=M+1
            @ARG
            D=M
            @SP
            A=M
            M=D
            @SP
            M=M+1
            @THIS
            D=M
            @SP
            A=M
            M=D
            @SP
            M=M+1
            @THAT
            D=M
            @SP
            A=M
            M=D
            @SP
            M=M+1\n
            """
            
            _asm += """
            @SP
            D=M
            D=D-1
            D=D-1
            D=D-1
            D=D-1
            D=D-1\n
            """
            for _ in 0 ..< argCount { _asm += "D=D-1\n" }
            _asm += """
            @ARG
            M=D\n
            """
            
            _asm += """
            @SP
            D=M
            @LCL
            M=D\n
            """
            
            _asm += translate(SynteticProgramFlow(operation: .goTo, symbol: name)) + "\n"
            _asm += translate(SynteticProgramFlow(label: returnAddressLabel))
            
            asm = _asm
            
        case .return:
            // FRAME            = LCL
            // RETURN_VAL       = RAM[RAM[SP-1]]
            // POPPED_SP        = ARG
            //
            // ... restore previous segments
            //
            // RAM[POPPED_SP]   = RETURN_VAL
            // SP               = POPPED_SP + 1
            // THAT             = FRAME - 1
            // THIS             = FRAME - 2
            // ARG              = FRAME - 3
            // LCL              = FRAME - 4
            // RETURN           = FRAME - 5
            // GOTO RETURN
            
            var _asm = """
            @LCL
            D=M
            @R5
            M=D\n
            """
            
            _asm += """
            @SP
            A=M-1
            D=M
            @R6
            M=D\n
            """
            
            _asm += """
            @ARG
            D=M\n
            """
            
            _asm += """
            @SP
            M=D
            @R6
            D=M
            @SP
            A=M
            M=D
            @SP
            M=M+1\n
            """
            
            _asm += """
            @R5
            M=M-1
            A=M
            D=M
            @THAT
            M=D
            @R5
            M=M-1
            A=M
            D=M
            @THIS
            M=D
            @R5
            M=M-1
            A=M
            D=M
            @ARG
            M=D
            @R5
            M=M-1
            A=M
            D=M
            @LCL
            M=D\n
            """
            
            _asm += """
            @R5
            M=M-1
            A=M
            A=M
            0;JMP
            """
            
            asm = _asm
        }
        
        return asm
    }
}

fileprivate struct SynteticMemoryAccess: MemoryCommand {
    let operation: MemoryOperation
    let segment: MemorySegment
    let index: Int
    var description: String { "\(self)" }
    
    init(operation: MemoryOperation, segment: MemorySegment, index: Int) {
        self.operation = operation
        self.segment = segment
        self.index = index
    }
    
    init(operation: MemoryOperation, constant: Int) {
        self.init(operation: operation, segment: .constant, index: constant)
    }
    
    init(pushConstant constant: Int) {
        self.init(operation: .push, constant: constant)
    }
}

fileprivate struct SynteticProgramFlow: ProgramFlowCommand {
    let operation: ProgramFlowOperation
    let symbol: String
    var description: String { "\(self)" }
    
    init(operation: ProgramFlowOperation, symbol: String) {
        self.operation = operation
        self.symbol = symbol
    }
    
    init(label: String) {
        self.init(operation: .label, symbol: label)
    }
}

fileprivate extension MemoryCommand {
    var constant: Int { index }
}

fileprivate struct SynteticFunction: FunctionCommand {
    var operation: FunctionOperation
    var name: String?
    var count: Int?
    var description: String { "\(self)" }
}

extension SynteticFunction {
    static var callSysInit: SynteticFunction {
        .init(operation: .invoke, name: "Sys.init", count: 0)
    }
}
