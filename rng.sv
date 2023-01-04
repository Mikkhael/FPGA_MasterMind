module RNG(
	input clk,
	input en,
	input [31:0] seed,
	output wire [31:0] res,
	output wire [63:0] res_full
);


localparam [31:0] init_state = 32'd2463534242;
localparam [31:0] multiplier = 32'd3084775641;

reg       [31:0] state      = init_state;
reg [63:0] mul_res = 0;

assign res = mul_res[63:32];
assign res_full = mul_res;

always @(posedge clk) begin

	if(seed) begin
		state = seed;
	end

	if(en) begin
		state ^= (state << 13);
		state ^= (state >> 17);
		state ^= (state << 5);
		
		mul_res = state * multiplier;
		mul_res[63:32] = state;
	end

	//mul_res[63:32] = state;
end


endmodule
