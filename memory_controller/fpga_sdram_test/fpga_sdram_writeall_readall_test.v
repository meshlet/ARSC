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
/// Tests SDRAM by writting the MAX_ADDR + 1 words to memory, and then
/// reading the memory and comparing the expected and actual memory words
module fpga_sdram_writeall_readall_test
#(
	parameter MAX_ADDR	/// The last ram address to write/read
)
(
	input wire clk, reset_n,
	input wire start_n,
	input wire [15:0] rd_data,
	input wire rd_data_valid, wait_req,
	output wire [24:0] addr,
	output wire [15:0] wr_data,
	output reg write_n, read_n,
	output reg test_done, test_passed
);

	localparam [3:0]
		idle = 0,
		write0 = 1,
		write1 = 2,
		write2 = 3,
		read0 = 4,
		read1 = 5,
		read2 = 6,
		passed = 7,
		failed = 8;
	
	reg [3:0] state_reg, state_next;
	reg [24:0] addr_reg, addr_next;
	reg [15:0] wr_data_reg, wr_data_next, rd_data_reg, rd_data_next;
	
	always @(posedge clk, negedge reset_n)
		if (~reset_n)
		begin
			state_reg <= idle;
			addr_reg <= 25'b0;
			wr_data_reg <= 16'b0;
			rd_data_reg <= 16'b0;
		end
		else
		begin
			state_reg <= state_next;
			addr_reg <= addr_next;
			wr_data_reg <= wr_data_next;
			rd_data_reg <= rd_data_next;
		end
	
	
	/// Test FSM
	always @*
	begin
		/// Defaults
		state_next = state_reg;
		addr_next = addr_reg;
		wr_data_next = wr_data_reg;
		rd_data_next = rd_data_reg;
		write_n = 1'b1;
		read_n = 1'b1;
		test_done = 1'b0;
		test_passed = 1'b0;
		
		case (state_reg)
			idle:
				if (~start_n)
				begin
					addr_next = 25'b0;
					wr_data_next = 16'b0;
					state_next = write0;
				end
			
			write0:
			begin
				write_n = 1'b0;
				state_next = write1;
			end
			
			write1:
				if (~wait_req)
					state_next = write2;
			
			write2:
				if (addr_reg == MAX_ADDR)
				begin
					wr_data_next = 16'b0;
					addr_next = 25'b0;
					state_next = read0;
				end
				else
				begin
					addr_next = addr_reg + 1;
					wr_data_next = wr_data_reg + 1;
					state_next = write0;
				end
			
			read0:
			begin
				read_n = 1'b0;
				state_next = read1;
			end
			
			read1:
				if (rd_data_valid)
				begin
					rd_data_next = rd_data;
					state_next = read2;
				end
				
			read2:
				if (rd_data_reg != wr_data_reg)
					state_next = failed;
				else if (addr_reg == MAX_ADDR)
					state_next = passed;
				else
				begin
					wr_data_next = wr_data_reg + 1;
					addr_next = addr_reg + 1;
					state_next = read0;
				end
			
			failed:
			begin
				test_done = 1'b1;
			end
				
			passed:
			begin
				test_done = 1'b1;
				test_passed = 1'b1;
			end
		endcase
	end
	
	/// Assign remaining output signals
	assign addr = addr_reg;
	assign wr_data = wr_data_reg;
	
endmodule
