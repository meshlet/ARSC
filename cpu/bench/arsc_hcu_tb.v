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
/// Testbench for the arsc_hcu circuit
`timescale 1 ns/1 ns

module arsc_hcu_tb;
    
    localparam
        T = 20,
        N = 16;
        
    reg clk, reset_n, start_n;
    reg idx_zr, rd_data_valid, wait_req, io_done;
    reg [N-1:0] ir;
    reg [4:0] psr;
    
    wire
        add_alu, comp_alu, shr_alu, shl_alu, and_alu, or_alu, xor_alu,
        tra1_alu, tra2_alu;
        
    wire
        pc_to_bus1, bus3_to_uar, one_to_bus2, bus3_to_pc, bus3_to_ir, irlow_to_bus1,
        idx_to_bus2, bus3_to_acc, acc_to_bus1, bus3_to_ubr, uar_to_bus1, bus3_to_idx,
        one_to_bus1, minone_to_bus1, rddata_to_bus2, dil_to_bus2;
        
    wire read_n, write_n, rd_indev_n, wr_outdev_n, running;
    
    arsc_hcu #(.N(N))
        uut(.clk(clk)
            , .reset_n(reset_n)
            , .start_n(start_n)
            , .idx_zr(idx_zr)
            , .ir(ir)
            , .psr(psr)
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
            , .bus3_to_uar(bus3_to_uar)
            , .one_to_bus2(one_to_bus2)
            , .bus3_to_pc(bus3_to_pc)
            , .bus3_to_ir(bus3_to_ir)
            , .irlow_to_bus1(irlow_to_bus1)
            , .idx_to_bus2(idx_to_bus2)
            , .bus3_to_acc(bus3_to_acc)
            , .acc_to_bus1(acc_to_bus1)
            , .bus3_to_ubr(bus3_to_ubr)
            , .uar_to_bus1(uar_to_bus1)
            , .bus3_to_idx(bus3_to_idx)
            , .one_to_bus1(one_to_bus1)
            , .minone_to_bus1(minone_to_bus1)
            , .rddata_to_bus2(rddata_to_bus2)
            , .dil_to_bus2(dil_to_bus2)
            , .read_n(read_n)
            , .write_n(write_n)
            , .rd_indev_n(rd_indev_n)
            , .wr_outdev_n(wr_outdev_n));
      
    always
    begin
        clk = 1'b1;
        #(T/2);
        clk = 1'b0;
        #(T/2);
    end
      
    initial
    begin
    
        reset_n = 1'b0;
        start_n = 1'b1;
        idx_zr = 1'b0;
        ir = 16'b0;
        psr = 5'b0;
        rd_data_valid = 1'b0;
        wait_req = 1'b0;
        io_done = 1'b0;
        repeat(2) @(negedge clk);
        
        reset_n = 1'b1;
        start_n = 1'b0;
        @(negedge clk);
        start_n = 1'b1;
        
        /// LDA
        /// Fetch
        wait_req = 1'b0;
        rd_data_valid = 1'b0;
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0000101001110100;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// STA
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0001010000001111;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// Execute
        repeat(2) @(negedge clk);
        wait_req = 1'b1;
        repeat(2) @(negedge clk);
        wait_req = 1'b0;
        @(negedge clk);
        
        /// ADD
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0001100011111111;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// TCA
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b001000000000000;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(2) @(negedge clk);
        
        /// BRU
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0010110110100011;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// Execute
        @(negedge clk);
        
        /// BIP
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0011001000100011;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// BIN
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0011100011101011;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// RWD
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0100010110101100;
        @(negedge clk);
        rd_data_valid = 1'b0;
        io_done = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(2) @(negedge clk);
        io_done = 1'b1;
        @(negedge clk);
        io_done = 1'b0;
        
        /// WWD
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0100101000011111;
        @(negedge clk);
        rd_data_valid = 1'b0;
        io_done = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(3) @(negedge clk);
        io_done = 1'b1;
        @(negedge clk);
        io_done = 1'b0;
        
        /// SHL
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0101000000000000;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// SHR
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0101100000000000;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// LDX
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0110011110100101;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// STX
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0110100110100101;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        wait_req = 1'b1;
        repeat(2) @(negedge clk);
        wait_req = 1'b0;
        @(negedge clk);
        
        /// TIX
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0111011011110101;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// Execute
        @(negedge clk);
        idx_zr = 1'b1;
        @(negedge clk);
        idx_zr = 1'b0;
        
        /// TDX
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0111100100000101;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        idx_zr = 1'b1;
        @(negedge clk);
        
        /// AND
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b1000000101011111;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// OR
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b1000110001011100;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
                
        /// Execute
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// NOT
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b1001000000000000;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// XOR
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b1001100001010011;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data_valid = 1'b0;
        
        /// HLT
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data_valid = 1'b1;
        ir = 16'b0000000000000000;
        @(negedge clk);
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// Make sure that HCU is not active after HLT
        ir = 16'b0011000011111111;
        repeat(10) @(negedge clk);
        
        $stop;
    
    end
endmodule
