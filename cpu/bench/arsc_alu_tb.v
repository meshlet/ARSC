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
/// Testbench for the arsc_alu circuit
`timescale 1 ns/1 ns

module arsc_alu_tb;
    
    localparam
        T = 20,
        N = 16;
        
    reg [N-1:0] in1, in2;
    reg
        add_cmd
        , comp_cmd
        , shr_cmd
        , shl_cmd
        , and_cmd
        , or_cmd
        , xor_cmd
        , tra1_cmd
        , tra2_cmd;
        
    wire [N-1:0] out;
    wire cr, of;
    
    arsc_alu #(.N(N))
        uut(
            .add_cmd(add_cmd)
            , .comp_cmd(comp_cmd)
            , .shr_cmd(shr_cmd)
            , .shl_cmd(shl_cmd)
            , .tra1_cmd(tra1_cmd)
            , .tra2_cmd(tra2_cmd)
            , .and_cmd(and_cmd)
            , .or_cmd(or_cmd)
            , .xor_cmd(xor_cmd)
            , .in1(in1)
            , .in2(in2)
            , .out(out)
            , .cr(cr)
            , .of(of));
    
    initial
    begin
        
        add_cmd  = 0;
        comp_cmd = 0;
        shr_cmd  = 0;
        shl_cmd  = 0;
        and_cmd  = 0;
        or_cmd   = 0;
        xor_cmd  = 0;
        tra1_cmd = 0;
        tra2_cmd = 0;
        
        #(T);
        
        /// Add
        in1 = 1999;
        in2 = 1001;
        add_cmd = 1;
        
        #(T);
        
        /// Add with carry
        in1 = 1;
        in2 = -1;
        
        #(T);
        
        /// Add with overflow (two positive integers)
        in1 = 2**(N-1) - 1;
        in2 = 10;
        
        #(T);
        
        /// Add with overflow (two negative integers)
        in1 = -(2**(N-1));
        in2 = -10;
        
        #(T);
        
        /// Complement
        in1 = 4567;
        add_cmd = 0;
        comp_cmd = 1;
        
        #(T);
        
        /// Shift right (MSB = 0)
        in1 = 9918;
        comp_cmd = 0;
        shr_cmd = 1;
        
        #(T);
        
        /// Shift right (MSB = 1)
        in1 = -17890;
        
        #(T);
        
        /// Shift left (no overflow)
        in1 = 15789;
        shr_cmd = 0;
        shl_cmd = 1;
        
        #(T);
        
        /// Shift left (overflow)
        in1 = 23783;
        
        #(T);
        
        /// And
        shl_cmd = 0;
        and_cmd = 1;
        in1 = 'b1111000011111111;
        in2 = 'b0000111111111111;
        
        #(T);
        
        /// Or
        in1 = 'b1000111111111111;
        in2 = 'b1100000000000000;
        and_cmd = 0;
        or_cmd = 1;
        
        #(T);
        
        /// XOr
        in1 = 'b1111010100000101;
        in2 = 'b1111101011110101;
        or_cmd = 0;
        xor_cmd = 1;
        
        #(T);
        
        /// Route in1 to out
        in1 = 9456;
        xor_cmd = 0;
        tra1_cmd = 1;
        
        #(T);
        
        /// Route in2 to out
        in2 = 8769;
        tra1_cmd = 0;
        tra2_cmd = 1;
        
        #(T);
        
        $stop;
        
    end
endmodule
