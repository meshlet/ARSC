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
/// BINARY DECREMENTAL COUNTER
///
/// N-bit binary counter that can: keep its current value, load a new value or
/// decrement the current value, with asynchronous reset_n input. Flag zero is
/// set when counter is down to zero value
module dec_bin_counter
#(
    parameter N = 8
)
(
    input wire clk, reset_n,
    input wire load,            /// Load counter with 'in'
    input wire dec,            /// If high decrementing is enabled
    input wire [N-1:0] in,      /// Loaded to the counter if load is high
    output wire zero,           /// High if counter contains zero
    output wire [N-1:0] out     /// Currect value of the counter
);
  
    reg [N-1:0] q_next, q_reg;

    always @(posedge clk, negedge reset_n)
        if (~reset_n)
            q_reg <= 0;
        else
            q_reg <= q_next;
  
    /// Combinational circuit that produces the next state
    always @*
        if (load)
            q_next = in;
        else if (dec)
             q_next = q_reg - 1;
        else
            q_next = q_reg;
  
    /// Set output signals
    assign out = q_reg;
    assign zero = (q_reg == { N{ 1'b0 } });
  
endmodule
