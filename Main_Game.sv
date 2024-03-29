module Main_Game(

input wire CLK0,

input wire BTN_RAW_LEFT ,
input wire BTN_RAW_DOWN ,
input wire BTN_RAW_RIGHT,
input wire BTN_RAW_UP   ,
input wire BTN_RAW_ENTER,
input wire BTN_RAW_DEBUG,

output wire LED0,
output wire LED1,
output wire LED2,
output wire LED3,

output reg VGA_R = 0,
output reg VGA_G = 0,
output reg VGA_B = 0,
output reg VGA_HSYNC = 0,
output reg VGA_VSYNC = 0,

output wire HDMI_D0,
output wire HDMI_D1,
output wire HDMI_D2,
output wire HDMI_CLK,

output wire BUZZER_ON

//output wire HDMI_D0p,
//output wire HDMI_D1p,
//output wire HDMI_D2p,
//output wire HDMI_CLKp,
//output wire HDMI_D0n,
//output wire HDMI_D1n,
//output wire HDMI_D2n,
//output wire HDMI_CLKn
);

wire pll_areset = 0;

wire CLK_PLL;
//wire CLK_PLL2;
wire CLK_VGA;
wire CLK_TMDS;
PLL main_pll(
	 .areset(pll_areset), 
	 .inclk0(CLK0),
	 .c0(CLK_PLL), 
//	 .c1(CLK_PLL2), 
//	 .c2(CLK_VGA), 
	 .c3(CLK_TMDS)
);
CLK_DIV_BY_10 tmds_div(CLK_TMDS, CLK_VGA);

wire BTN_DEB_LEFT  , BTN_EDGE_LEFT;
wire BTN_DEB_DOWN  , BTN_EDGE_DOWN;
wire BTN_DEB_RIGHT , BTN_EDGE_RIGHT;
wire BTN_DEB_UP    , BTN_EDGE_UP;
wire BTN_DEB_ENTER , BTN_EDGE_ENTER;
wire BTN_DEB_DEBUG , BTN_EDGE_DEBUG;

wire BTN_RAW_DEBUG_NEGATED = ~BTN_RAW_DEBUG;

DEBOUNCE deb_left (CLK_PLL, BTN_RAW_LEFT , 	BTN_DEB_LEFT );
DEBOUNCE deb_down (CLK_PLL, BTN_RAW_DOWN , 	BTN_DEB_DOWN );
DEBOUNCE deb_right(CLK_PLL, BTN_RAW_RIGHT, 	BTN_DEB_RIGHT);
DEBOUNCE deb_ip   (CLK_PLL, BTN_RAW_UP   , 	BTN_DEB_UP   );
DEBOUNCE deb_enter(CLK_PLL, BTN_RAW_ENTER, 	BTN_DEB_ENTER);
DEBOUNCE deb_debug(CLK_PLL, BTN_RAW_DEBUG_NEGATED, 	BTN_DEB_DEBUG);
EDGE_NEG edge_left (CLK_PLL, BTN_DEB_LEFT ,  BTN_EDGE_LEFT );
EDGE_NEG edge_down (CLK_PLL, BTN_DEB_DOWN ,  BTN_EDGE_DOWN );
EDGE_NEG edge_right(CLK_PLL, BTN_DEB_RIGHT,  BTN_EDGE_RIGHT);
EDGE_NEG edge_ip   (CLK_PLL, BTN_DEB_UP   ,  BTN_EDGE_UP   );
EDGE_NEG edge_enter(CLK_PLL, BTN_DEB_ENTER,  BTN_EDGE_ENTER);
EDGE_NEG edge_debug(CLK_PLL, BTN_DEB_DEBUG,  BTN_EDGE_DEBUG);


//reg [4:0] Vals [0:3] = '{default: 5'h0};
//SegmentDisplay segdisp1(CLK_PLL2, Vals, {DS4, DS3, DS2, DS1}, {SEG_DP, SEG_G, SEG_F, SEG_E, SEG_D, SEG_C, SEG_B, SEG_A});

reg [3:0] LEDS = 0;
assign {LED3, LED2, LED1, LED0} = ~LEDS;

// CLK_f = 1 MHz
// CLK_T = 1/1000000 s
// 1s ~ (1.048s) = 2^20 * CLK_T
reg [31:0] time_counter = 0;

wire [ADDR_W-1:0] font_rom_addr;
wire       			font_rom_clk;
wire [FONT_W-1:0] font_rom_q;
FONT_ROM font_rom(font_rom_addr, font_rom_clk, font_rom_q);

reg  		    board_ram_wen  = 0;
reg  [7:0]   board_ram_data = 0;
wire [7:0]   board_ram_q;
reg  [11:0]  board_ram_waddr = 0;
wire [11:0]  board_ram_raddr;
wire         board_ram_wclk = CLK_PLL;
wire         board_ram_rclk;
BOARD_RAM board_ram(board_ram_data, board_ram_raddr, board_ram_rclk, board_ram_waddr, board_ram_wclk, board_ram_wen, board_ram_q);

reg  		    star_ram_wen  = 0;
reg  [63:0]  star_ram_data = 0;
wire [63:0]  star_ram_q;
reg  [8:0]   star_ram_waddr = 0;
wire [8:0]   star_ram_raddr;
wire         star_ram_wclk = CLK_PLL;
wire         star_ram_rclk;
STAR_RAM star_ram(star_ram_data, star_ram_raddr, star_ram_rclk, star_ram_waddr, star_ram_wclk, star_ram_wen, star_ram_q);

TUNE_ID music_tune_id = 0;
reg music_new_tune = 0;
MUSIC_PLAYER music_player(CLK_PLL, music_new_tune, music_tune_id, BUZZER_ON);

st_GAME_STATE GS = '{default:0,
	state_name: GS_MAIN_MENU,
	options: '{
		default:0,
		pin_colors: 8'd6,
		pins_count: 8'd4,
		guesses: 8'd20,
		PIX_W: 3,
		PIX_H: 3
	},
	render: '{
		default:0,
		palette: palettes[0]
	}
//	firework: '{
//		x: 11'd200,
//		y: 11'd300,
//		p: 11'd50,
//		r: 11'd300
//	}
};
st_GAME_STATE GS_vga;

st_GS_DECIMALIZED GS_vga_decim;
GS_DECIMALIZER GS_vga_decimalizer(GS_vga, GS_vga_decim);


reg has_updated_seed = 0;
reg [31:0] rng_new_seed = 0;
reg rng_en = 1;
wire [31:0] rng_out;
wire [63:0] rng_out_full;
RNG rng(CLK_PLL, rng_en, rng_new_seed, rng_out, rng_out_full);

reg [4:0] generated_secret_pins = 0;

localparam RNG_MOD_W = 8;
function [PIN_COLOR_W-1:0] truncate_rng_mod_to_pin_color(input [RNG_MOD_W-1:0] val);
	truncate_rng_mod_to_pin_color = val[PIN_COLOR_W-1:0];
endfunction

wire [STARS_X_W-1:0] star_index_x = time_counter[STARS_X_W-1 : 0];
wire [STARS_Y_W-1:0] star_index_y = time_counter[STARS_X_W+STARS_Y_W-1 : STARS_X_W];
wire all_stars_updated = (time_counter[STARS_X_W+STARS_Y_W-1 : 0] == {(STARS_X_W+STARS_Y_W){1'd1}});

reg update_stars = 1;

parameter [5:0] update_stars_interval = 6'd20;
parameter [5:0] update_stars_chance   = 6'd2;

parameter update_stars_pos_x = STAR_POS_W   + update_stars_chance;
parameter update_stars_pos_y = STAR_POS_W   + update_stars_pos_x;
parameter update_stars_stage = STAR_STAGE_W + update_stars_pos_y;
parameter update_stars_color = 3 			  + update_stars_stage;

wire vga_blanking, VGA_HSYNC_temp, VGA_VSYNC_temp;
//wire [PIN_COLOR_W-1:0] color_index;
VGA_Game_Renderer vga(	
	CLK_VGA, font_rom_clk, font_rom_addr, font_rom_q,
	board_ram_rclk, board_ram_raddr, board_ram_q, 
	star_ram_rclk, star_ram_raddr, star_ram_q, 
	GS_vga, GS_vga_decim,
	time_counter, 
	vga_blanking,
//	color_index,
	{VGA_R, VGA_G, VGA_B}, VGA_HSYNC_temp, VGA_VSYNC_temp
);

assign VGA_HSYNC = HSYNC_POLARITY ? VGA_HSYNC_temp : ~VGA_HSYNC_temp;
assign VGA_VSYNC = VSYNC_POLARITY ? VGA_VSYNC_temp : ~VGA_VSYNC_temp;

//wire HDMI_D2, HDMI_D1, HDMI_D0;
//DIFF diff1(CLK_TMDS, HDMI_CLKp, HDMI_CLKn);
//DIFF diff2(HDMI_D0, HDMI_D0p, HDMI_D0n);
//DIFF diff3(HDMI_D1, HDMI_D1p, HDMI_D1n);
//DIFF diff4(HDMI_D2, HDMI_D2p, HDMI_D2n);

assign HDMI_CLK = CLK_VGA;
VGA_TO_HDMI vga_to_hdmi(
	CLK_VGA,
	CLK_TMDS,
	{VGA_R, VGA_G, VGA_B},
//	color_index,
	vga_blanking,
	VGA_HSYNC_temp,
	VGA_VSYNC_temp,
	{HDMI_D2, HDMI_D1, HDMI_D0}
);


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
			GS.render.values_updated = !(BTN_EDGE_UP || BTN_EDGE_DOWN); \
		end else begin \
			`dec_or_inc_clumped(GS.options.``name``, min, max, BTN_EDGE_RIGHT, BTN_EDGE_LEFT) \
			GS.render.values_updated = !(BTN_EDGE_LEFT || BTN_EDGE_RIGHT); \
		end \
	end

	
task reset_analysis();
	GS.board.calculated_green  = 0;
	GS.board.calculated_yellow = 0;
	GS.board.analyzed_guess  = 0; //({max_pins_count{1'd1}} << GS.options.pins_count);
	GS.board.analyzed_secret = 0; //({max_pins_count{1'd1}} << GS.options.pins_count);
endtask

task reset_game(input ENUM_GAME_MODE gamemode);
	GS.board.gamemode = gamemode;
	GS.board.guessed_count = 0;
	GS.board.scroll_offset = 0;
	GS.board.current_guess = '{default: 0}; // This line crashes Quartus Prime, if outsie the Task
	GS.board.is_guess_entered = 1;
	GS.board.is_guess_uploading = 0;
	GS.board.is_guess_uploaded = 0;
	reset_analysis();
endtask

task enter_guess();
	`inc_clumped(GS.board.guessed_count, GS.options.guesses)
	GS.board.is_guess_entered = 1;
	GS.board.is_guess_uploaded = 0;
	check_for_win = 1;
	reset_analysis();
	if(GS.board.guessed_count >= GS.board.scroll_offset + GS.render.charlines) begin
		GS.board.scroll_offset = GS.board.guessed_count - GS.render.charlines[7:0] + 1'd1;
	end
endtask

task analyze_pin_pair_same(input [PIN_POS_W-1:0] index);
	if(index >= GS.options.pins_count) begin
		GS.board.analyzed_secret[index] = 1;
		GS.board.analyzed_guess [index] = 1;
	end else if( GS.board.current_guess[index] == GS.board.secret[index] &&
				   !GS.board.analyzed_secret[index] &&
				   !GS.board.analyzed_guess [index]) begin
		GS.board.analyzed_secret[index] = 1;
		GS.board.analyzed_guess [index] = 1;
		GS.board.calculated_green += 1'd1;
	end
endtask

task analyze_pin_pair_different(input [PIN_POS_W-1:0] g, input [PIN_POS_W-1:0] s);
	if( GS.board.current_guess[g] == GS.board.secret[s] &&
				   !GS.board.analyzed_secret[s] &&
				   !GS.board.analyzed_guess [g]) begin
		GS.board.analyzed_secret[s] = 1;
		GS.board.analyzed_guess [g] = 1;
		GS.board.calculated_yellow += 1'd1;
	end
endtask

function [PIX_VALUE_W-1:0] truncate_11_to_PIXEL_W(input [10:0] value);
	truncate_11_to_PIXEL_W = value[PIX_VALUE_W-1:0];
endfunction

// PIN_POS_W = 5
// [(PIN_POS_W*2):0] = 11
// CLK_T = 1/1000000 s
// Ram_Upload_T = CLK_T * 2^11 = 2.048 ms

reg [(PIN_POS_W*2):0] ram_loader_step = 0;
wire [PIN_POS_W-1:0]  ram_loader_step_low    = ram_loader_step[PIN_POS_W-1:0];
wire [PIN_POS_W-1:0]  ram_loader_step_high   = ram_loader_step[(2*PIN_POS_W)-1:PIN_POS_W];
wire ram_loader_step_differnt_hints_section  = ram_loader_step[2*PIN_POS_W];


wire show_firework = GS.state_name == GS_GAME && (
							GS.board.dial_state == DIAL_YOUWIN  ||
							GS.board.dial_state == DIAL_GUESSER ||
							GS.board.dial_state == DIAL_SETTER);
reg firework_initialized = 0;
							
parameter firework_starting_p = 11'd16;
wire firework_change_r = time_counter[10:0] == 0;
wire firework_change_p = time_counter[16:0] == 0;

reg check_for_win = 0;

always @(posedge CLK_PLL) begin
	time_counter <= time_counter + 1'd1;
	
	music_new_tune = 0;
	board_ram_wen = 0;
	star_ram_wen = 0;
	rng_new_seed = 0;
	
	if(BTN_EDGE_DOWN || BTN_EDGE_LEFT || BTN_EDGE_RIGHT || BTN_EDGE_UP || BTN_EDGE_ENTER) begin
		music_new_tune = 1;
		music_tune_id = TUNE_BTN;
	end
	
	GS.options.debug = BTN_DEB_DEBUG;
	
	if(BTN_EDGE_DEBUG) begin
		if(!BTN_DEB_DOWN && BTN_DEB_UP) begin
//			
//			tile_pix_width_add += BTN_DEB_LEFT ? (BTN_DEB_RIGHT ? 1'd0 : 1'd1) : -1'd1;
//			
//			if(BTN_DEB_LEFT && BTN_DEB_RIGHT) begin
				GS.options.palette_id += 1'd1;
				if(GS.options.palette_id >= palettes_count) begin
					GS.options.palette_id = 1'd0;
				end
//			end
			GS.render.values_updated = 0;
			
		end else if(BTN_DEB_DOWN && !BTN_DEB_UP) begin
			GS.options.pins_count += BTN_DEB_LEFT ? (BTN_DEB_RIGHT ? 1'd0 : 1'd1) : -1'd1;
			GS.render.values_updated = 0;
		end else if(!BTN_DEB_DOWN && !BTN_DEB_UP) begin
			GS.options.pin_colors += BTN_DEB_LEFT ? (BTN_DEB_RIGHT ? 1'd0 : 1'd1) : -1'd1;
			GS.render.values_updated = 0;
		end else if(BTN_DEB_DOWN && BTN_DEB_UP) begin
			GS.options.PIX_W += BTN_DEB_LEFT ? (BTN_DEB_RIGHT ? 1'd0 : 1'd1) : -1'd1;
			GS.render.values_updated = 0;
		end
		
	end
	
	if(show_firework) begin
		if(GS.firework.p == 0 || !firework_initialized) begin
			GS.firework.x = rng_out[10:0]  % RES_H;
			GS.firework.y = rng_out[21:11] % RES_V;
			GS.firework.p = firework_starting_p;
			GS.firework.r = 0;
			firework_initialized = 1;
		end
		if(firework_change_p) begin
			--GS.firework.p;
		end
		if(firework_change_r) begin
			++GS.firework.r;
		end
	end else begin
		firework_initialized = 0;
	end
	
	/// STARS ///
	
	if(time_counter[update_stars_interval-1:0] == 0) begin
		update_stars = 1;
	end
	if(update_stars && (rng_out_full[update_stars_chance-1:0] == 0)) begin
		star_ram_wen   = 1;
		star_ram_data  = rng_out_full[STAR_W+update_stars_chance-1:update_stars_chance];
		star_ram_waddr = {{(9-STARS_X_W-STARS_Y_W){1'b0}}, star_index_y, star_index_x};
	end
	if(all_stars_updated) begin
		update_stars = 0;
	end
	
//	if(BTN_EDGE_LEFT) begin
//		music_new_tune = 1;
//		music_tune_id = TUNE_BTN;
//	end else if(BTN_EDGE_DOWN) begin
//		music_new_tune = 1;
//		music_tune_id = TUNE_Victory;
//	end else if(BTN_EDGE_RIGHT) begin
//		music_new_tune = 1;
//		music_tune_id = TUNE_GameOver;
//	end else if(BTN_EDGE_UP) begin
//		music_new_tune = 1;
//		music_tune_id = TUNE_None;
//	end
	
	/// UPDATE RENDERING ///
	
//	LEDS[3] = !GS.render.values_updated;
//	LEDS[3] = (stars_visited == (32'd1 << (STARS_X_W + STARS_Y_W))+2'd1);
//	LEDS[2] = (stars_visited == (32'd1 << (STARS_X_W + STARS_Y_W)));
//	LEDS[1] = (stars_visited == (32'd1 << (STARS_X_W + STARS_Y_W))-2'd1);
//	LEDS[0] = (stars_visited == (32'd1 << (STARS_X_W + STARS_Y_W))-2'd2);
	
	if(!GS.render.values_updated) begin
		
		GS.render.charlines = RES_V / (GS.options.PIX_H * (FONT_H+1'd1));
		GS.render.charcols  = RES_H / (GS.options.PIX_W * (FONT_W+1'd1));
		
		GS.render.pixels_H = GS.render.charcols * GS.options.PIX_W;
		
		// Title Menu
		
		//GS.render.title_subcols_offset = 200;
		//GS.render.title_charlines_offset = 4;
		//GS.render.title_menu_charlines_offset = 7;
		
		GS.render.title_subcols_offset = ((RES_H - STR_TITLE_LEN * (FONT_W+1'd1) * (GS.options.PIX_W + title_pixel_size_add)) >> 1);
		if(GS.render.title_subcols_offset >= (RES_H >> 1)) GS.render.title_subcols_offset = 0;
		
		GS.render.title_charlines_offset = ((GS.render.charlines - (title_menu_charlines_offset_add + 3'd5)) >> 1);
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
		
		// Board
		
//		GS.render.board_index_subcols_offset = 100;
//		GS.render.board_border1_subcols_offset = 300;
//		GS.render.board_border1_subcols_end = 305;
//		GS.render.board_tiles_subcols_offset = 310;
//		GS.render.board_border2_subcols_offset = 500;
//		GS.render.board_hints_subcols_offset = 510;
//		GS.render.board_border_seperator_length = 5;
//		GS.render.board_exit_subcols_offset = 50;
//		GS.render.board_guess_subcols_offset = 150;
		
			// Right border and hints
		GS.render.board_border_seperator_length = 5;
		GS.render.board_border_subcols_width = GS.options.PIX_W * 2'd2;
		
		GS.render.board_hints_subcols_offset = RES_H - ((FONT_W+1'd1) * 3'd4 * GS.options.PIX_W);
		GS.render.board_border2_subcols_offset = GS.render.board_hints_subcols_offset - GS.render.board_border_subcols_width - GS.options.PIX_W;
		
			// Tiles
		GS.render.board_tiles_subcols_available = RES_H - (((FONT_W+1'd1) * 11'd7 + 11'd6) * GS.options.PIX_W);
		GS.render.board_tile_pix_width = truncate_11_to_PIXEL_W(GS.render.board_tiles_subcols_available / (GS.options.pins_count * (FONT_W + 10'd1)));
		if(GS.render.board_tile_pix_width > GS.options.PIX_W*3'd4) GS.render.board_tile_pix_width = GS.options.PIX_W*3'd4;
		if(GS.render.board_tile_pix_width == 0) GS.render.board_tile_pix_width = 1;
		GS.render.board_tiles_subcols_offset = GS.render.board_border2_subcols_offset - (GS.render.board_tile_pix_width * (FONT_W + 1'd1) * GS.options.pins_count);
		
			// Left of Tiles
		GS.render.board_border1_subcols_end = GS.render.board_tiles_subcols_offset - GS.options.PIX_W;
		GS.render.board_border1_subcols_offset = GS.render.board_border1_subcols_end - GS.render.board_border_subcols_width;
		GS.render.board_index_subcols_offset = GS.render.board_border1_subcols_offset - ((FONT_W+1'd1) * 2'd3 * GS.options.PIX_W);
		GS.render.board_exit_subcols_offset = 0;
		GS.render.board_guess_subcols_offset = GS.render.board_border1_subcols_offset / 2'd2;

			// Tiles Dialog
		GS.render.board_tiles_dialog_charlines_offset = 2;
		GS.render.board_text_dialog_charlines_offset  = 1;
		GS.render.board_tiles_dialog_width  = (GS.options.pin_colors < 10 ? 3'd3 : (GS.options.pin_colors < 17 ? 3'd4 : 3'd5));
		GS.render.board_tiles_dialog_height = (GS.options.pin_colors - 1'd1) / GS.render.board_tiles_dialog_width + 1'd1;
		GS.render.board_tiles_dialog_subcols_end = GS.render.board_tiles_dialog_width * (FONT_W + 1'd1) * GS.options.PIX_W;
		GS.render.board_tiles_dialog_charlines_end = GS.render.board_tiles_dialog_charlines_offset + GS.render.board_tiles_dialog_width - 4'd2;
		GS.render.board_text_dialog_input_charcols_offset = GS.render.charcols - 2'd3;
		
		GS.render.values_updated = 1'd1;
	end
	
//	GS.board.secret[0] = 1;
//	GS.board.secret[1] = 1;
//	GS.board.secret[2] = 2;
//	GS.board.secret[3] = 3;
//	GS.board.secret[4] = 2;
//	GS.board.secret[5] = 4;
//	GS.board.secret[6] = 5;

	
	case(GS.state_name)
		GS_MAIN_MENU: begin
			`dec_or_inc_clumped(GS.navigation.selected_element, 0, 3, BTN_EDGE_DOWN, BTN_EDGE_UP)
			if(BTN_EDGE_ENTER) begin	
				case(GS.navigation.selected_element)
					0: begin // PLAY RANDOM
						GS.navigation.selected_element = 0;
						GS.navigation.selected_sub_element = 0;
						GS.board.dial_state = DIAL_NONE;
						reset_game(GAMEMODE_RANDOM);
						if(!has_updated_seed) begin
							has_updated_seed = 1;
							rng_new_seed = time_counter;
						end
						generated_secret_pins = 0;
						GS.state_name = GS_GENERATE_PINS;
					end
					1: begin // PLAY CUSTOM
						GS.navigation.selected_element = 0;
						GS.navigation.selected_sub_element = 0;
						GS.board.dial_state = DIAL_ENTERSECRET;
						reset_game(GAMEMODE_CUSTOM);
						GS.state_name = GS_GAME;
					end
					2: begin // PLAY RIVAL
						GS.navigation.selected_element = 0;
						GS.navigation.selected_sub_element = 0;
						GS.board.dial_state = DIAL_ENTERSECRET;
						reset_game(GAMEMODE_RIVAL);
						GS.state_name = GS_GAME;
					end
					3: begin // OPTIONS
						GS.navigation.selected_element = 0;
						GS.state_name = GS_OPTIONS;
					end
				endcase
			end
		end
		GS_OPTIONS: begin
			if(!GS.navigation.is_selected_sub) begin
				`dec_or_inc_clumped(GS.navigation.selected_element, 1'd0, 3'd6, BTN_EDGE_DOWN, BTN_EDGE_UP)	
			end
			case(GS.navigation.selected_element)
				0: begin // BACK
					if(BTN_EDGE_ENTER) begin
						GS.navigation.selected_element = 3;
						GS.state_name = GS_MAIN_MENU;
					end
				end
				1: `decimal_option_manipulation_routine(pin_colors, 2'd2, max_pin_colors,  PIN_COLOR_W) // PIN COLORS
				2: `decimal_option_manipulation_routine(pins_count, 2'd2, max_pins_count,  PIN_POS_W) // PINS COUNT
				3: `decimal_option_manipulation_routine(guesses,    2'd2, max_guesses, 4'd8) // GUESSES
				4: `decimal_option_manipulation_routine(PIX_W, 1'd1, 5'd25, PIX_VALUE_W) // PIXEL WIDTH
				5: `decimal_option_manipulation_routine(PIX_H, 1'd1, 5'd25, PIX_VALUE_W) // PIXEL HEIGHT
				6: `decimal_option_manipulation_routine(palette_id, 1'd0, palettes_count-1'd1, 2'd3) // PALETTE
			endcase
		end
		GS_GAME: begin
			if(GS.navigation.is_selected_sub) begin
				`dec_or_inc_clumped(GS.navigation.selected_sub_element, 												  1'd0, GS.options.pin_colors - 1'd1, BTN_EDGE_RIGHT, BTN_EDGE_LEFT)
				`sub_or_add_clumped(GS.navigation.selected_sub_element, GS.render.board_tiles_dialog_width, 1'd0, GS.options.pin_colors - 1'd1, BTN_EDGE_DOWN,  BTN_EDGE_UP)
				GS.board.current_guess[GS.navigation.selected_element - 2'd2] = GS.navigation.selected_sub_element[PIN_COLOR_W-1:0];
				if(BTN_EDGE_ENTER) begin
					GS.navigation.is_selected_sub = 0;
					GS.board.is_guess_entered = 1;
					GS.board.is_guess_uploaded = 0;
					reset_analysis();
				end
			end else begin
				
				case(GS.board.dial_state)
					DIAL_HINTSGREEN: begin
						`dec_or_inc_clumped(GS.navigation.selected_element, 0, 1'd1, BTN_EDGE_RIGHT, BTN_EDGE_LEFT)
						`dec_or_inc_clumped(GS.board.proposed_green, 0, GS.options.pins_count, BTN_EDGE_UP, BTN_EDGE_DOWN)
					end
					DIAL_HINTSYELLOW: begin
						`dec_or_inc_clumped(GS.navigation.selected_element, 0, 1'd1, BTN_EDGE_RIGHT, BTN_EDGE_LEFT)
						`dec_or_inc_clumped(GS.board.proposed_yellow, 0, GS.options.pins_count, BTN_EDGE_UP, BTN_EDGE_DOWN)
					end
					default: begin
						`dec_or_inc_clumped(GS.navigation.selected_element, 0, 1'd1 + GS.options.pins_count, BTN_EDGE_RIGHT, BTN_EDGE_LEFT)
						`dec_or_inc_clumped(GS.board.scroll_offset, 0, GS.board.guessed_count == 0 ? 0 : GS.board.guessed_count-1'd1, BTN_EDGE_UP, BTN_EDGE_DOWN)
					end
				endcase
				
			
				if(BTN_EDGE_ENTER) begin
					case(GS.navigation.selected_element)
						0: begin // EXIT
							GS.state_name = GS_MAIN_MENU;
							GS.navigation.selected_element = GS.board.gamemode;
						end
						1: begin // GUESS
							if(GS.board.is_guess_uploaded) begin
//								case(GS.board.dial_state)
//									DIAL_HINTSYELLOW: begin
									if(GS.board.dial_state == DIAL_HINTSYELLOW) begin
										GS.board.dial_state = DIAL_HINTSGREEN;
									end
//									DIAL_HINTSGREEN: begin
									else if(GS.board.dial_state == DIAL_HINTSGREEN) begin
										if(GS.board.calculated_green  != GS.board.proposed_green ||
											GS.board.calculated_yellow != GS.board.proposed_yellow) begin
												GS.board.dial_state = DIAL_GUESSER;
										end else begin
											GS.board.dial_state = DIAL_NONE;
											enter_guess();
										end
									end
//									DIAL_NONE: begin
									else if(GS.board.dial_state == DIAL_NONE) begin
										if(GS.board.gamemode == GAMEMODE_RIVAL) begin
											GS.board.dial_state = DIAL_HINTSYELLOW;
										end else begin
											enter_guess();
										end
									end
//									DIAL_ENTERSECRET: begin
									else if(GS.board.dial_state == DIAL_ENTERSECRET) begin
										GS.board.secret = GS.board.current_guess;
										GS.board.dial_state = DIAL_NONE;
										GS.board.current_guess = '{default: 0};
										GS.board.is_guess_entered = 1;
										GS.board.is_guess_uploaded = 0;
										reset_analysis();
									end
//								endcase
							end
						end
						default: begin // TILES
							if(GS.board.is_guess_uploaded) begin
								GS.navigation.is_selected_sub = 1;
								GS.navigation.selected_sub_element = GS.board.current_guess[GS.navigation.selected_element - 2'd2];
							end
						end
					endcase
				end
			end
			
			ram_loader_step = time_counter[(PIN_POS_W*2):0];
			
			// Load current Guess to RAM
			if(ram_loader_step == 0 && GS.board.is_guess_entered) begin // Begin loading to RAM
				GS.board.is_guess_entered = 0;
				GS.board.is_guess_uploading = 1;
				GS.board.is_guess_uploaded = 0;
			end
			if(GS.board.is_guess_uploading) begin
				if(ram_loader_step < max_pins_count) begin // Upload all pin colors
					board_ram_wen = 1;
					board_ram_waddr = max_pins_count;
					board_ram_waddr *= GS.board.guessed_count;
					board_ram_waddr += ram_loader_step;
					board_ram_data  = GS.board.current_guess[ram_loader_step[PIN_POS_W-1:0]];
					
					analyze_pin_pair_same(ram_loader_step[PIN_POS_W-1:0]); // Also calculate green hints
				end
				if(ram_loader_step_differnt_hints_section) begin // Check, if at yelow hints section
					if(ram_loader_step_high == max_pins_count) begin // If all combination have been analyzed
						if(ram_loader_step_low[PIN_POS_W-1:1] == 0) begin
							board_ram_wen = 1;
							board_ram_waddr = GS.board.guessed_count;
							board_ram_waddr *= 2;
							board_ram_waddr += ram_hints_offset + ram_loader_step_low[0];
							board_ram_data  = (ram_loader_step_low[0] ? GS.board.calculated_green : GS.board.calculated_yellow);
						end
					end else if(ram_loader_step_low  < max_pins_count &&
									ram_loader_step_high < max_pins_count &&
									ram_loader_step_low != ram_loader_step_high) begin 
						analyze_pin_pair_different(ram_loader_step_high, ram_loader_step_low);
					end
				end
				if((ram_loader_step == -11'd1) && !GS.board.is_guess_entered) begin // End uploading, if no new request is present
					GS.board.is_guess_uploading = 0;
					GS.board.is_guess_uploaded = 1;
					
					if(check_for_win) begin
						if(GS.board.gamemode != GAMEMODE_RANDOM) begin
							if(GS.board.calculated_green == GS.options.pins_count) begin
								music_new_tune = 1;
								music_tune_id = TUNE_Victory;
								GS.board.dial_state = DIAL_GUESSER;
							end else if(GS.board.guessed_count >= GS.options.guesses) begin
								music_new_tune = 1;
								music_tune_id = TUNE_GameOver;
								GS.board.dial_state = DIAL_SETTER;
							end
						end else begin
							if(GS.board.calculated_green == GS.options.pins_count) begin
								music_new_tune = 1;
								music_tune_id = TUNE_Victory;
								GS.board.dial_state = DIAL_YOUWIN;
							end else if(GS.board.guessed_count >= GS.options.guesses) begin
								music_new_tune = 1;
								music_tune_id = TUNE_GameOver;
								GS.board.dial_state = DIAL_YOULOSE;
							end
						end
						check_for_win = 0;
					end
					
					
				end
			end
		end
		GS_GENERATE_PINS: begin
			if(generated_secret_pins >= max_pins_count) begin
				GS.state_name = GS_GAME;
			end else begin
				GS.board.secret[generated_secret_pins] = truncate_rng_mod_to_pin_color(rng_out[RNG_MOD_W-1:0] % GS.options.pin_colors);
				generated_secret_pins += 1'd1;
			end
		end
	endcase

//	Vals[0][3:0] = GS.navigation.selected_element;
//	Vals[1][3:0] = GS.options.palette_id;
//	Vals[2][4] = 1;
//	Vals[3][3:0] = GS.state_name;
	
	LEDS[0] = GS.board.is_guess_entered;
	LEDS[1] = GS.board.is_guess_uploading;
	LEDS[2] = GS.board.is_guess_uploaded;
	LEDS[3] = music_new_tune;
	//LEDS[3] = time_counter[19];
	
	//LEDS[2:0] = ram_loader_step[2:0];
	//LEDS[3]   = ram_loader_step < GS.options.pins_count;
	
	if(VGA_VSYNC_temp && GS.state_name != GS_GENERATE_PINS) begin
		GS_vga = GS;
	end
	
end

endmodule