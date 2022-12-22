module Main_Game(

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

output wire LED0,
output wire LED1,
output wire LED2,
output wire LED3,

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

reg [3:0] LEDS = 0;
assign {LED3, LED2, LED1, LED0} = ~LEDS;

wire [8:0] font_rom_addr;
wire       font_rom_clk;
wire [3:0] font_rom_q;
FONT_ROM font_rom(font_rom_addr, font_rom_clk, font_rom_q);

st_GAME_STATE GS = '{default:0,
	options: '{
		default:0,
		PIX_W: 5,
		PIX_H: 5
	},
	render: '{
		default:0,
		charlines: 20,
		charcols:  20,
	   menu_charlines_offset_selected: 2,
	   menu_charlines_offset: 2,
	   menu_charcols_offset_selected: 2,
	   menu_charcols_offset: 2,
		palette: palettes[0]
	}
};

VGA_Game_Renderer vga(CLK_VGA, font_rom_clk, font_rom_addr, font_rom_q, GS, {VGA_R, VGA_G, VGA_B}, VGA_HSYNC, VGA_VSYNC);

always @(posedge CLK_PLL) begin
	
	if(S1_EDGE) begin
		if(++GS.options.palette_id == palettes_count) begin
			GS.options.palette_id = 0;
		end
		GS.render.palette = palettes[GS.options.palette_id];
	end
	if(S2_EDGE) begin
		++GS.navigation.selected_element;
	end
	if(S3_EDGE) begin
		Vals[2][3:0] += 3'd7;
	end
	Vals[0][3:0] = GS.navigation.selected_element;
	Vals[1][3:0] = GS.options.palette_id;
	Vals[2][4] = 1;
	Vals[3][3:0] = GS.state_name;
	
	LEDS[3:0] = GS.navigation.selected_element;
	
end

endmodule