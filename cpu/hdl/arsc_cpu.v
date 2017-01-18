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
/// ARSC CENTRAL PROCESSING UNIT
module arsc_cpu
#(
    parameter N = 16                /// Bus width
)
(
    /// Input signals
    input wire clk, reset_n,
    input wire start_n,             /// Starts the CPU when low (if not already started)
    input wire rd_data_valid,       /// High when requested memory data is available in rd_data
    input wire wait_req,            /// High if memory controller is busy (defers read/write ops)
    input wire io_done,             /// High if scheduled I/O operation has been completed
    input wire [N-1:0] rd_data,     /// Carries read memory word when rd_data_valid is active
    input wire [N-1:0] dil,         /// Carries data acquired from an input device when io_done is high
    
    /// Output signals
    output wire read_n,             /// Asks memory controller to read the word at address addr
    output wire write_n,            /// Asks memory controller to write wr_data to address addr
    
    /// Some I/O devices may require an address when reading/writting. For instance,
    /// video controller requires an address of the pixel in video memory
    output wire rd_indev_n,         /// Asks I/O controller to read the word from I/O device io_dev
    output wire wr_outdev_n,        /// Asks I/O controller to write wr_data to I/O device io_dev
    output wire io_dev,             /// ID of an I/O device (only two I/O devices are supported)
    
    output wire [N-1:0] addr,       /// The memory address for read/write operation
    output wire [N-1:0] wr_data,    /// Data to be written to address addr
	output wire running,            /// High if CPU is currently active
    
    /// These output signals are useful for testing only
    output wire [N-1:0] pc,
    output wire [N-1:0] ir,
    output wire [N-1:0] acc,
    output wire [N-1:0] uar,
    output wire [N-1:0] ubr,
    output wire [N-1:0] idx1,
    output wire [N-1:0] idx2,
    output wire [N-1:0] idx3,
    output wire [4:0] psr
);

    /// Macros for different PSR bits
    localparam [2:0]
        PSR_IN = 3'd0,
        PSR_OF = 3'd1,
        PSR_ZR = 3'd2,
        PSR_NG = 3'd3,
        PSR_CR = 3'd4;
    
    /// Constants
    localparam [N-1:0]
        ZERO = 0
        , ONE = 1
        , MINUS_ONE = { N{ 1'b1 } };
    
    reg [4:0] psr_reg;
    reg [N-1:0]
        pc_reg
        , ir_reg
        , acc_reg
        , uar_reg
        , ubr_reg
        , idx1_reg
        , idx2_reg
        , idx3_reg;
    
    wire [4:0] psr_next;
    wire [N-1:0]
        pc_next
        , ir_next
        , acc_next
        , uar_next
        , ubr_next
        , idx1_next
        , idx2_next
        , idx3_next
        , idx_tmp
        , selected_idx;
    
    wire [N-1:0]
        alu_in1
        , alu_in2
        , alu_out;
    
    wire idx_zr;
    wire add_alu
         , comp_alu
         , shr_alu
         , shl_alu
         , and_alu
         , or_alu
         , xor_alu
         , tra1_alu
         , tra2_alu;
    
    /// BUS control signals
    wire pc_to_bus1
         , irlow_to_bus1
         , acc_to_bus1
         , uar_to_bus1
         , one_to_bus1
         , minone_to_bus1
         , one_to_bus2
         , rddata_to_bus2
         , idx_to_bus2
         , dil_to_bus2
         , bus3_to_uar
         , bus3_to_pc
         , bus3_to_ir
         , bus3_to_acc
         , bus3_to_ubr
         , bus3_to_idx;
    
    /// Control unit
    arsc_hcu #(.N(N))
        hcu(.clk(clk)
            , .reset_n(reset_n)
            , .start_n(start_n)
            , .idx_zr(idx_zr)
            , .ir(ir_reg)
            , .psr(psr_reg)
            , .rd_data_valid(rd_data_valid)
            , .wait_req(wait_req)
            , .io_done(io_done)
			, .running(running)
            , .add_alu(add_alu)
            , .comp_alu(comp_alu)
            , .shr_alu(shr_alu)
            , .shl_alu(shl_alu)
            , .and_alu(and_alu)
            , .or_alu(or_alu)
            , .xor_alu(xor_alu)
            , .tra1_alu(tra1_alu)
            , .tra2_alu(tra2_alu)
            , .pc_to_bus1(pc_to_bus1)
            , .irlow_to_bus1(irlow_to_bus1)
            , .acc_to_bus1(acc_to_bus1)
            , .uar_to_bus1(uar_to_bus1)
            , .one_to_bus1(one_to_bus1)
            , .minone_to_bus1(minone_to_bus1)
            , .one_to_bus2(one_to_bus2)
            , .rddata_to_bus2(rddata_to_bus2)
            , .idx_to_bus2(idx_to_bus2)
            , .dil_to_bus2(dil_to_bus2)
            , .bus3_to_uar(bus3_to_uar)
            , .bus3_to_pc(bus3_to_pc)
            , .bus3_to_ir(bus3_to_ir)
            , .bus3_to_acc(bus3_to_acc)
            , .bus3_to_ubr(bus3_to_ubr)
            , .bus3_to_idx(bus3_to_idx)
            , .read_n(read_n)
            , .write_n(write_n)
            , .rd_indev_n(rd_indev_n)
            , .wr_outdev_n(wr_outdev_n));
    
    /// ALU
    arsc_alu #(.N(N))
        alu(.add_cmd(add_alu)
            , .comp_cmd(comp_alu)
            , .shr_cmd(shr_alu)
            , .shl_cmd(shl_alu)
            , .and_cmd(and_alu)
            , .or_cmd(or_alu)
            , .xor_cmd(xor_alu)
            , .tra1_cmd(tra1_alu)
            , .tra2_cmd(tra2_alu)
            , .in1(alu_in1)
            , .in2(alu_in2)
            , .cr(psr_next[PSR_CR])
            , .of(psr_next[PSR_OF])
            , .out(alu_out));
    
    /// BUS
    arsc_bus #(.N(N))
        bus(/// BUS1 signals
            .bus1_ctrl({ minone_to_bus1, one_to_bus1, uar_to_bus1, acc_to_bus1, irlow_to_bus1, pc_to_bus1 })
            , .bus1_node0(pc_reg)
            , .bus1_node1({ 8'b0, ir_reg[7:0] })
            , .bus1_node2(acc_reg)
            , .bus1_node3(uar_reg)
            , .bus1_node4(ONE)
            , .bus1_node5(MINUS_ONE)
            , .bus1_out(alu_in1)
            
            /// BUS2 signals
            , .bus2_ctrl({ 2'b0, dil_to_bus2, idx_to_bus2, rddata_to_bus2, one_to_bus2 })
            , .bus2_node0(ONE)
            , .bus2_node1(rd_data)
            , .bus2_node2(selected_idx)
            , .bus2_node3(dil)
            , .bus2_node4()
            , .bus2_node5()
            , .bus2_out(alu_in2)
            
            /// BUS3 signals
            , .bus3_ctrl({ bus3_to_idx, bus3_to_ubr, bus3_to_acc, bus3_to_ir, bus3_to_pc, bus3_to_uar })
            , .bus3_in(alu_out)
            , .bus3_node0_in(uar_reg)
            , .bus3_node1_in(pc_reg)
            , .bus3_node2_in(ir_reg)
            , .bus3_node3_in(acc_reg)
            , .bus3_node4_in(ubr_reg)
            , .bus3_node5_in(selected_idx)
            , .bus3_node0_out(uar_next)
            , .bus3_node1_out(pc_next)
            , .bus3_node2_out(ir_next)
            , .bus3_node3_out(acc_next)
            , .bus3_node4_out(ubr_next)
            , .bus3_node5_out(idx_tmp));
    
    always @(posedge clk, negedge reset_n)
        if (reset_n == 1'b0)
        begin
            pc_reg      <= 0;
            ir_reg      <= 0;
            acc_reg     <= 0;
            uar_reg     <= 0;
            ubr_reg     <= 0;
            idx1_reg    <= 0;
            idx2_reg    <= 0;
            idx3_reg    <= 0;
            psr_reg     <= 0;
        end
        else
        begin
            pc_reg      <= pc_next;
            ir_reg      <= ir_next;
            acc_reg     <= acc_next;
            uar_reg     <= uar_next;
            ubr_reg     <= ubr_next;
            idx1_reg    <= idx1_next;
            idx2_reg    <= idx2_next;
            idx3_reg    <= idx3_next;
            psr_reg     <= psr_next;
        end
    
    /// Determine selected index register (if any)
    assign selected_idx =
        (ir_reg[9:8] == 2'b01) ? idx1_reg :
        (ir_reg[9:8] == 2'b10) ? idx2_reg :
        (ir_reg[9:8] == 2'b11) ? idx3_reg :
        ZERO;
    
    /// idx_zr flag is high if selected index register is zero
    assign idx_zr = (selected_idx == ZERO);
    
    /// Route idx_tmp to selected index register (if any). This will write new
    /// data to the given index register only if the 'bus3_to_idx' flag was
    /// asserted by the CU. Otherwise, previous data is written back to register
    assign idx1_next = (ir_reg[9:8] == 2'b01) ? idx_tmp : idx1_reg;
    assign idx2_next = (ir_reg[9:8] == 2'b10) ? idx_tmp : idx2_reg;
    assign idx3_next = (ir_reg[9:8] == 2'b11) ? idx_tmp : idx3_reg;
    
    /// Set negative, zero and interrupt PSR bits
    assign psr_next[PSR_IN] = 1'b0;
    assign psr_next[PSR_NG] = acc_reg[N-1];
    assign psr_next[PSR_ZR] = (acc_reg == ZERO);
    
    /// UBR/UAR is routed to wr_data/addr output
    assign wr_data = ubr_reg;
    assign addr = uar_reg;
    
    /// 10th bit of the instruction identfies I/O device for RWD and WWD
    assign io_dev = ir_reg[10];
    
    /// Expose internal registers for ease of testing
    assign pc = pc_reg;
    assign ir = ir_reg;
    assign acc = acc_reg;
    assign uar = uar_reg;
    assign ubr = ubr_reg;
    assign idx1 = idx1_reg;
    assign idx2 = idx2_reg;
    assign idx3 = idx3_reg;
    assign psr = psr_reg;
    
endmodule
