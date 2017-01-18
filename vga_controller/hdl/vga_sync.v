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
/// VGA synchronization circuit that produces HSYNC and VSYNC signals used
/// to control the horizontal and vertical scans of the VGA monitor. The
/// circuit also produces the pixel_x and pixel_y signals that identify the
/// exact pixel that is being drawn, as well as the video_on signal that
/// is active when current pixel is within the displayable region. If this
/// signal is inactive, the RGB signal must be zero (black).
///
/// It is assumed that system clock cycle period is smaller or equal than
/// the pixel clock cycle (the rate at which pixels are scanned). The param
/// PXCLK_DURATION specifies how many system clock cycles make up a single
/// pixel clock cycle (i.e. if sys clk is 50MHz and pixel clk is 25MHz, than
/// PXCLK_DURATION is 2). Value PXCLK_DURATION - 1 must fit in PXCLKDUR_BITS.
///
/// The circuit also exposes the possibility to generate special index and
/// offset for pixels that can be used when multiple pixels are groupped together.
/// I.e. video RAM is organized as Mx16 bits and each 16-bit word contains five
/// pixels (3-bits per pixel, MSB unused). In order to access a specific pixel,
/// word address is needed as well as pixel offset within the word. vga_sync
/// circuit can generate both of these signals for every pixel. To enable this
/// feature set GENERATE_IDX_OFFSET param to non-zero value. Generated index
/// and offset signals are valid ONLY when video_on signal is active
module vga_sync
#(
    /// Default values are valid for 640x480 display with 25MHz pixel rate
    parameter LB = 48,                      /// Left border (horizontal back porch) - 40 pixel clock cycles
    parameter HD = 640,                     /// Horizontal display - 640 pixel clock cycles
    parameter RB = 16,                      /// Right border (horizontal front porch) - 16 pixels
    parameter HR = 96,                      /// Horizontal retrace - 96 pixels
    parameter TB = 33,                      /// Top border (vertial back porch) - 33 lines
    parameter VD = 480,                     /// Vertical display - 480 lines
    parameter BB = 10,                      /// Bottom border (vertial front porch) - 10 lines
    parameter VR = 2,                       /// Vertical retrace - 2 lines
    parameter HBITS = 10,                   /// Number of bits needed for HD + RB + HR + LB - 1
    parameter VBITS = 10,                   /// Number of bits needed for VD + BB + VR + TB - 1
    
    parameter PXCLK_DURATION,               /// Pixel clock cycle (the number of sys cycles in the pixel cycle)
    parameter PXCLKDUR_BITS,                /// Number of bits needed to store PXCLK_DURATION - 1
    
    parameter GENERATE_IDX_OFFSET = 0,      /// If not zero, index and offset will be generated for pixels
    parameter GROUP_SIZE,                   /// The number of pixels groupped together (offset is in [0,GROUP_SIZE-1])
    parameter IDXBITS,                      /// Number of bits needed to store HD*VD/GROUP_SIZE - 1
    parameter OFFBITS                       /// Number of bits needed to store GROUP_SIZE - 1
)
(
    input wire clk, reset_n,
    input wire start_n,                     /// Starts the synchronizer (if not already started)
    output reg hsync,                       /// Controls the horizontal scan
    output reg vsync,                       /// Controls the vertical scan
    output reg video_on,                    /// Is pixel within displayable region
    output wire pixel_tick,                 /// Active for one cycle in PXCLK_DURATION cycles
    output wire [HBITS-1:0] pixel_x,        /// X-axis coordinate (horizontal)
    output wire [VBITS-1:0] pixel_y,        /// Y-axis coordinate (vertical)
    output wire [IDXBITS-1:0] pixel_idx,    /// Pixel index (high-Z if GENERATE_IDX_OFFSET = 0)
    output wire [OFFBITS-1:0] pixel_offset  /// Pixel offset (high-Z if GENERATE_IDX_OFFSET = 0)
);

    localparam [0:0]
        IDLE = 0,
        RUN = 1;
    
    reg state_reg, state_next;
    reg [HBITS-1:0] h_count_reg, h_count_next;
    reg [VBITS-1:0] v_count_reg, v_count_next;
    reg [PXCLKDUR_BITS-1:0] clk_count_reg, clk_count_next;
    wire h_end, v_end;
    
    reg [IDXBITS-1:0] idx_counter_reg, idx_counter_next;
    reg [OFFBITS-1:0] off_counter_reg, off_counter_next;
    
    always @(posedge clk, negedge reset_n)
        if (~reset_n)
        begin
            state_reg <= IDLE;
            clk_count_reg <= { PXCLKDUR_BITS{ 1'b0 } };
            h_count_reg <= { HBITS{ 1'b0 } };
            v_count_reg <= { VBITS{ 1'b0 } };
            idx_counter_reg <= { IDXBITS { 1'b0 } };
            off_counter_reg <= { OFFBITS { 1'b0 } };
        end
        else
        begin
            state_reg <= state_next;
            clk_count_reg <= clk_count_next;
            h_count_reg <= h_count_next;
            v_count_reg <= v_count_next;
            idx_counter_reg <= idx_counter_next;
            off_counter_reg <= off_counter_next;
        end
    
    assign pixel_tick = (clk_count_reg == PXCLK_DURATION - 1);
    assign h_end = (h_count_reg == LB + HD + RB + HR - 1);
    assign v_end = (v_count_reg == TB + VD + BB + VR - 1);
    
    /// FSM for horizontal and vertical scanning
    always @*
    begin
        /// Defaults
        state_next = state_reg;
        h_count_next = h_count_reg;
        v_count_next = v_count_reg;
        clk_count_next = clk_count_reg;
        hsync = 1'b0;
        vsync = 1'b0;
        video_on = 1'b0;
        
        case (state_reg)
            IDLE:
                if (~start_n)
                begin
                    h_count_next = { HBITS{ 1'b0 } };
                    v_count_next = { VBITS{ 1'b0 } };
                    clk_count_next = { PXCLKDUR_BITS{ 1'b0 } };
                    state_next = RUN;
                end
            
            RUN:
            begin
                hsync = (h_count_reg < LB + HD + RB);
                vsync = (v_count_reg < TB + VD + BB);
                video_on = (
                    h_count_reg >= LB
                    && h_count_reg < LB + HD
                    && v_count_reg >= TB
                    && v_count_reg < TB + VD);
                
                if (pixel_tick)
                begin
                    clk_count_next = { PXCLKDUR_BITS{ 1'b0 } };
                    if (h_end)
                        h_count_next = { HBITS{ 1'b0 } };
                    else
                        h_count_next = h_count_reg + 1;
                    
                    if (h_end & v_end)
                        v_count_next = { VBITS{ 1'b0 } };
                    else if (h_end)
                        v_count_next = v_count_reg + 1;
                end
                else
                begin
                    clk_count_next = clk_count_reg + 1;
                end
            end
        endcase
    end
    
    /// Index/offset generation is included only if GENERATE_IDX_OFFSET != 0
    generate
        if (GENERATE_IDX_OFFSET == 0)
            always @*
            begin
                idx_counter_next = { IDXBITS { 1'bz } };
                off_counter_next = { OFFBITS { 1'bz } };
            end
        else
            always @*
            begin
                /// Defaults
                idx_counter_next = idx_counter_reg;
                off_counter_next = off_counter_reg;
                
                if (state_reg == RUN)
                    if (pixel_tick)
                        if (video_on)
                            if (off_counter_reg == GROUP_SIZE - 1)
                            begin
                                off_counter_next = { OFFBITS{ 1'b0 } };
                                idx_counter_next = idx_counter_reg + 1;
                            end
                            else
                                off_counter_next = off_counter_reg + 1;
                        else if (v_end)
                        begin
                            idx_counter_next = { IDXBITS{ 1'b0 } };
                            off_counter_next = { OFFBITS{ 1'b0 } };
                        end
            end
    endgenerate
    
    /// Assign remaining outputs
    assign pixel_x = h_count_reg - LB;
    assign pixel_y = v_count_reg - TB;
    assign pixel_idx = idx_counter_reg;
    assign pixel_offset = off_counter_reg;
    
endmodule
