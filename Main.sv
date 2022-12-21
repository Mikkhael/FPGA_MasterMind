module Main(

input wire CLK0,

input wire S1,
input wire S2,
input wire S3,

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
wire S3_DEB, S3_EDGE;

DEBOUNCE deb1(CLK_PLL, S1, S1_DEB);
DEBOUNCE deb2(CLK_PLL, S2, S2_DEB);
DEBOUNCE deb3(CLK_PLL, S3, S3_DEB);

EDGE_NEG edge1(CLK_PLL, S1_DEB, S1_EDGE);
EDGE_NEG edge2(CLK_PLL, S2_DEB, S2_EDGE);
EDGE_NEG edge3(CLK_PLL, S3_DEB, S3_EDGE);

reg [4:0] Vals [0:3] = '{default: 5'h0};


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

wire [8:0] font_rom_addr = display_type == 4 ? font_rom_addr2 : font_rom_addr1;
wire       font_rom_clk = display_type == 4 ? font_rom_clk2 : font_rom_clk1;
wire [3:0] font_rom_q;

wire [8:0] font_rom_addr1;
wire       font_rom_clk1;
wire [8:0] font_rom_addr2;
wire       font_rom_clk2;



//wire [6:0] font_rom2_addr;
//wire       font_rom2_clk;
//wire [3:0] font_rom2_q;

reg [3:0][3:0] font_test_nums [0:3] = '{default: 0};
reg [1:0]      font_test_curr_num = 0;

FONT_ROM font_rom(font_rom_addr, font_rom_clk, font_rom_q);
//FONT_ROM_ASYNC font_rom2(font_rom2_addr, font_rom2_clk, font_rom2_q);

st_GAME_STATE GS = '{default:0};


reg [2:0] color = 3'b001;

reg [2:0] display_type = 4;


wire [4:0] vga_mux [0:4];

VGA_Basic_Controller vga1(CLK_VGA, color, vga_mux[0][4:2], vga_mux[0][1], vga_mux[0][0]);
VGA_Grid_Controller  vga2(CLK_VGA,        vga_mux[1][4:2], vga_mux[1][1], vga_mux[1][0]);
VGA_RAM_Controller   vga3(CLK_VGA, ram_rclk, ram_raddr, ram_rdata, vga_mux[2][4:2], vga_mux[2][1], vga_mux[2][0]);
VGA_FONT_ROM_test_Controller  vga4(CLK_VGA, font_rom_clk1, font_rom_addr1, font_rom_q, font_test_nums, font_test_curr_num, vga_mux[3][4:2], vga_mux[3][1], vga_mux[3][0]);
VGA_Game_Renderer  vga5(CLK_VGA, font_rom_clk2, font_rom_addr2, font_rom_q, GS, vga_mux[4][4:2], vga_mux[4][1], vga_mux[4][0]);
//VGA_FONT_ROM2_test_Controller vga5(CLK_VGA, font_rom2_clk, font_rom2_addr, font_rom2_q, font_test_nums, font_test_curr_num, vga_mux[4][4:2], vga_mux[4][1], vga_mux[4][0]);


assign {VGA_R, VGA_G, VGA_B, VGA_HSYNC, VGA_VSYNC} = vga_mux[display_type];



always @(posedge CLK_PLL) begin

	ram_wen = 0;
	{LED3, LED2, LED1, LED0} = {1'b0, display_type[2:0]};
	
	if(S3_EDGE) begin
		Vals = '{default: 5'h0};
		display_type = display_type + 1'b1;
		if(display_type == 5) begin
			display_type = 0;
		end
	end
	
	case(display_type)
		0: begin
			if(S1_EDGE) begin
				color = color + 3'd1;
			end
			Vals[0] = color;
		end
		1: begin
		end
		2: begin
			if(S1_EDGE) begin
				ram_wdata = ram_wdata + 1'b1;
				ram_wen = 1;
			end
			if(S2_EDGE) begin
				ram_waddr = ram_waddr + 1'b1;
			end
			Vals[0][3:0] = ram_waddr;
			Vals[2][3:0] = ram_wdata[3:0];
			Vals[3][1:0] = ram_wdata[5:4];
		end
		3: begin
			if(S1_EDGE) begin
				font_test_curr_num = font_test_curr_num + 1'h1;
			end
			if(S2_EDGE) begin
				font_test_nums[font_test_curr_num] = font_test_nums[font_test_curr_num] + 8'h11;
			end
			Vals[0][1:0] = font_test_curr_num;
			Vals[1][3:0] = font_test_nums[font_test_curr_num][0];
			Vals[2][3:0] = font_test_nums[font_test_curr_num][1];
			Vals[3][1:0] = font_test_nums[font_test_curr_num][2][1:0];
		end
		4: begin
			if(S1_EDGE) begin
				GS.options.color = GS.options.color + 1'd1;
			end
			if(S2_EDGE) begin
				GS.main_menu.selected_element = GS.main_menu.selected_element + 1'd1;
			end
			Vals[0][3:0] = GS.main_menu.selected_element;
			Vals[1][3:0] = GS.options.color;
			Vals[2][3:0] = 0;
			Vals[3][1:0] = GS.state_name;
		end
	endcase
	
	
	
end

endmodule