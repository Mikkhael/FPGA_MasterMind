module Main(

input wire CLK0,

input wire S1,
input wire S2,

output reg SEG_A = 0,
output reg SEG_B = 0,
output reg SEG_C = 0,
output reg SEG_D = 0,
output reg SEG_E = 0,
output reg SEG_F = 0,
output reg SEG_G = 0,
output reg SEG_DP = 0,

output reg DS1 = 0,
output reg DS2 = 0,
output reg DS3 = 0,
output reg DS4 = 0,

output reg LED0 = 0,
output reg LED1 = 0,
output reg LED2 = 0,
output reg LED3 = 0

);

wire CLK_PLL;
PLL main_pll(CLK0, CLK_PLL);

wire S1_DEB, S1_EDGE;
wire S2_DEB, S2_EDGE;

DEBOUNCE deb1(CLK_PLL, S1, S1_DEB);
DEBOUNCE deb2(CLK_PLL, S2, S2_DEB);

EDGE_NEG edge1(CLK_PLL, S1_DEB, S1_EDGE);
EDGE_NEG edge2(CLK_PLL, S2_DEB, S2_EDGE);

reg [1:0] CurrentVal = 0;
reg [4:0] Vals [0:3] = '{ 5'h0, 5'h2, 5'h4, 5'h8 };

wire CLK_REFRESH;
CLK_DIV#(.DIV_BITS(1)) CLK_REFRESH_module(CLK_PLL, CLK_REFRESH);

SegmentDisplay segdisp1(CLK_REFRESH, Vals, {DS4, DS3, DS2, DS1}, {SEG_DP, SEG_G, SEG_F, SEG_E, SEG_D, SEG_C, SEG_B, SEG_A});

always @(posedge CLK_PLL) begin

	{LED1, LED0} = ~CurrentVal;
	{LED3, LED2} = ~Vals[CurrentVal][1:0];
	if(S1_EDGE) begin
		Vals[CurrentVal][4] = 0;
		CurrentVal = CurrentVal + 2'd1;
		Vals[CurrentVal][4] = 1;
	end
	if(S2_EDGE) begin
		Vals[CurrentVal][3:0] = Vals[CurrentVal][3:0] + 4'd1;
	end
	
end

endmodule