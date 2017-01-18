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
/// 3-BIT TO 12-BIT COLOR DECODER
///
/// Decodes 3-bit RGB signal (1-bit for red, green and blue) to 12-bit RGB signal
/// (4-bits for each color)
module color_3b_12b_decoder
(
	input wire  [2:0]  color_3bit,		/// 3-bit RGB signal
	output wire [11:0] color_12bit		/// 12-bit RGB signal
);

	one_to_four_decoder decoder_1b_4b_red
	(
		.in(color_3bit[2])
		, .out(color_12bit[11:8])
	);
	
	one_to_four_decoder decoder_1b_4b_green
	(
		.in(color_3bit[1])
		, .out(color_12bit[7:4])
	);
	
	one_to_four_decoder decoder_1b_4b_blue
	(
		.in(color_3bit[0])
		, .out(color_12bit[3:0])
	);
	
endmodule
