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
/// ARSC ALU 
///
/// The ALU accepts to N-bit input buses and produces a single N-bit output bus along with
/// a set of status signals. The following operations are supported:
///
/// add  - adds inputs and may set cr (carry) and of (overflow) status bits
/// comp - output is the complement (all bits reversed) of the input 1 (input 2 not used)
/// shr  - output is input 1 shifted to the right by 1 bit (MSB preserved, input 2 not used)
/// shl  - output is input 1 shifted to the left by 1 bit (LSB is zero, input 2 not used).
///        If the sign bit changes of (overflow) flag is set
/// and  - performs bit and operation on inputs
/// or   - performs bit or operation on inputs
/// xor  - performs bit xor operation on inputs
/// tra1 - transfers input 1 to output
/// tra2 - transfers input 2 output
///
/// If multiple control its are set, ALU will execute the operation according to the above
/// order (i.e. if both add and rt1 are 1, ALU performs add). The following status flags are
/// produced:
///
/// cr (carry) - set IFF the addition results in a carry bit
/// of (overflow) - set either during add or shl operation as explained
module arsc_alu
#(
    parameter N     /// Bus width
)
(
    input wire add_cmd,
    input wire comp_cmd,
    input wire shr_cmd,
    input wire shl_cmd,
    input wire and_cmd,
    input wire or_cmd,
    input wire xor_cmd,
    input wire tra1_cmd,
    input wire tra2_cmd,
    input wire [N-1:0] in1, in2,
    output wire cr, of,
    output wire [N-1:0] out
);

    wire [N:0] bus;
    
    assign bus =
        (add_cmd)   ? in1 + in2                         :
        (comp_cmd)  ? ~in1                              :
        (shr_cmd)   ? { 1'b0, in1[N-1], in1[N-1:1] }    :
        (shl_cmd)   ? { in1[N-1], in1[N-2:0], 1'b0 }    :
        (and_cmd)   ? { 1'b0, in1 & in2 }               :
        (or_cmd)    ? { 1'b0, in1 | in2 }               :
        (xor_cmd)   ? { 1'b0, in1 ^ in2 }               :
        (tra1_cmd)  ? { 1'b0, in1 }                     :
        (tra2_cmd)  ? { 1'b0, in2 }                     :
                      { (N+1) { 1'b0 } }                ;
    
    assign cr = bus[N] & add_cmd;
    assign of =
        ((add_cmd & ~(in1[N-1] ^ in2[N-1]) & (bus[N-1] ^ in1[N-1])) ||
        (shl_cmd & (bus[N] ^ bus[N-1])));
    
    assign out = bus[N-1:0];
    
endmodule
