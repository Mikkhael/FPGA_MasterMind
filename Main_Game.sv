

module Main_Game(

input wire CLK0,

input wire BTN_RAW_LEFT ,
input wire BTN_RAW_DOWN ,
input wire BTN_RAW_RIGHT,
input wire BTN_RAW_UP   ,
input wire BTN_RAW_ENTER,

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

wire BTN_DEB_LEFT  , BTN_EDGE_LEFT;
wire BTN_DEB_DOWN  , BTN_EDGE_DOWN;
wire BTN_DEB_RIGHT , BTN_EDGE_RIGHT;
wire BTN_DEB_UP    , BTN_EDGE_UP;
wire BTN_DEB_ENTER , BTN_EDGE_ENTER;

DEBOUNCE deb_left (CLK_PLL, BTN_RAW_LEFT , 	BTN_DEB_LEFT );
DEBOUNCE deb_down (CLK_PLL, BTN_RAW_DOWN , 	BTN_DEB_DOWN );
DEBOUNCE deb_right(CLK_PLL, BTN_RAW_RIGHT, 	BTN_DEB_RIGHT);
DEBOUNCE deb_ip   (CLK_PLL, BTN_RAW_UP   , 	BTN_DEB_UP   );
DEBOUNCE deb_enter(CLK_PLL, BTN_RAW_ENTER, 	BTN_DEB_ENTER);
EDGE_NEG edge_left (CLK_PLL, BTN_DEB_LEFT ,  BTN_EDGE_LEFT );
EDGE_NEG edge_down (CLK_PLL, BTN_DEB_DOWN ,  BTN_EDGE_DOWN );
EDGE_NEG edge_right(CLK_PLL, BTN_DEB_RIGHT,  BTN_EDGE_RIGHT);
EDGE_NEG edge_ip   (CLK_PLL, BTN_DEB_UP   ,  BTN_EDGE_UP   );
EDGE_NEG edge_enter(CLK_PLL, BTN_DEB_ENTER,  BTN_EDGE_ENTER);


//reg [4:0] Vals [0:3] = '{default: 5'h0};
//SegmentDisplay segdisp1(CLK_PLL2, Vals, {DS4, DS3, DS2, DS1}, {SEG_DP, SEG_G, SEG_F, SEG_E, SEG_D, SEG_C, SEG_B, SEG_A});

reg [3:0] LEDS = 0;
assign {LED3, LED2, LED1, LED0} = ~LEDS;

// CLK_f = 500 kHz
// CLK_T = 1/500000 s
// 1s ~ (1.048s) = 2^19 * CLK_T
reg [31:0] time_counter = 0;

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




VGA_Game_Renderer vga(CLK_VGA, font_rom_clk, font_rom_addr, font_rom_q, GS, GS_decim, time_counter, {VGA_R, VGA_G, VGA_B}, VGA_HSYNC, VGA_VSYNC);

`define add_clumped(value, step, max) \
	value = (value >= (max) || (step) >= (max) - value) ? (max) : (value + (step));
`define sub_clumped(value, step, min) \
	value = (value <= (min) || value - (min) <= (step)) ? (min) : (value - (step));
	
`define inc_clumped(value, max) \
	value = (value >= (max)) ? value : (value + 1'd1);
`define dec_clumped(value, min) \
	value = (value <= (min)) ? value : (value - 1'd1);
	
`define inc_rolled(value, min, max) \
	value = (value >= (max)) ? (min) : (value + 1'd1);
`define dec_rolled(value, min, max) \
	value = (value <= (min)) ? (max) : (value - 1'd1);

`define sub_or_add_clumped(value, step, min, max, at_add, at_sub) \
	begin \
		if(at_add) `add_clumped(value, step, max) \
		if(at_sub) `sub_clumped(value, step, min) \
	end
	
`define dec_or_inc_clumped(value, min, max, at_inc, at_dec) \
	begin \
		if(at_inc) `inc_clumped(value, max) \
		if(at_dec) `dec_clumped(value, min) \
	end
	
`define dec_or_inc_rolled(value, min, max, at_inc, at_dec) \
	begin \
		if(at_inc) `inc_rolled(value, min, max) \
		if(at_dec) `dec_rolled(value, min, max) \
	end
	
`define decimal_option_manipulation_routine(name, min, max, width) \
	begin \
		if(BTN_EDGE_ENTER) begin \
			GS.navigation.is_selected_sub ^= 1'd1; \
			GS.navigation.selected_sub_element = 0; \
		end \
		if(GS.navigation.is_selected_sub) begin \
			`dec_or_inc_rolled(GS.navigation.selected_sub_element, 1'd0, GS_DECIM_options_``name``_LEN-1'd1, BTN_EDGE_RIGHT, BTN_EDGE_LEFT) \
			`sub_or_add_clumped(GS.options.``name``, powers_of_10[GS_DECIM_options_``name``_LEN-1'd1-GS.navigation.selected_sub_element][width-1:0], min, max, BTN_EDGE_UP, BTN_EDGE_DOWN) \
			GS.render.values_updated = ~(BTN_EDGE_UP | BTN_EDGE_DOWN); \
		end else begin \
			`dec_or_inc_clumped(GS.options.``name``, min, max, BTN_EDGE_RIGHT, BTN_EDGE_LEFT) \
			GS.render.values_updated = ~(BTN_EDGE_LEFT | BTN_EDGE_RIGHT); \
		end \
	end

always @(posedge CLK_PLL) begin
	
	if(!GS.render.values_updated) begin
		
		GS.render.charlines = RES_V / (GS.options.PIX_H * (FONT_H+1'd1));
		GS.render.charcols  = RES_H / (GS.options.PIX_W * (FONT_W+1'd1));
		
		// Title Menu
		
		//GS.render.title_subcols_offset = 200;
		//GS.render.title_charlines_offset = 4;
		//GS.render.title_menu_charlines_offset = 7;
		
		GS.render.title_subcols_offset = ((RES_H - STR_TITLE_LEN * (FONT_W+1'd1) * (GS.options.PIX_W + title_pixel_size_add)) >> 1);
		if(GS.render.title_subcols_offset >= (RES_H >> 1)) GS.render.title_subcols_offset = 0;
		
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
		
		GS.render.palette = palettes[GS.options.palette_id];
		
	end
	
	case(GS.state_name)
		GS_MAIN_MENU: begin
			`dec_or_inc_clumped(GS.navigation.selected_element, 0, 2, BTN_EDGE_DOWN, BTN_EDGE_UP)
			if(BTN_EDGE_ENTER) begin	
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
			if(!GS.navigation.is_selected_sub) begin
				`dec_or_inc_clumped(GS.navigation.selected_element, 1'd0, 3'd3, BTN_EDGE_DOWN, BTN_EDGE_UP)	
			end
			case(GS.navigation.selected_element)
				0: begin // BACK
					if(BTN_EDGE_ENTER) begin
						GS.navigation.selected_element = 1;
						GS.state_name = GS_MAIN_MENU;
					end
				end
				1: `decimal_option_manipulation_routine(PIX_W, 1'd1, 5'd25, PIX_VALUE_W) // PIXEL WIDTH
				2: `decimal_option_manipulation_routine(PIX_H, 1'd1, 5'd25, PIX_VALUE_W) // PIXEL HEIGHT
				3: `decimal_option_manipulation_routine(palette_id, 1'd0, palettes_count-1'd1, 2'd3) // PALETTE
			endcase
		end
	endcase

//	Vals[0][3:0] = GS.navigation.selected_element;
//	Vals[1][3:0] = GS.options.palette_id;
//	Vals[2][4] = 1;
//	Vals[3][3:0] = GS.state_name;
	
	LEDS[3:0] = time_counter[22:19];
	
end

always @(posedge CLK_PLL2) begin
	time_counter += 1'd1;
end

endmodule