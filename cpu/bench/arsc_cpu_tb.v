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
/// Testbench for the arsc_cpu circuit
`timescale 1 ns/1 ns

module arsc_cpu_tb;
    
    localparam
        T = 20,
        N = 16;
    
    reg [2:0] i;
    reg [N-1:0] idx_data [3:1];
    
    reg clk, reset_n, start_n;
    reg rd_data_valid, wait_req, io_done;
    reg [N-1:0] rd_data, dil;
     
    wire read_n, write_n, rd_indev_n, wr_outdev_n, io_dev;
    wire [N-1:0] addr, wr_data;
    wire [N-1:0] pc, ir, acc, uar, ubr, idx1, idx2, idx3;
    wire [4:0] psr;
    
    arsc_cpu #(.N(N))
        uut(.clk(clk)
            , .reset_n(reset_n)
            , .start_n(start_n)
            , .rd_data_valid(rd_data_valid)
            , .wait_req(wait_req)
            , .io_done(io_done)
            , .rd_data(rd_data)
            , .dil(dil)
            , .read_n(read_n)
            , .write_n(write_n)
            , .rd_indev_n(rd_indev_n)
            , .wr_outdev_n(wr_outdev_n)
            , .io_dev(io_dev)
            , .addr(addr)
            , .wr_data(wr_data)
            , .pc(pc)
            , .ir(ir)
            , .acc(acc)
            , .uar(uar)
            , .ubr(ubr)
            , .idx1(idx1)
            , .idx2(idx2)
            , .idx3(idx3)
            , .psr(psr));
    
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
        rd_data_valid = 1'b0;
        wait_req = 1'b0;
        io_done = 1'b0;
        dil = 0;
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
        rd_data = 16'b0000100001110100;     /// LDA instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data = 16'd8923;                 /// Data read from RAM
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        
        /// LDX (load every index register)
        idx_data[1] = 16'd9999;
        idx_data[2] = 16'd18455;
        idx_data[3] = 16'd19;
        for (i = 1; i <= 3; i = i + 1)
        begin
            /// Fetch
            repeat(5) @(negedge clk);
            rd_data = 16'b0110000010100101;     /// LDX instruction
            rd_data[9:8] = i;
            rd_data_valid = 1'b1;
            @(negedge clk);
            rd_data = 16'd0;
            rd_data_valid = 1'b0;
            @(negedge clk);
            
            /// Execute
            repeat(4) @(negedge clk);
            rd_data = idx_data[i];              /// Data read from RAM
            rd_data_valid = 1'b1;
            @(negedge clk);
            rd_data = 16'd0;
            rd_data_valid = 1'b0;
        end
                
        /// STA
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data = 16'b0001010000001111;     /// STA instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data = 16'd1087;                 /// The actual address (after indirection)
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
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
        rd_data = 16'b0001101111111111;     /// ADD instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data = 16'd13000;                /// Data read from RAM
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        
        /// TCA
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data = 16'b0010000000000000;     /// TCA instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(2) @(negedge clk);
        
        /// BRU
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b0010110110100011;     /// BRU instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data = 16'd17999;                /// The actual address (after indirection)
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        
        /// Execute
        @(negedge clk);
        
        /// BIP
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b0011001000100011;     /// BIP instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// BIN
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data = 16'b0011100011101011;     /// BIN instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// RWD
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data = 16'b0100010110101100;     /// RWD instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        io_done = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(2) @(negedge clk);
        dil = 16'd2000;
        io_done = 1'b1;
        @(negedge clk);
        io_done = 1'b0;
        
        /// WWD
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b0100101000011111;     /// WWD instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(3) @(negedge clk);
        io_done = 1'b1;
        @(negedge clk);
        io_done = 1'b0;
        
        /// SHL
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b0101000000000000;     /// SHL instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// SHR
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data = 16'b0101100000000000;     /// SHR instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// STX
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data = 16'b0110100110100101;     /// STX instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
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
        rd_data = 16'b0111011011110101;     /// TIX instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data = 16'd19999;                /// The actual address (after indirection)
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        
        /// Execute
        repeat(2) @(negedge clk);
        
        /// TDX
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data = 16'b0111100100000101;     /// TDX instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(2) @(negedge clk);
        
        /// AND
        /// Fetch
        repeat(6) @(negedge clk);
        rd_data = 16'b1000001111111111;     /// AND instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data = 16'd8796;                 /// Data read from RAM
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        
        // OR
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b1000110001011100;     /// OR instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Defer
        repeat(4) @(negedge clk);
        rd_data = 16'd17999;                /// The actual address (after indirection)
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
                
        /// Execute
        repeat(4) @(negedge clk);
        rd_data = 16'd8796;                 /// Data read from RAM
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        
        /// NOT
        /// Fetch
        repeat(5) @(negedge clk);
        rd_data = 16'b1001000000000000;     /// NOT instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// XOR
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b1001100001010011;     /// XOR instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        repeat(4) @(negedge clk);
        rd_data = 16'd8796;                 /// Data read from RAM
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
                
        /// HLT
        /// Fetch
        repeat(4) @(negedge clk);
        rd_data = 16'b0000000000000000;     /// HLT instruction
        rd_data_valid = 1'b1;
        @(negedge clk);
        rd_data = 16'd0;
        rd_data_valid = 1'b0;
        @(negedge clk);
        
        /// Execute
        @(negedge clk);
        
        /// Make sure that HCU is not active after HLT
        rd_data = 16'b0011000011111111;
        repeat(10) @(negedge clk);
        
        $stop;
    end
endmodule
