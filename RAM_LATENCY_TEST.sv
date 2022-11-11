module RAM_LATENCY_TEST(

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
wire CLK_VGA_old;
PLL main_pll(pll_areset, CLK0, CLK_PLL, CLK_PLL2, CLK_VGA);

//reg [3:0] vga_counter = 0;
//always @(posedge CLK_VGA_old) begin
//	if(vga_counter == 4'd1) begin
//		CLK_VGA = ~CLK_VGA;
//		vga_counter <= 0;
//	end else begin
//		vga_counter <= vga_counter + 1'b1;
//	end
//end

wire S1_DEB, S1_EDGE;
wire S2_DEB, S2_EDGE;

DEBOUNCE deb1(CLK_PLL, S1, S1_DEB);
DEBOUNCE deb2(CLK_PLL, S2, S2_DEB);

EDGE_NEG edge1(CLK_VGA, S1_DEB, S1_EDGE);
EDGE_NEG edge2(CLK_VGA, S2_DEB, S2_EDGE);

reg [1:0] CurrentVal = 0;
reg [4:0] Vals [0:3] = '{ 5'h0, 5'h0, 5'h0, 5'h0 };


SegmentDisplay segdisp1(CLK_PLL, Vals, {DS4, DS3, DS2, DS1}, {SEG_DP, SEG_G, SEG_F, SEG_E, SEG_D, SEG_C, SEG_B, SEG_A});

reg [3:0] ram_waddr = 0;
reg [7:0] ram_wdata = 0;
reg 		 ram_wclk  = 0;
reg 		 ram_wen   = 0;

reg  [3:0] ram_raddr = 0;
wire [7:0] ram_rdata;
wire 		  ram_rclk = CLK_VGA;

VIDEORAM videoram(ram_wdata, ram_raddr, ram_rclk, ram_waddr, ram_wclk, ram_wen, ram_rdata);


reg [2:0] state = 0;
reg disp_type = 0;
reg [7:0] delay = 0;


always @(posedge CLK_VGA) begin

	if(S2_EDGE) begin
		disp_type <= ~disp_type;
	end

	case(disp_type)
		0: begin
			Vals[3][3:0] <= ram_rdata[3:0];
			Vals[2][3:0] <= ram_raddr[3:0];
			Vals[1][3:0] <= delay[7:4];
			Vals[0][3:0] <= delay[3:0];
		end
		1: begin
			Vals[3][3:0] <= state;
			Vals[2][3:0] <= ram_raddr;
			Vals[1][3:0] <= ram_rdata[3:0];
			Vals[0][3:0] <= ram_wdata[3:0];
		end
	endcase
	Vals[3][4] <= disp_type;
	Vals[2][4] <= (state == 0);
	Vals[1][4] <= (state == 2);
	Vals[0][4] <= (state == 3);

	case(state)
	0: begin
		if(S1_EDGE) begin
			ram_raddr <= ram_raddr + 1'b1;
			//ram_wen <= 1;
			//ram_wclk <= 1;
			delay <= 0;
			state <= 2;
		end
	end
	2: begin
			//ram_rclk <= 0;
			if(ram_raddr == ram_rdata) begin
				state <= 3;
			end else begin
				delay <= delay + 1'h1;
			end
	end
	3: begin
			if(!S1_EDGE) begin
				state <= 0;
			end
	end
	endcase

	
end

endmodule