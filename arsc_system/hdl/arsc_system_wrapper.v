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
/// ARSC SYSTEM WRAPPER
///
/// Instantiates the ARSC system and connects the FPGA pins to correct arsc_system pins.
/// This module exists only to separate the arsc_system pins from the actual FPGA pins
/// that will be used
module arsc_system_wrapper
(
	input wire CLOCK_50,			/// Reference 50MHz clock
	input wire [3:0] KEY,			/// KEY[0] - reset_n, KEY[1] - start_n
	output wire [9:0] LEDR,			/// LEDR[0] - ARSC running
	
	/// SDRAM signals
	output wire [12:0] DRAM_ADDR,
	inout wire [15:0] DRAM_DQ,
	output wire [1:0] DRAM_BA,
	output wire DRAM_LDQM,
	output wire DRAM_UDQM,
	output wire DRAM_RAS_N,
	output wire DRAM_CAS_N,
	output wire DRAM_CKE,
	output wire DRAM_CLK,
	output wire DRAM_WE_N,
	output wire DRAM_CS_N,
	
	/// VGA signals
	output wire [3:0] VGA_R,		/// Red color
	output wire [3:0] VGA_G,		/// Green color
	output wire [3:0] VGA_B,		/// Blue color
	output wire VGA_HS,				/// Horizontal sync
	output wire VGA_VS				/// Vertical sync
);

	arsc_system arsc
	(
		.ref_clk(CLOCK_50)
		, .reset_n(KEY[0])
		, .start_n(KEY[1])
		, .running(LEDR)
		, .dram_addr(DRAM_ADDR)
		, .dram_ba(DRAM_BA)
		, .dram_cas_n(DRAM_CAS_N)
		, .dram_cke(DRAM_CKE)
		, .dram_cs_n(DRAM_CS_N)
		, .dram_dq(DRAM_DQ)
		, .dram_dqm({ DRAM_UDQM, DRAM_LDQM })
		, .dram_ras_n(DRAM_RAS_N)
		, .dram_we_n(DRAM_WE_N)
		, .dram_clk(DRAM_CLK)
		, .vga_r(VGA_R)
		, .vga_g(VGA_G)
		, .vga_b(VGA_B)
		, .vga_hs(VGA_HS)
		, .vga_vs(VGA_VS)
	);
	
endmodule
	