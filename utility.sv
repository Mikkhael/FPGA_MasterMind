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
