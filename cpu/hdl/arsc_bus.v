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
/// ARSC INTERNAL BUS
///
/// ARSC internal bus system contains three bus lines, two input and one output
/// line. Input bus line has one or more input nodes but only a single output
/// node. Output bus line has a single input and one or more output nodes.
/// Input/output lines are limited to five input/output nodes.
///
/// The output line works as follows: based on the control signal, the input
/// is routed to exactly one or none output nodes. For unselected output nodes,
/// their existing data is routed to the corresponding output. For this to
/// work, all output nodes must be connected as inputs to the bus. And, the
/// output nodes must be clocked so that the new value will be taken only on
/// the active edge of the clock. This basically means that output nodes of
/// this bus must be a set of registers whose outputs are connected to inputs
/// of the BUS3, and their inputs are connected to the outputs of the BUS3
module arsc_bus
#(
    parameter N = 16    /// Bus width
)
(
    /// BUS1 (input line)
    input wire [5:0] bus1_ctrl,
    input wire [N-1:0] bus1_node0,
    input wire [N-1:0] bus1_node1,
    input wire [N-1:0] bus1_node2,
    input wire [N-1:0] bus1_node3,
    input wire [N-1:0] bus1_node4,
    input wire [N-1:0] bus1_node5,
    output wire [N-1:0] bus1_out,
    
    /// BUS2 (input line)
    input wire [5:0] bus2_ctrl,
    input wire [N-1:0] bus2_node0,
    input wire [N-1:0] bus2_node1,
    input wire [N-1:0] bus2_node2,
    input wire [N-1:0] bus2_node3,
    input wire [N-1:0] bus2_node4,
    input wire [N-1:0] bus2_node5,
    output wire [N-1:0] bus2_out,
    
    /// BUS3 (output line)
    input wire [5:0] bus3_ctrl,
    input wire [N-1:0] bus3_in,
    input wire [N-1:0] bus3_node0_in,
    input wire [N-1:0] bus3_node1_in,
    input wire [N-1:0] bus3_node2_in,
    input wire [N-1:0] bus3_node3_in,
    input wire [N-1:0] bus3_node4_in,
    input wire [N-1:0] bus3_node5_in,
    output reg [N-1:0] bus3_node0_out,
    output reg [N-1:0] bus3_node1_out,
    output reg [N-1:0] bus3_node2_out,
    output reg [N-1:0] bus3_node3_out,
    output reg [N-1:0] bus3_node4_out,
    output reg [N-1:0] bus3_node5_out
);

    /// Route inputs to BUS1 depending on the control signal
    assign bus1_out =
        (bus1_ctrl[0] == 1'b1) ? bus1_node0 :
        (bus1_ctrl[1] == 1'b1) ? bus1_node1 :
        (bus1_ctrl[2] == 1'b1) ? bus1_node2 :
        (bus1_ctrl[3] == 1'b1) ? bus1_node3 :
        (bus1_ctrl[4] == 1'b1) ? bus1_node4 :
        (bus1_ctrl[5] == 1'b1) ? bus1_node5 :
        { N{ 1'b0 } };
    
    /// Route inputs to BUS2 depending on the control signal
    assign bus2_out =
        (bus2_ctrl[0] == 1'b1) ? bus2_node0 :
        (bus2_ctrl[1] == 1'b1) ? bus2_node1 :
        (bus2_ctrl[2] == 1'b1) ? bus2_node2 :
        (bus2_ctrl[3] == 1'b1) ? bus2_node3 :
        (bus2_ctrl[4] == 1'b1) ? bus2_node4 :
        (bus2_ctrl[5] == 1'b1) ? bus2_node5 :
        { N{ 1'b0 } };
    
    /// Route input signal of the BUS3 to correct output port
    always @*
    begin
        /// Defaults
        bus3_node0_out = bus3_node0_in;
        bus3_node1_out = bus3_node1_in;
        bus3_node2_out = bus3_node2_in;
        bus3_node3_out = bus3_node3_in;
        bus3_node4_out = bus3_node4_in;
        bus3_node5_out = bus3_node5_in;
        
        if (bus3_ctrl[0] == 1'b1)
            bus3_node0_out = bus3_in;
        else if (bus3_ctrl[1] == 1'b1)
            bus3_node1_out = bus3_in;
        else if (bus3_ctrl[2] == 1'b1)
            bus3_node2_out = bus3_in;
        else if (bus3_ctrl[3] == 1'b1)
            bus3_node3_out = bus3_in;
        else if (bus3_ctrl[4] == 1'b1)
            bus3_node4_out = bus3_in;
        else if (bus3_ctrl[5] == 1'b1)
            bus3_node5_out = bus3_in;
    end
endmodule
