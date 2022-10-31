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
output reg LED3 = 0,

output reg VGA_R = 0,
output reg VGA_G = 0,
output reg VGA_B = 0,
output reg VGA_HSYNC = 0,
output reg VGA_VSYNC = 0

);

wire pll_areset = 0;

wire CLK_PLL;
wire CLK_PLL2;
wire CLK_VGA;
PLL main_pll(pll_areset, CLK0, CLK_PLL, CLK_PLL2, CLK_VGA);

wire S1_DEB, S1_EDGE;
wire S2_DEB, S2_EDGE;

DEBOUNCE deb1(CLK_PLL, S1, S1_DEB);
DEBOUNCE deb2(CLK_PLL, S2, S2_DEB);

EDGE_NEG edge1(CLK_PLL, S1_DEB, S1_EDGE);
EDGE_NEG edge2(CLK_PLL, S2_DEB, S2_EDGE);

reg [1:0] CurrentVal = 0;
reg [4:0] Vals [0:3] = '{ 5'h0, 5'h2, 5'h4, 5'h8 };


SegmentDisplay segdisp1(CLK_PLL2, Vals, {DS4, DS3, DS2, DS1}, {SEG_DP, SEG_G, SEG_F, SEG_E, SEG_D, SEG_C, SEG_B, SEG_A});

reg [3:0] ram_waddr = 0;
reg [5:0] ram_wdata = 0;
wire 		 ram_wclk  = CLK_PLL;
reg 		 ram_wen   = 0;

wire [3:0] ram_raddr;
wire [7:0] ram_rdata;
wire 		  ram_rclk;

wire [7:0] ram_wdata_full;
assign ram_wdata_full = {1'b0, 1'b0, ram_wdata};

VIDEORAM videoram(ram_wdata_full, ram_raddr, ram_rclk, ram_waddr, ram_wclk, ram_wen, ram_rdata);


reg [2:0] color = 3'b001;

reg [2:0] display_type = 0;

wire [4:0] vga_temp0;
wire [4:0] vga_temp1;
wire [4:0] vga_temp2;

VGA_Basic_Controller vga1(CLK_VGA, color, vga_temp0[4:2], vga_temp0[1], vga_temp0[0]);
VGA_Grid_Controller  vga2(CLK_VGA,        vga_temp1[4:2], vga_temp1[1], vga_temp1[0]);
VGA_RAM_Controller  vga3(CLK_VGA, ram_rclk, ram_raddr, ram_rdata, vga_temp2[4:2], vga_temp2[1], vga_temp2[0]);

assign {VGA_R, VGA_G, VGA_B, VGA_HSYNC, VGA_VSYNC} = display_type == 0 ? vga_temp0 : (display_type == 1 ? vga_temp1 : vga_temp2);

always @(posedge CLK_PLL) begin

	ram_wen = 0;

	{LED1, LED0} = ~CurrentVal;
	{LED3, LED2} = ~Vals[CurrentVal][1:0];
	if(S1_EDGE) begin
		Vals[CurrentVal][4] = 0;
		CurrentVal = CurrentVal + 2'd1;
		Vals[CurrentVal][4] = 1;
		color = color + 3'd1;
		ram_wdata = ram_wdata + 1'b1;
		ram_wen = 1;
	end
	if(S2_EDGE) begin
		Vals[CurrentVal][3:0] = Vals[CurrentVal][3:0] + 4'd1;
		if(display_type == 2'd2) begin
			if(ram_waddr == 4'b1111)
				display_type = 3;
			ram_waddr = ram_waddr + 1'b1;
		end else begin
			display_type = display_type + 1'b1;
		end
		
		if(display_type == 3)
			display_type = 0;
	end
	
end

endmodule