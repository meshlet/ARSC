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
/// Testbench for the debouncer circuit
module debouncer_tb;
  
  localparam
    T = 20,
    INIT = 3;
    
  reg clk, reset_n, in;
  wire db_level, db_tick, db_tick_n;
  
  debouncer #(.INIT(INIT))
    uut(.clk(clk)
        , .reset_n(reset_n)
        , .in(in)
        , .db_level(db_level)
        , .db_tick(db_tick)
        , .db_tick_n(db_tick_n));
  
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
    @(negedge clk);
    
    reset_n = 1'b1;
    in = 1'b1;
    @(negedge clk);
    
    in = 1'b0;
    @(negedge clk);
    
    in = 1'b1;
    repeat(2*INIT) @(negedge clk);
    
    in = 1'b0;
    @(negedge clk);
    
    in = 1'b1;
    @(negedge clk);
    
    in = 1'b0;
    repeat(2*INIT) @(negedge clk);
    
    $stop;
    
  end
endmodule
