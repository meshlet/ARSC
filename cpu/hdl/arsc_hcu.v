/// ==============================================================================
/// ARSC (A Relatively Simple Computer) License
/// ==============================================================================
/// 
/// ARSC is distributed under the following BSD-style license:
/// 
/// Copyright (c) 2016-2017 Dzanan Bajgoric
/// All rights reserved.
/// 
/// Redistribution and use in source and binary forms, with or without modification,
/// are permitted provided that the following conditions are met:
/// 
/// 1. Redistributions of source code must retain the above copyright notice, this
///    list of conditions and the following disclaimer.
/// 
/// 2. Redistributions in binary form must reproduce the above copyright notice, this
///    list of conditions and the following disclaimer in the documentation and/or other
///    materials provided with the distribution.
/// 
/// 3. The name of the author may not be used to endorse or promote products derived from
///    this product without specific prior written permission from the author.
/// 
/// 4. Products derived from this product may not be called "ARSC" nor may "ARSC" appear
///    in their names without specific prior written permission from the author.
/// 
/// THIS PRODUCT IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
/// BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
/// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
/// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO
/// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
/// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
/// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
/// OF THIS PRODUCT, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///
///
/// ARSC HARDWIRED CONTROL UNIT
///
/// ARSC CPU is a 16-bit machine whose instruction has the following format:
///      opcode     indirect/IO device bit   index register          address
/// 15 14 13 12 11           10                   9 8           7 6 5 4 3 2 1 0
///
/// In IDLE state, HCU doesn't perform any actions. FETCH, DEFER and EXECUTE
/// states correspond to major cycles of the ARSC CPU. Once start_n signal becomes
/// active (low), HCU moves to FETCH state and reads the instruction whose address
/// is stored in PC. The indexed addressing operation (for instructions that support
/// it) is performed at the end of fetch.
///
/// For all one-address instructions except RWD and WWD, 10th bit of the instruction
/// is an indirect bit. In case of indirect addressing this bit is enabled which
/// causes the HCU moves to DEFER state in which the actual address is read from
/// the memory. Finally, HCU moves to EXECUTE state in which (for most instructions)
/// the arithmetic/logic operations are carried out.
///
/// In case of RWD and WWD instructions, 10th bit is the identifier of the input and
/// output device, respectively. This means that ARSC supports two input and two
/// output devices, with IDs 0 and 1.
///
/// HCU has a variable length major cycle to support memory with different read/write
/// access times. HCU will wait a number of clock cycles after a read or write is
/// issued, and will proceed only when RAM controller informs it that the memory op
/// was completed. HCU divides major cycle into variable number of phases to be able
/// to track the current operation within one major cycle. Each phase may take one or
/// more clock cycles.
///
/// PSR = [carry, negative, zero, overflow, interrupt]
module arsc_hcu
#(
    parameter N = 16                /// Bus width
)
(
    /// Input signals
    input wire clk, reset_n,
    input wire start_n,				         /// Starts the control unit (and entire CPU)
    input wire idx_zr,              /// Is selected index register zero?
    input wire [N-1:0] ir,          /// IR register contents
    input wire [4:0] psr,           /// Processor status register contents
    input wire rd_data_valid,       /// Is requested memory word in MBR?
    input wire wait_req,            /// Is memory controller busy? (keeps MAR and MBR unmodified)
    input wire io_done,             /// Signalled once scheduled I/O operation has been completed
    
	output reg running,				         /// High if HCU is active (executing instructions)
	
    /// Outputs to ALU
    output reg add_alu,				         /// ALU add
    output reg comp_alu,            /// ALU 1's complement
    output reg shr_alu,             /// ALU shift right
    output reg shl_alu,             /// ALU shift left
    output reg and_alu,             /// ALU bit and
    output reg or_alu,              /// ALU bit or
    output reg xor_alu,             /// ALU bit xor
    output reg tra1_alu,            /// ALU transfer input 1 to output
    output reg tra2_alu,            /// ALU transfer input 2 to output
    
    /// Outputs to BUS structure
    output reg pc_to_bus1,         	/// Feed PC to BUS1
    output reg irlow_to_bus1,      	/// Feed IR[7:0] to BUS1 (upper 8 bits are zero-filled)
    output reg acc_to_bus1,        	/// Feed ACC to BUS1
    output reg uar_to_bus1,        	/// Feed UAR to BUS1
    output reg one_to_bus1,        	/// Feed constant 1 to BUS1
    output reg minone_to_bus1,     	/// Feed constant -1 to BUS1
    output reg one_to_bus2,        	/// Feed contant 1 to BUS2
    output reg idx_to_bus2,        	/// Feed selected index register to BUS2
    output reg rddata_to_bus2,     	/// Feed data read from memory to BUS2
    output reg dil_to_bus2,         /// Feed data input line to BUS2
    output reg bus3_to_uar,        	/// Feed BUS3 to UAR
    output reg bus3_to_pc,         	/// Feed BUS3 to PC
    output reg bus3_to_ir,         	/// Feed BUS3 to IR
    output reg bus3_to_acc,        	/// Feed BUS3 too ACC
    output reg bus3_to_ubr,        	/// Feed BUS3 to UBR
    output reg bus3_to_idx,        	/// Feed BUS3 to selected index register
    
    /// Outputs to memory
    output reg read_n,             	/// Triggers memory read op
    output reg write_n,            	/// Triggers mememory write op
    
    /// Outputs to I/O
    output reg rd_indev_n,          /// Triggers read from an input device
    output reg wr_outdev_n          /// Triggers write to an output device
);

    /// States of the HCU (fetch, defer and execute are major cycles)
    localparam [1:0]
        IDLE = 2'd0,
        FETCH = 2'd1,
        DEFER = 2'd2,
        EXECUTE = 2'd3;
    
    /// Phase refers to a substate within the current HCU state. Pair (state, phase)
    /// precicely defines the operations HCU will undertake in each clock cycle
    localparam [2:0]
        PHASE_0 = 3'd0,
        PHASE_1 = 3'd1,
        PHASE_2 = 3'd2,
        PHASE_3 = 3'd3,
		PHASE_4 = 3'd4;
        
    /// 5-bit opcodes for every instruction in the ARSC ISA
    localparam [4:0]
        HLT = 5'b00000,     /// Halts the execution
        LDA = 5'b00001,     /// Loads ACC with data from given memory address
        STA = 5'b00010,     /// Stores ACC to given memory address
        ADD = 5'b00011,     /// Adds ACC with data from memory address and writes back to ACC
        TCA = 5'b00100,     /// Calculates 2's complement of ACC and writes it to ACC
        BRU = 5'b00101,     /// Unconditionally branches to given memory address
        BIP = 5'b00110,     /// Branches if ACC > 0
        BIN = 5'b00111,     /// Branches if ACC < 0
        RWD = 5'b01000,     /// Reads a data word from input device to ACC
        WWD = 5'b01001,     /// Writes ACC to output device
        SHL = 5'b01010,     /// Left shifts ACC and writes back to ACC
        SHR = 5'b01011,     /// Right shifts ACC and writes back to ACC
        LDX = 5'b01100,     /// Loads given index register with data from memory address
        STX = 5'b01101,     /// Stores index register to given memory address
        TIX = 5'b01110,     /// Increments index register and branches if it is zero
        TDX = 5'b01111,     /// Decrements index register and branches if it is not zero
        AND = 5'b10000,     /// Bit AND between ACC and data from the address and writes result to ACC
        OR  = 5'b10001,     /// Bit OR between ACC and data from the address and writes result to ACC
        NOT = 5'b10010,     /// Bit negation of the ACC and result is written back to ACC
        XOR = 5'b10011;     /// Bit XOR between ACC and data from the address and writes result to ACC
    
    /// Macros for different PSR bits
    localparam [2:0]
        PSR_IN = 3'd0,
        PSR_OF = 3'd1,
        PSR_ZR = 3'd2,
        PSR_NG = 3'd3,
        PSR_CR = 3'd4;
        
    reg [1:0] state_reg, state_next;
    reg [2:0] phase_reg, phase_next;
    
    always @(posedge clk, negedge reset_n)
        if (~reset_n)
        begin
            state_reg <= IDLE;
            phase_reg <= PHASE_0;
        end
        else
        begin
            state_reg <= state_next;
            phase_reg <= phase_next;
        end
    
    /// HCU FSM
    always @*
    begin
        /// Defaults
        state_next = state_reg;
        phase_next = phase_reg;
        { add_alu, comp_alu, shr_alu, shl_alu, and_alu, or_alu, xor_alu, tra1_alu, tra2_alu } = 9'b0;
        { read_n, write_n } = 2'b11;
        { rd_indev_n, wr_outdev_n } = 2'b11;
        pc_to_bus1 = 1'b0;
        bus3_to_uar = 1'b0;
        one_to_bus2 = 1'b0;
        bus3_to_pc = 1'b0;
        bus3_to_ir = 1'b0;
        irlow_to_bus1 = 1'b0;
        idx_to_bus2 = 1'b0;
        bus3_to_acc = 1'b0;
        acc_to_bus1 = 1'b0;
        bus3_to_ubr = 1'b0;
        uar_to_bus1 = 1'b0;
        bus3_to_idx = 1'b0;
        one_to_bus1 = 1'b0;
        minone_to_bus1 = 1'b0;
        rddata_to_bus2 = 1'b0;
        dil_to_bus2 = 1'b0;
		running = 1'b1;
        
        case (state_reg)
            /// While in IDLE state, HCU doesn't do any processing
            IDLE:
			begin
				running = 1'b0;
                if (~start_n)
                begin
                    state_next = FETCH;
                    phase_next = PHASE_0;
                end
			end
            
            /// FETCH state is dedicated to instruction fetching (includes memory
            /// read) and partical decoding
            FETCH:
                if (phase_reg == PHASE_0)
                begin
                    /// UAR <- PC
                    pc_to_bus1 = 1'b1;
                    bus3_to_uar = 1'b1;
                    tra1_alu = 1'b1;
                    phase_next = PHASE_1;
                end
                else if (phase_reg == PHASE_1)
                begin
                    /// PC <- PC + 1
                    pc_to_bus1 = 1'b1;
                    one_to_bus2 = 1'b1;
                    bus3_to_pc = 1'b1;
                    add_alu = 1'b1;
                    
                    /// Read memory
                    read_n = 1'b0;
                    phase_next = PHASE_2;
                end
                else if (phase_reg == PHASE_2 && rd_data_valid)
                begin
                    /// IR <- RD_DATA
                    rddata_to_bus2 = 1'b1;
                    bus3_to_ir = 1'b1;
                    tra2_alu = 1'b1;
                    phase_next = PHASE_3;
                end
                else if (phase_reg == PHASE_3)
                begin
                    /// Strictly speaking, PHASE 3 should be run for 1-address instructions only
                    /// (indexing is done here and decision to move to DEFER state is made). But,
                    /// if all unused instruction fields of 0-address instructions is set to zero
                    /// (bit[10] - indirect bit, bit[11:10] - index register), then running PHASE_3
                    /// for these instructions will have no effect. Also, note that instruction
                    /// bits (9, 8) are not checked - if they are zero (no indexing) then there
                    /// will be no selected index register and 16'b0 will be fed to the bus
                    if (ir[15:11] < LDX || ir[15:11] > TDX)
                    begin
                        /// UAR <- IR[7:0] + INDEX
                        irlow_to_bus1 = 1'b1;
                        idx_to_bus2 = 1'b1;
                        bus3_to_uar = 1'b1;
                        add_alu = 1'b1;
                    end
                    else
                    begin
                        /// UAR <- IR[7:0]
                        irlow_to_bus1 = 1'b1;
                        bus3_to_uar = 1'b1;
                        tra1_alu = 1'b1;
                    end
                    
                    /// If indirect addressing bit is set (bit[10]) and this is not an I/O instruction
                    /// go to DEFER, otherwise EXECUTE
                    state_next = (ir[10] && ir[15:11] != RWD && ir[15:11] != WWD) ? DEFER : EXECUTE;
                    phase_next = PHASE_0;
                end
            
            /// Read the actual address from the memory and write it to UAR (run only if
            /// indirect addressing bit is set)
            DEFER:
                if (phase_reg == PHASE_0)
                begin
                    /// Read memory
                    read_n = 1'b0;
                    phase_next = PHASE_1;
                end
                else if (phase_reg == PHASE_1 && rd_data_valid)
                begin
                    /// UAR <- RD_DATA
                    rddata_to_bus2 = 1'b1;
                    bus3_to_uar = 1'b1;
                    tra2_alu = 1'b1;
                    
                    state_next = EXECUTE;
                    phase_next = PHASE_0;
                end
                
            /// EXECUTE cycle performs the actual operation required by the instruction
            /// and is unique for each instruction
            EXECUTE:
                case (ir[15:11])
                    HLT:
                    begin
                        state_next = IDLE;
                    end
                        
                    LDA:
                        if (phase_reg == PHASE_0)
                        begin
                            /// Read memory
                            read_n = 1'b0;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1 && rd_data_valid)
                        begin
                            /// ACC <- RD_DATA
                            rddata_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            tra2_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                        
                    STA:
                        if (phase_reg == PHASE_0)
                        begin
                            /// UBR <- ACC
                            acc_to_bus1 = 1'b1;
                            bus3_to_ubr = 1'b1;
                            tra1_alu = 1'b1;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1)
                        begin
                            /// Write memory
                            write_n = 1'b0;
                            phase_next = PHASE_2;
                        end
                        else if (phase_reg == PHASE_2 && ~wait_req)
                        begin
                            /// Memory written
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                        
                    ADD:
                        if (phase_reg == PHASE_0)
                        begin
                            /// Read memory
                            read_n = 1'b0;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1 && rd_data_valid)
                        begin
                            /// ACC <- RD_DATA + ACC
                            acc_to_bus1 = 1'b1;
                            rddata_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            add_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                    
                    TCA:
                        if (phase_reg == PHASE_0)
                        begin
                            /// ACC <- ACC'
                            acc_to_bus1 = 1'b1;
                            bus3_to_acc = 1'b1;
                            comp_alu = 1'b1;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1)
                        begin
                            /// ACC <- ACC + 1 (ACC' + 1 => 2's complement)
                            acc_to_bus1 = 1'b1;
                            one_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            add_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                            
                    BRU:
                    begin
                        /// PC <- UAR
                        uar_to_bus1 = 1'b1;
                        bus3_to_pc = 1'b1;
                        tra1_alu = 1'b1;
                        
                        state_next = FETCH;
                        phase_next = PHASE_0;
                    end
                    
                    BIP:
                    begin
                        state_next = FETCH;
                        phase_next = PHASE_0;
                        
                        if (~psr[PSR_NG] && ~psr[PSR_ZR])
                        begin
                            /// PC <- UAR
                            uar_to_bus1 = 1'b1;
                            bus3_to_pc = 1'b1;
                            tra1_alu = 1'b1;
                        end
                    end
                    
                    BIN:
                    begin
                        state_next = FETCH;
                        phase_next = PHASE_0;
                        
                        if (psr[PSR_NG])
                        begin
                            /// PC <- UAR
                            uar_to_bus1 = 1'b1;
                            bus3_to_pc = 1'b1;
                            tra1_alu = 1'b1;
                        end
                    end
                    
                    RWD:
						if (phase_reg == PHASE_0)
						begin
							/// Read the I/O address from the memory
							read_n = 1'b0;
                            phase_next = PHASE_1;
						end
						else if (phase_reg == PHASE_1 && rd_data_valid)
						begin
							/// UAR <- RD_DATA
							rddata_to_bus2 = 1'b1;
                            bus3_to_uar = 1'b1;
                            tra2_alu = 1'b1;
							phase_next = PHASE_2;
						end
                        else if (phase_reg == PHASE_2)
                        begin
                            /// Request data from an input device
                            rd_indev_n = 1'b0;
                            phase_next = PHASE_3;
                        end
                        else if (phase_reg == PHASE_3 && io_done)
                        begin
                            /// ACC <- DIL
                            dil_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            tra2_alu = 1'b1;
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                    
                    WWD:
						if (phase_reg == PHASE_0)
						begin
							/// Read the I/O address from the memory
							read_n = 1'b0;
                            phase_next = PHASE_1;
						end
						else if (phase_reg == PHASE_1 && rd_data_valid)
						begin
							/// UAR <- RD_DATA
							rddata_to_bus2 = 1'b1;
                            bus3_to_uar = 1'b1;
                            tra2_alu = 1'b1;
							phase_next = PHASE_2;
						end
                        else if (phase_reg == PHASE_2)
                        begin
                            /// UBR <- ACC
                            acc_to_bus1 = 1'b1;
                            bus3_to_ubr = 1'b1;
                            tra1_alu = 1'b1;
                            phase_next = PHASE_3;
                        end
                        else if (phase_reg == PHASE_3)
                        begin
                            /// Write data to an output device
                            wr_outdev_n = 1'b0;
                            phase_next = PHASE_4;
                        end
                        else if (phase_reg == PHASE_4 && io_done)
                        begin
                            /// Data written to an output device
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                    
                    SHL:
                    begin
                        /// ACC <- ACC << 1
                        acc_to_bus1 = 1'b1;
                        bus3_to_acc = 1'b1;
                        shl_alu = 1'b1;
                        
                        state_next = FETCH;
                        phase_next = PHASE_0;
                    end
                    
                    SHR:
                    begin
                        /// ACC <- ACC >> 1
                        acc_to_bus1 = 1'b1;
                        bus3_to_acc = 1'b1;
                        shr_alu = 1'b1;
                        
                        state_next = FETCH;
                        phase_next = PHASE_0;
                    end
                    
                    LDX:
                        if (phase_reg == PHASE_0)
                        begin
                            /// Read memory
                            read_n = 1'b0;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1 && rd_data_valid)
                        begin
                            /// INDEX <- RD_DATA
                            rddata_to_bus2 = 1'b1;
                            bus3_to_idx = 1'b1;
                            tra2_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                    
                    STX:
                        if (phase_reg == PHASE_0)
                        begin
                            /// UBR <- INDEX
                            idx_to_bus2 = 1'b1;
                            bus3_to_ubr = 1'b1;
                            tra2_alu = 1'b1;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1)
                        begin
                            /// Write memory
                            write_n = 1'b0;
                            phase_next = PHASE_2;
                        end
                        else if (phase_reg == PHASE_2 && ~wait_req)
                        begin
                            /// Memory written
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                        
                    TIX:
                        if (phase_reg == PHASE_0)
                        begin
                            /// INDEX <- INDEX + 1
                            one_to_bus1 = 1'b1;
                            idx_to_bus2 = 1'b1;
                            bus3_to_idx = 1'b1;
                            add_alu = 1'b1;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1)
                        begin
                            state_next = FETCH;
                            phase_next = PHASE_0;
                            
                            if (idx_zr)
                            begin
                                /// PC <- UAR
                                uar_to_bus1 = 1'b1;
                                bus3_to_pc = 1'b1;
                                tra1_alu = 1'b1;
                            end
                        end
                    
                    TDX:
                        if (phase_reg == PHASE_0)
                        begin
                            /// INDEX <- INDEX - 1
                            minone_to_bus1 = 1'b1;
                            idx_to_bus2 = 1'b1;
                            bus3_to_idx = 1'b1;
                            add_alu = 1'b1;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1)
                        begin
                            state_next = FETCH;
                            phase_next = PHASE_0;
                            
                            if (~idx_zr)
                            begin
                                /// PC <- UAR
                                uar_to_bus1 = 1'b1;
                                bus3_to_pc = 1'b1;
                                tra1_alu = 1'b1;
                            end
                        end
                        
                    AND:
                        if (phase_reg == PHASE_0)
                        begin
                            /// Read memory
                            read_n = 1'b0;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1 && rd_data_valid)
                        begin
                            /// ACC <- RD_DATA & ACC
                            acc_to_bus1 = 1'b1;
                            rddata_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            and_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                    
                    OR:
                        if (phase_reg == PHASE_0)
                        begin
                            /// Read memory
                            read_n = 1'b0;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1 && rd_data_valid)
                        begin
                            /// ACC <- RD_DATA | ACC
                            acc_to_bus1 = 1'b1;
                            rddata_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            or_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                    
                    NOT:
                    begin
                        /// ACC <- ~ACC
                        acc_to_bus1 = 1'b1;
                        bus3_to_acc = 1'b1;
                        comp_alu = 1'b1;
                        
                        state_next = FETCH;
                        phase_next = PHASE_0;
                    end
                                        
                    XOR:
                        if (phase_reg == PHASE_0)
                        begin
                            /// Read memory
                            read_n = 1'b0;
                            phase_next = PHASE_1;
                        end
                        else if (phase_reg == PHASE_1 && rd_data_valid)
                        begin
                            /// ACC <- RD_DATA xor ACC
                            acc_to_bus1 = 1'b1;
                            rddata_to_bus2 = 1'b1;
                            bus3_to_acc = 1'b1;
                            xor_alu = 1'b1;
                            
                            state_next = FETCH;
                            phase_next = PHASE_0;
                        end
                        
                endcase
        endcase
    end
endmodule
