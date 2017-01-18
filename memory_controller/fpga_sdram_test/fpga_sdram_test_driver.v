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
module fpga_sdram_test_driver
(
	input wire CLOCK_50,
	input wire [3:0] KEY,			/// KEY0 resets the test; KEY1 triggers test start
	output reg [9:0] LEDR,			/// LED0 - idle, LED1 - (write), LED2 - (read)
	output reg [6:0] HEX0,			/// Shows 1 if test passed, 0 on failure
	output wire [12:0] DRAM_ADDR,
	inout wire [15:0] DRAM_DQ,
	output wire [1:0] DRAM_BA,
	output wire DRAM_LDQM, DRAM_UDQM,
	output wire DRAM_RAS_N,
	output wire DRAM_CAS_N,
	output wire DRAM_CKE,
	output wire DRAM_CLK,
	output wire DRAM_WE_N,
	output wire DRAM_CS_N
);

	localparam MAX_ADDR = 25'h1ffffff; /// 32M
	localparam [2:0]
		idle = 0,
		running_test1 = 1,
		running_test2 = 2,
		passed = 3,
		failed = 4;
	
	wire sys_clk;
	wire reset_n;
	reg start_test1_n, start_test2_n;
	wire write_test1_n, read_test1_n, write_test2_n, read_test2_n;
	reg write_n, read_n;
	reg [1:0] state_reg, state_next;
	wire [24:0] addr_test1, addr_test2;
	reg [24:0] addr;
	wire [15:0] wr_data_test1, wr_data_test2, rd_data;
	reg [15:0] wr_data;
	wire rd_data_valid, wait_req;
	wire test1_done, test1_passed, test2_done, test2_passed;
	
	assign reset_n = KEY[0];
	
	/// PLL
	pll pll_unit(
		.refclk   (CLOCK_50),
		.rst      (~reset_n),
		.outclk_0 (sys_clk),
		.outclk_1 (DRAM_CLK),	/// Phase-shifted by -3ns compared to sys_clk
		.locked   ()
	);
	
	sdram_control_wrapper sdram_ctrl_unit(
		.address(addr),
		.byteenable_n(2'b00),
		.chipselect(1'b1),
		.writedata(wr_data),
		.read_n(read_n),
		.write_n(write_n),
		.readdata(rd_data),
		.readdatavalid(rd_data_valid),
		.waitrequest(wait_req),
		.clk(sys_clk),
		.dram_addr(DRAM_ADDR),
		.dram_ba(DRAM_BA),
		.dram_cas_n(DRAM_CAS_N),
		.dram_cke(DRAM_CKE),
		.dram_cs_n(DRAM_CS_N),
		.dram_dq(DRAM_DQ),
		.dram_dqm({ DRAM_UDQM, DRAM_LDQM }),
		.dram_ras_n(DRAM_RAS_N),
		.dram_we_n(DRAM_WE_N),
		.reset_n(reset_n));
	
	/// Test 1 (triggered by KEY[1])
	fpga_sdram_writeall_readall_test #(.MAX_ADDR(MAX_ADDR))
		writeall_readall_test(
			.clk(sys_clk)
			, .reset_n(reset_n)
			, .start_n(start_test1_n)
			, .rd_data(rd_data)
			, .rd_data_valid(rd_data_valid)
			, .wait_req(wait_req)
			, .addr(addr_test1)
			, .wr_data(wr_data_test1)
			, .write_n(write_test1_n)
			, .read_n(read_test1_n)
			, .test_done(test1_done)
			, .test_passed(test1_passed));
	
	/// Test 2 (triggered by KEY[2])
	fpga_sdram_writeone_readone_test #(.MAX_ADDR(MAX_ADDR))
		writeone_readone_test(
			.clk(sys_clk)
			, .reset_n(reset_n)
			, .start_n(start_test2_n)
			, .rd_data(rd_data)
			, .rd_data_valid(rd_data_valid)
			, .wait_req(wait_req)
			, .addr(addr_test2)
			, .wr_data(wr_data_test2)
			, .write_n(write_test2_n)
			, .read_n(read_test2_n)
			, .test_done(test2_done)
			, .test_passed(test2_passed));
	
	
	always @(posedge sys_clk, negedge reset_n)
		if (~reset_n)
			state_reg <= idle;
		else
			state_reg <= state_next;
	
	
	/// Test FSM
	always @*
	begin
		/// Defaults
		LEDR = 10'b0;
		state_next = state_reg;
		start_test1_n = 1'b1;
		start_test2_n = 1'b1;
		write_n = 1'b1;
		read_n = 1'b1;
		addr = 25'b0;
		wr_data = 16'b0;
		HEX0 = 7'h7F;
		
		case (state_reg)
			idle:
			begin
				LEDR[0] = 1'b1;
				if (~KEY[1])
				begin
					start_test1_n = 1'b0;
					state_next = running_test1;
				end
				else if (~KEY[2])
				begin
					start_test2_n = 1'b0;
					state_next = running_test2;
				end
			end
			
			running_test1:
			begin
				LEDR[1] = 1'b1;
				write_n = write_test1_n;
				read_n = read_test1_n;
				addr = addr_test1;
				wr_data = wr_data_test1;
				
				if (test1_done & test1_passed)
					state_next = passed;
				else if (test1_done & ~test1_passed)
					state_next = failed;
			end
			
			running_test2:
			begin
				LEDR[2] = 1'b1;
				write_n = write_test2_n;
				read_n = read_test2_n;
				addr = addr_test2;
				wr_data = wr_data_test2;
				
				if (test2_done & test2_passed)
					state_next = passed;
				else if (test2_done & ~test2_passed)
					state_next = failed;
			end
			
			failed:
			begin
				HEX0 = 7'b1000000;
			end
				
			passed:
			begin
				HEX0 = 7'b1001111;
			end
		endcase
	end
endmodule
