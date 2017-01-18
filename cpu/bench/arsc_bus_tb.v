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
/// Testbench for the arsc_bus circuit
`timescale 1 ns/1 ns

module arsc_bus_tb;
    
    localparam
        T = 20,
        N = 16;
    
    reg [2:0] i;
    
    /// BUS1 signals
    reg [5:0] bus1_ctrl;
    reg [N-1:0]
        bus1_node0, bus1_node1, bus1_node2, bus1_node3,
        bus1_node4, bus1_node5;
    wire [N-1:0] bus1_out;
    
    /// BUS2 signals
    reg [5:0] bus2_ctrl;
    reg [N-1:0]
        bus2_node0, bus2_node1, bus2_node2, bus2_node3,
        bus2_node4, bus2_node5;
    wire [N-1:0] bus2_out;
    
    /// BUS3 signals
    reg [5:0] bus3_ctrl;
    reg [N-1:0] bus3_in;
    reg [N-1:0]
        bus3_node0_in, bus3_node1_in, bus3_node2_in,
        bus3_node3_in, bus3_node4_in, bus3_node5_in;
    wire [N-1:0]
        bus3_node0_out, bus3_node1_out, bus3_node2_out,
        bus3_node3_out, bus3_node4_out, bus3_node5_out;
    
    arsc_bus #(.N(N))
        uut(.bus1_ctrl(bus1_ctrl)
            , .bus1_node0(bus1_node0)
            , .bus1_node1(bus1_node1)
            , .bus1_node2(bus1_node2)
            , .bus1_node3(bus1_node3)
            , .bus1_node4(bus1_node4)
            , .bus1_node5(bus1_node5)
            , .bus1_out(bus1_out)
            , .bus2_ctrl(bus2_ctrl)
            , .bus2_node0(bus2_node0)
            , .bus2_node1(bus2_node1)
            , .bus2_node2(bus2_node2)
            , .bus2_node3(bus2_node3)
            , .bus2_node4(bus2_node4)
            , .bus2_node5(bus2_node5)
            , .bus2_out(bus2_out)
            , .bus3_ctrl(bus3_ctrl)
            , .bus3_in(bus3_in)
            , .bus3_node0_in(bus3_node0_in)
            , .bus3_node1_in(bus3_node1_in)
            , .bus3_node2_in(bus3_node2_in)
            , .bus3_node3_in(bus3_node3_in)
            , .bus3_node4_in(bus3_node4_in)
            , .bus3_node5_in(bus3_node5_in)
            , .bus3_node0_out(bus3_node0_out)
            , .bus3_node1_out(bus3_node1_out)
            , .bus3_node2_out(bus3_node2_out)
            , .bus3_node3_out(bus3_node3_out)
            , .bus3_node4_out(bus3_node4_out)
            , .bus3_node5_out(bus3_node5_out));
    
    initial
    begin
        /// Test BUS1 and BUS2
        bus1_ctrl = 6'b0;
        bus2_ctrl = 6'b0;
        bus1_node0 = 56;
        bus1_node1 = -123;
        bus1_node2 = 1234;
        bus1_node3 = -6543;
        bus1_node4 = 23456;
        bus1_node5 = -10000;
        bus2_node0 = -888;
        bus2_node1 = 7432;
        bus2_node2 = 9872;
        bus2_node3 = -5;
        bus2_node4 = 9911;
        bus2_node5 = 11111;
        #(T);
        
        /// Activate each input line in turn for BUS1 and BUS2
        for (i = 0; i <= 5; i = i + 1)
        begin
            bus1_ctrl = 6'b0;
            bus2_ctrl = 6'b0;
            bus1_ctrl[i] = 1'b1;
            bus2_ctrl[i] = 1'b1;
            #(T);
        end
        
        /// Test BUS3
        bus3_ctrl = 6'b0;
        bus3_in = 5461;
        bus3_node0_in = 9999;
        bus3_node1_in = -439;
        bus3_node2_in = 12345;
        bus3_node3_in = -777;
        bus3_node4_in = -8843;
        bus3_node5_in = 29333;
        #(T);
        
        /// Activate each output line in turn for BUS3
        for (i = 0; i <= 5; i = i +1)
        begin
            bus3_ctrl = 6'b0;
            bus3_ctrl[i] = 1'b1;
            #(T);
        end
        
        $stop;
    end
endmodule
