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
/// I/O CONTROLLER
///
///
module io_controller
#(
	parameter N						/// Bus width
)
(
	input wire clk,
	input wire reset_n,
	input wire start_n,
	input wire io_device,			/// Identifies I/O device (0 or 1)
	input wire rd_input_n,			/// Causes I/O controller to read data from io_device
	input wire wr_output_n,			/// Causes I/O controller to write data to io_device
	input wire [N-1:0] addr,		/// Destination address for io_device (if required by the device)
	input wire [N-1:0] wr_data,		/// Data to write to the io_device
	
	output wire io_done,			/// High for single cycle after I/O op has been completed
	output wire [N-1:0] rd_data,	/// Data read from the input device
	
	/// To VGA
	output wire [3:0]  vga_r,		/// Red color signal
	output wire [3:0]  vga_g,		/// Green color signal
	output wire [3:0]  vga_b,		/// Blue color signal
	output wire 	   vga_hs,		/// Horizontal sync
	output wire 	   vga_vs		/// Vertical sync
);

	localparam [0:0]
		VGA_INPUT = 0,
		KBD_INPUT = 1;
	
	localparam [0:0]
		VGA_OUTPUT = 0;
	
	wire vga_op_done, kbd_op_done;
	wire [N-1:0] vga_data, kbd_data;
	
	vga_controller
	#(
		.N(N)
	)
	vga_ctrl_unit
	(
		.clk(clk)
		, .reset_n(reset_n)
		, .start_n(start_n)
		, .rd_px_n(rd_input_n || (io_device != VGA_INPUT))
		, .wr_px_n(wr_output_n || (io_device != VGA_OUTPUT))
		, .px_addr(addr)
		, .px_data_in(wr_data)
		, .io_done(vga_op_done)
		, .px_data_out(vga_data)
		, .vga_r(vga_r)
		, .vga_g(vga_g)
		, .vga_b(vga_b)
		, .vga_hs(vga_hs)
		, .vga_vs(vga_vs)
	);
	
	/// FIXME: fix once Keyboard controller is implemented
	assign kbd_op_done = 1'b1;
	assign kbd_data = { N{ 1'b0 } };
	
	assign { io_done, rd_data } =
		(io_device == VGA_INPUT || io_device == VGA_OUTPUT) ? { vga_op_done, vga_data } :
		(io_device == KBD_INPUT)							? { kbd_op_done, kbd_data  } :
															  { 1'b1, { N{ 1'b0 } }   } ;
	
endmodule
