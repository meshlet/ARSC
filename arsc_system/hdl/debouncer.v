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
/// DEBOUNCER
///
/// Debouncer circuit used to eliminate the bouncing effect of the input signal
/// and provide a stable output signal (i.e. when using HW switches). Output
/// 'db_level' is the debounced 'in' signal. 'db_tick' output will be high for
/// a single cycle when low-to-high transition has been experienced. 'db_tick_n'
/// output will be low for a single clock cycle when high-to-low transition has
/// been experienced. These two outputs allows to use the debouncer as a positive
/// and negative edge detector respectively.
///
/// The user can control the time the debouncer is waiting before it accepts
/// the signal change by setting the INIT parameter. INIT parameter must be in
/// range [0, 2^21 - 1], and the actual waiting time is: T = (1/f) * INIT where
/// 'f' is the frequency of clock signal 'clk'. For debouncer to work reliably,
/// the 'T' should be at least 20 ms
module debouncer
#(
    parameter INIT
)
(
    input wire clk, reset_n,
    input wire in,              /// Input signal
    output reg db_level,        /// Debounced 'in' signal
    output reg db_tick,         /// Set to HIGH for a single cycle on low-to-high
    output reg db_tick_n        /// Set to LOW for a single cycle on high-to-low
);
  
    localparam [1:0]
        zero = 0,
        wait1 = 1,
        one = 2,
        wait0 = 3;
  
    reg [1:0] state_reg, state_next;
    reg load, dec;
    wire zero_flag;
    wire [20:0] counter_out;
  
    dec_bin_counter #(.N(21))
        counter_unt(.clk(clk)
                    , .reset_n(reset_n)
                    , .load(load)
                    , .dec(dec)
                    , .in(INIT)
                    , .zero(zero_flag)
                    , .out(counter_out));
  
    always @(posedge clk, negedge reset_n)
        if (~reset_n)
            state_reg <= zero;
        else
            state_reg <= state_next;
  
    /// Next-state logic
    always @*
    begin
        /// Defaults
        state_next = state_reg;
        load = 1'b0;
        dec = 1'b0;
        db_level = 1'b0;
        db_tick = 1'b0;
        db_tick_n = 1'b1;
    
        case (state_reg)
            zero:
                if (in)
                begin
                    load = 1'b1;
                    state_next = wait1;
                end
          
            wait1:
                if (in)
                    if (zero_flag)
                    begin
                        state_next = one;
                        db_tick = 1'b1;
                    end
                    else
                    begin
                        dec = 1'b1;
                    end
                else
                    state_next = zero;
          
            one:
            begin
                db_level = 1'b1;
                if (~in)
                begin
                    load = 1'b1;
                    state_next = wait0;
                end
            end
          
            wait0:
            begin
                db_level = 1'b1;
                if (~in)
                    if (zero_flag)
                    begin
                        state_next = zero;
                        db_tick_n = 1'b0;
                    end
                    else
                    begin
                        dec = 1'b1;
                    end
                else
                    state_next = one;
            end
        endcase
    end
endmodule
