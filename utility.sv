module EDGE_POS(
	input wire clk,
	input wire in,
	output reg out = 0
);

	reg last = 0;
	always @(posedge clk) begin
		out  = ~last & in;
		last = in;
	end

endmodule

module EDGE_NEG(
	input wire clk,
	input wire in,
	output reg out = 0
);

	reg last = 0;
	always @(posedge clk) begin
		out  = last & ~in;
		last = in;
	end

endmodule

module EDGE_ANY(
	input wire clk,
	input wire in,
	output reg out = 0
);

	reg last = 0;
	always @(posedge clk) begin
		out  = last ^ in;
		last = in;
	end

endmodule


module CLK_DIV #(parameter DIV_BITS)
(
	input wire in,
	output wire out
);
	reg [DIV_BITS-1:0] counter = 0;
	assign out = counter[DIV_BITS-1];
	always @(posedge in)
		counter = counter + 1'd1;
endmodule

module DEBOUNCE(
	input wire clk,
	input wire in,
	output reg out = 0
);

	reg last = 0;
	reg [10:0] counter = 0;

	always @(posedge clk) begin
		if(last == in) 
			counter = counter + 11'd1;
		else 
			counter = 0;
			
		if(counter[10]) begin
			out = last;
			counter = 0;
		end
		last = in;
	end
endmodule



module DIV_MOD #(
	parameter base = 4'd10,
	parameter W_in  = 4'd9,
	parameter W_mod = 4'd4,
	parameter W_div = W_in
)(
	input wire [W_in-1:0]  in,
	output reg [W_div-1:0] div,
	output reg [W_mod-1:0] mod
);
	
	// To avoid implicit truncatino warning
	function [W_mod-1:0] truncate_mod(input [W_in-1:0] val);
		truncate_mod = val[W_mod-1:0];
	endfunction
	function [W_div-1:0] truncate_div(input [W_in-1:0] val);
		truncate_div = val[W_div-1:0];
	endfunction
	
	always @(*) begin
		div = truncate_div(in / base);
		mod = truncate_mod(in % base);
	end

endmodule