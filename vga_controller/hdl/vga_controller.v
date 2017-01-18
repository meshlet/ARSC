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
/// ARSC VGA CONTROLLER
///
/// Performs VGA synchronization (vga_sync circuit) and drives drawing by
/// continuously reading the video memory and feeding the data through the
/// VGA output bus. It also enables reading the pixel data from the video
/// RAM and writting the pixel data to video RAM
module vga_controller
#(
	parameter N							/// Bus width
)
(
	input  wire 	    clk,
	input  wire		    reset_n,
	input  wire		    start_n,		/// Starts the vga_controller (if not already running)
	input  wire         rd_px_n,		/// Causes VGA controller to read data from video RAM
	input  wire         wr_px_n,		/// Causes VGA controller to write data to video RAM
	input  wire [N-1:0] px_addr,		/// Pixel address in the video RAM
	input  wire [N-1:0] px_data_in,		/// Pixel data
	
	output wire         io_done,		/// High for one cycle after read/write has been completed
	output wire [N-1:0] px_data_out,	/// Pixel data at px_addr video ram location
	
	/// To VGA
	output reg [3:0]    vga_r,			/// Red color signal
	output reg [3:0]    vga_g,			/// Green color signal
	output reg [3:0]    vga_b,			/// Blue color signal
	output wire 	    vga_hs,			/// Horizontal sync
	output wire 	    vga_vs			/// Vertical sync
);

	localparam [0:0]
		IDLE = 0,
		DRAW = 1;
		
	reg  state_reg, state_next;
	wire video_on, pixel_tick;
	wire [N-1:0] internal_addr;
	wire [N-1:0] internal_px_data;
	wire [2:0] pixel_offset;
	wire [2:0]  pixel_data_3bit;
	wire [11:0] pixel_data_12bit;
	
	/// Video ram
	video_ram video_ram_unit
	(
		.address(px_addr),
		.address2(internal_addr),
		.byteenable(2'b11),
		.byteenable2(2'b11),
        .chipselect(1'b1),
		.chipselect2(1'b1),
        .clk(clk),
		.clk2(clk),
        .clken(1'b1),
		.clken2(1'b1),
        .reset(),
		.reset2(),
        .reset_req(~reset_n),
		.reset_req2(~reset_n),
        .write(~wr_px_n),
		.write2(),
        .writedata(px_data_in),
		.writedata2(),
        .readdata(px_data_out),
		.readdata2(internal_px_data));
	
	/// VGA sync circuit
	vga_sync
	#(
		.PXCLK_DURATION(2)
		, .PXCLKDUR_BITS(1)
		, .GENERATE_IDX_OFFSET(1)
        , .GROUP_SIZE(5)
        , .IDXBITS(16)
        , .OFFBITS(3)
	)
	vga_sync_unit
	(
		.clk(clk)
		, .reset_n(reset_n)
		, .start_n(start_n)
		, .hsync(vga_hs)
		, .vsync(vga_vs)
		, .video_on(video_on)
		, .pixel_tick(pixel_tick)
		, .pixel_x()
		, .pixel_y()
		, .pixel_idx(internal_addr)
		, .pixel_offset(pixel_offset)
	);
	
	/// Extract single pixel (3-bits) from 16-bit video ram word
	assign pixel_data_3bit =
		(pixel_offset == 3'b000) ? internal_px_data[2:0]   :
		(pixel_offset == 3'b001) ? internal_px_data[5:3]   :
		(pixel_offset == 3'b010) ? internal_px_data[8:6]   :
		(pixel_offset == 3'b011) ? internal_px_data[11:9]  :
		(pixel_offset == 3'b100) ? internal_px_data[14:12] :
								   3'b000 		  		   ;
	
	/// 3-bit color to 12-bit color decoder
	color_3b_12b_decoder color_decoder
	(
		.color_3bit(pixel_data_3bit)
		, .color_12bit(pixel_data_12bit)
	);
	
	always @(posedge clk, negedge reset_n)
		if (~reset_n)
			state_reg <= IDLE;
		else
			state_reg <= state_next;
	
	/// VGA controller FSM
	always @*
	begin
		/// Defaults
		{ vga_r, vga_g, vga_b } = 12'b0;
		state_next = state_reg;
		
		case (state_reg)
			IDLE:
				if (~start_n)
					state_next = DRAW;
			
			DRAW:
				if (video_on & pixel_tick)
					{ vga_r, vga_g, vga_b } = pixel_data_12bit;
		endcase
	end
	
	/// As video RAM read and write ops take one cycle, io_done can be active
	/// all the time
	assign io_done = 1'b1;
	
endmodule
