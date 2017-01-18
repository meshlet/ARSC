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
/// Testbench for the vga_sync circuit
module vga_sync_tb;
    
    localparam
        T = 20,
        LB = 2,
        HD = 10,
        RB = 3,
        HR = 2,
        TB = 2,
        VD = 4,
        BB = 1,
        VR = 2,
        HBITS = 5,
        VBITS = 4,
        /// Pixel clock cycle = 2 system clock cycles
        PXCLK_DURATION = 2,
        PXCLKDUR_BITS = 1,
        LINE = LB + HD + RB + HR,
        SCREEN = TB + VD + BB + VR,
        GENERATE_IDX_OFFSET = 1,
        GROUP_SIZE = 5,
        IDXBITS = 16,
        OFFBITS = 3;
        
    reg clk, reset_n, start_n;
    wire hsync, vsync, video_on, pixel_tick;
    wire [HBITS-1:0] pixel_x;
    wire [VBITS-1:0] pixel_y;
    wire [IDXBITS-1:0] pixel_idx;
    wire [OFFBITS-1:0] pixel_offset;
    
    vga_sync
        #(.LB(LB)
          , .HD(HD)
          , .RB(RB)
          , .HR(HR)
          , .TB(TB)
          , .VD(VD)
          , .BB(BB)
          , .VR(VR)
          , .HBITS(HBITS)
          , .VBITS(VBITS)
          , .PXCLK_DURATION(PXCLK_DURATION)
          , .PXCLKDUR_BITS(PXCLKDUR_BITS)
          , .GENERATE_IDX_OFFSET(GENERATE_IDX_OFFSET)
          , .GROUP_SIZE(GROUP_SIZE)
          , .IDXBITS(IDXBITS)
          , .OFFBITS(OFFBITS))
        
        uut(.clk(clk)
            , .reset_n(reset_n)
            , .start_n(start_n)
            , .hsync(hsync)
            , .vsync(vsync)
            , .video_on(video_on)
            , .pixel_tick(pixel_tick)
            , .pixel_x(pixel_x)
            , .pixel_y(pixel_y)
            , .pixel_idx(pixel_idx)
            , .pixel_offset(pixel_offset));
    
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
        @(negedge clk);
        
        reset_n = 1'b1;
        start_n = 1'b0;
        repeat(3*LINE*SCREEN*PXCLK_DURATION) @(negedge clk);
        
        $stop;
        
    end
endmodule