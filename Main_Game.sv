

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

st_GS_DECIMALIZED GS_decim;
GS_DECIMALIZER GS_decimalizer(GS, GS_decim);

//DIV_MOD dm1(GS.options.PIX_W. r1, r2);
//DIV_MOD dm2(GS.options.PIX_H. r3, r4);


VGA_Game_Renderer vga(CLK_VGA, font_rom_clk, font_rom_addr, font_rom_q, GS, GS_decim, {VGA_R, VGA_G, VGA_B}, VGA_HSYNC, VGA_VSYNC);

always @(posedge CLK_PLL) begin
	
	if(!GS.render.values_updated) begin
		
		GS.render.charlines = RES_V / (GS.options.PIX_H * (FONT_H+1'd1));
		GS.render.charcols  = RES_H / (GS.options.PIX_W * (FONT_W+1'd1));
		
		// Title Menu
		
		//GS.render.title_subcols_offset = 200;
		//GS.render.title_charlines_offset = 4;
		//GS.render.title_menu_charlines_offset = 7;
		
		GS.render.title_subcols_offset = ((RES_H - STR_TITLE_LEN * (FONT_W+1'd1) * (GS.options.PIX_W + title_pixel_size_add)) >> 1);
		if(GS.render.title_subcols_offset >= RES_H) GS.render.title_subcols_offset = 0;
		
		GS.render.title_charlines_offset = ((GS.render.charlines - (title_menu_charlines_offset_add + 3'd4)) >> 1);
		if(GS.render.title_charlines_offset >= GS.render.charlines) GS.render.title_charlines_offset = 0;
		
		GS.render.title_menu_charlines_offset = GS.render.title_charlines_offset + title_menu_charlines_offset_add;
		
		// Options Menu
		
		GS.render.options_charlines_offset_selected = GS.render.charlines >> 1;
		if(GS.render.options_charlines_offset_selected >= GS.render.charlines) GS.render.options_charlines_offset_selected = 0;
		
		GS.render.options_subcols_offset = 5;
		GS.render.options_add_subcols_offset_selected = 5;
		GS.render.options_values_subcols_offset = RES_H - ((FONT_W+1'd1) * 3'd3 * GS.options.PIX_W) - 4'd5;
		if(GS.render.options_values_subcols_offset >= RES_H) GS.render.options_values_subcols_offset = 1;
		
	end
	
	case(GS.state_name)
		GS_MAIN_MENU: begin
			if(S1_EDGE) begin	
				if(++GS.navigation.selected_element >= 3) begin
					GS.navigation.selected_element = 0;
				end
			end
			if(S2_EDGE) begin	
				case(GS.navigation.selected_element)
					0: begin // PLAY
						//TODO
					end
					1: begin // OPTIONS
						GS.navigation.selected_element = 0;
						GS.state_name = GS_OPTIONS;
					end
					2: begin // HIGHSCORES
						//TODO
					end
				endcase
			end
		end
		GS_OPTIONS: begin
			if(S1_EDGE) begin	
				if(++GS.navigation.selected_element >= 4) begin
					GS.navigation.selected_element = 0;
					GS.navigation.selected_sub_element = 0;
				end
			end
			if(S2_EDGE) begin	
				case(GS.navigation.selected_element)
					0: begin // BACK
						GS.navigation.selected_element = 1;
						GS.state_name = GS_MAIN_MENU;
					end
					1: begin // PIXEL WIDTH
						GS.render.values_updated = 0;
						if(!S3_DEB) GS.options.PIX_W -= 2'd2;
						if(++GS.options.PIX_W >= 21) begin
							GS.options.PIX_W = 1;
						end
					end
					2: begin // PIXEL HEIGHT
						GS.render.values_updated = 0;
						if(!S3_DEB) GS.options.PIX_H -= 2'd2;
						if(++GS.options.PIX_H >= 21) begin
							GS.options.PIX_H = 1;
						end
					end
					3: begin // PALETTE
						if(++GS.options.palette_id == palettes_count) begin
							GS.options.palette_id = 0;
						end
						GS.render.palette = palettes[GS.options.palette_id];
					end
				endcase
			end
		end
	endcase

	Vals[0][3:0] = GS.navigation.selected_element;
	Vals[1][3:0] = GS.options.palette_id;
	Vals[2][4] = 1;
	Vals[3][3:0] = GS.state_name;
	
	LEDS[1:0] = GS.navigation.selected_element[1:0];
	LEDS[3:2] = GS.options.palette_id[1:0];
	
end

endmodule