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
	state_name: GS_MAIN_MENU,
	options: '{
		default:0,
		PIX_W: 3,
		PIX_H: 3
	},
	render: '{
		default:0,
		palette: palettes[0]
	}
};

VGA_Game_Renderer vga(CLK_VGA, font_rom_clk, font_rom_addr, font_rom_q, GS, {VGA_R, VGA_G, VGA_B}, VGA_HSYNC, VGA_VSYNC);

always @(posedge CLK_PLL) begin
	
	if(!GS.render.values_updated) begin
		
		GS.render.charlines = RES_V / (GS.options.PIX_H * (FONT_H+1'd1));
		GS.render.charcols  = RES_H / (GS.options.PIX_W * (FONT_W+1'd1));
		
		//GS.render.title_subcols_offset = 200;
		//GS.render.title_charlines_offset = 4;
		//GS.render.title_menu_charlines_offset = 7;
		
		GS.render.title_subcols_offset = ((RES_H - STR_TITLE_LEN * (FONT_W+1) * (GS.options.PIX_H + title_pixel_size_add)) >> 1);
		if(GS.render.title_subcols_offset >= RES_H) GS.render.title_subcols_offset = 0;
		
		GS.render.title_charlines_offset = ((GS.render.charlines - (title_menu_charlines_offset_add + 3'd4)) >> 1);
		if(GS.render.title_charlines_offset >= GS.render.charlines) GS.render.title_charlines_offset = 0;
		
		GS.render.title_menu_charlines_offset = GS.render.title_charlines_offset + title_menu_charlines_offset_add;
		
		
	end
	
	
	
	
	if(S1_EDGE) begin
		if(++GS.options.palette_id == palettes_count) begin
			GS.options.palette_id = 0;
		end
		GS.render.palette = palettes[GS.options.palette_id];
	end
	if(S2_EDGE) begin
		case(GS.state_name)
			GS_MAIN_MENU: begin
				if(++GS.navigation.selected_element >= 3) begin
					GS.navigation.selected_element = 0;
					GS.options.PIX_H++;
					GS.options.PIX_W++;
					GS.render.values_updated = 0;
				end
			end
			GS_OPTIONS: begin
				if(++GS.navigation.selected_element >= 3) begin
					GS.navigation.selected_element = 0;
					GS.options.PIX_H = 2;
					GS.options.PIX_W = 2;
					GS.render.values_updated = 0;
				end
			end
		endcase
	end
	if(S3_EDGE) begin
		Vals[2][3:0] += 3'd7;
		case(GS.state_name)
			GS_MAIN_MENU: GS.state_name = GS_OPTIONS;
			GS_OPTIONS:   GS.state_name = GS_MAIN_MENU;
		endcase
	end
	Vals[0][3:0] = GS.navigation.selected_element;
	Vals[1][3:0] = GS.options.palette_id;
	Vals[2][4] = 1;
	Vals[3][3:0] = GS.state_name;
	
	LEDS[3:0] = GS.navigation.selected_element;
	
end

endmodule