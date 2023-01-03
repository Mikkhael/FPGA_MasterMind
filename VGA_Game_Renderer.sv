module VGA_Game_Renderer(
	input wire 			clk,
	
	output wire 		rom_clk, 
	output reg  [(ADDR_W-1):0]	rom_addr = 0, 
	input  wire	[(FONT_W-1):0] rom_q,
	
	output wire board_ram_rclk,
	output reg [11:0] board_ram_raddr = 0,
	input wire [7:0]  board_ram_q,
	
	input st_GAME_STATE GS,
	input st_GS_DECIMALIZED GS_decim,
	
	input wire [31:0] time_counter,
	
	output wire [2:0] RGB,
	output wire 		HSYNC,
	output wire			VSYNC
);


typedef enum logic [5:0] {
	DRAWING_STAGE_NONE,

	MAIN_MENU_TITLE,
	MAIN_MENU_OPTION,
	
	OPTIONS_NAMES,
	OPTIONS_VALUES,

	BOARD_INDEX, 
	BOARD_BORDER_L, 
	BOARD_BORDER_R,
	BOARD_TILES, 
	BOARD_HINTS,
	BOARD_EXIT,
	BOARD_GUESS,
	BOARD_TILE_DIALOG,
	BOARD_TEXT_DIALOG
} DRAWING_STAGE;

typedef struct{
	reg blanking;
	reg [10:0] val;
	reg [4:0] subcol;
	reg [10:0] col;
	
	reg [10:0] fontcol;
	
	reg [10:0] charcol;
	
	reg skip_spacing_once;
	reg [5:0] pix_size;
	
	reg [10:0] start_subcols;
	DRAWING_STAGE drawing_stage;
	reg [10:0] dialog_input_charcol;
} st_counters_h;

typedef struct{
	reg blanking;
	reg [10:0] val;
	reg [4:0] subline;
	reg [10:0] line;
	
	reg [ADDR_W-1:0] fontline;
	
	reg [10:0] charline;
	
	reg skip_spacing_once;
	reg [5:0] pix_size;
} st_counters_v;

st_counters_h cnth       = '{default: 0, val: (H_TIME_TOTAL - 4), blanking: 1};
st_counters_h temp_cnth1 = '{default: 0, val: (H_TIME_TOTAL - 3), blanking: 1};
st_counters_h temp_cnth2 = '{default: 0, val: (H_TIME_TOTAL - 2), blanking: 1};
st_counters_h cnth_fetch = '{default: 0, val: (H_TIME_TOTAL - 1), blanking: 1};
st_counters_v cntv       = '{default: 0};


reg [2:0] color = 3'b000;

assign RGB   = (cnth.val <  RES_H          && cntv.val < RES_V) ? color : 3'b000;
assign HSYNC = (cnth.val >= RES_H + BLK_HF && cnth.val < RES_H + BLK_HF + BLK_HT);
assign VSYNC = (cntv.val >= RES_V + BLK_VF && cntv.val < RES_V + BLK_VF + BLK_VT);

assign rom_clk = clk;
assign board_ram_rclk = clk;


task automatic advance_counters_h(ref st_GAME_STATE GS, ref st_counters_h cnth);
	
	if(cnth.val == RES_H) begin // Czy skończyło się wyświetlanie lini
		// Reset
		cnth.blanking = 1;
		cnth.subcol = 0;
		cnth.col = 0;
		cnth.fontcol = 0;
		cnth.charcol = -11'd1;
		cnth.skip_spacing_once = 0;
		
	end else if(~cnth.blanking) begin // Czy jesteśmy w sekcji kolorowego obrazu
		// Increment
		if(++cnth.subcol == cnth.pix_size) begin
			cnth.subcol = 0;
			++cnth.col;
			// Advance displayed font pixel
			if(++cnth.fontcol == FONT_W + 1 - cnth.skip_spacing_once) begin
				cnth.fontcol = 0;
				cnth.skip_spacing_once = 0;
				++cnth.charcol;
			end
		end
	end
	
	if(++cnth.val == H_TIME_TOTAL) begin
		cnth.val = 0;
		cnth.blanking = 0;
	end
	
endtask


task automatic advance_counters_v(ref st_GAME_STATE GS, ref st_counters_v cntv);
	
	if(cntv.val == RES_V) begin // Czy skończyło się wyświetlanie klatki
		// Reset
		cntv.blanking = 1;
		cntv.subline = 0;
		cntv.line = 0;
		cntv.fontline = 0;
		cntv.charline = 0;
		cntv.skip_spacing_once = 0;
		
	end else if(~cntv.blanking) begin // Czy jesteśmy w sekcji kolorowego obrazu
		// Increment
		if(++cntv.subline == cntv.pix_size) begin
			cntv.subline = 0;
			++cntv.line;
			// Advance displayed font pixel
			if(++cntv.fontline == FONT_H + 1 - cntv.skip_spacing_once) begin
				cntv.fontline = 0;
				cntv.skip_spacing_once = 0;
				++cntv.charline;
			end
		end
	end
	
	if(++cntv.val == V_TIME_TOTAL) begin
		cntv.val = 0;
		cntv.blanking = 0;
	end
	
endtask

function [PIN_COLOR_W-1:0] truncate_11_to_COLOR_W(input [10:0] value);
	truncate_11_to_COLOR_W = value[PIN_COLOR_W-1:0];
endfunction

`define display_decimized_character(name, index, fontline) \
	rom_addr = (index < GS_DECIM_``name``_LEN) ? (CHAR_0 +  GS_decim.``name``[index] + (fontline << FONT_LINESHIFT)) : CHAR_;

`define display_decimized_character2(name, index, fontline) \
	rom_addr = ((index) < 2'd2 && ((index) != 1'd0 || ``name``[1'd0] != 4'd0)) ? (CHAR_0 + ``name``[index] + (fontline << FONT_LINESHIFT)) : CHAR_;

`define display_string_character(name, index, fontline) \
	rom_addr = (index < STR_``name``_LEN) ? (STR_``name[index] + (fontline << FONT_LINESHIFT)) : CHAR_;

`define display_string_character_with_mask(name, index, fontline) \
   begin \
	`display_string_character(name, index, fontline) \
	cnth_fetch.skip_spacing_once = (index < STR_``name``_LEN) && (STR_MASK_``name``[index]); \
	end
	
function [2:0] get_visible_color(input [2:0] color);
	get_visible_color = color;
	get_visible_color = (get_visible_color == GS.render.palette.bg) 			 ? C_BLACK : get_visible_color;
	get_visible_color = (get_visible_color == GS.render.palette.selected_bg) ? (GS.render.palette.bg == C_BLACK ? C_WHITE : C_BLACK) : get_visible_color;
endfunction

function [2:0] get_pin_color(input [PIN_COLOR_W-1:0] index);
	get_pin_color = get_visible_color(pin_colorset[index][cntv.fontline[0]]);
endfunction

function [2:0] get_palette_color(input is_bg, input is_selected);
	get_palette_color = is_bg ? 
					(is_selected ? GS.render.palette.selected_bg : GS.render.palette.bg)  : 
					(is_selected ? GS.render.palette.selected    : GS.render.palette.text);
endfunction
	
//reg [10:0] off_fetch_char = 0;
reg [10:0] off_charline  = 0;
reg is_selected_option_line = 0;
reg is_selected = 0;
reg is_bg = 0;
reg blink = 0;

reg [7:0] temp_color_index = 0;
reg is_board_current_guess = 0;


reg [10:0] board_current_line_index   = 0;
reg [7:0]  board_current_hints_green  = 0;
reg [7:0]  board_current_hints_yellow = 0;

reg [1:0][3:0] board_current_line_index_decimized   = 0;
reg [1:0][3:0] board_current_hints_green_decimized  = 0;
reg [1:0][3:0] board_current_hints_yellow_decimized = 0;
reg [1:0][3:0] board_current_proposed_green_decimized  = 0;
reg [1:0][3:0] board_current_proposed_yellow_decimized = 0;

DIV_MOD #(.W_in(8), .W_div(4)) dm_index        (board_current_line_index,   board_current_line_index_decimized[0],      board_current_line_index_decimized[1]);
DIV_MOD #(.W_in(8), .W_div(4)) dm_hints_green  (board_current_hints_green,  board_current_hints_green_decimized[0],     board_current_hints_green_decimized[1]);
DIV_MOD #(.W_in(8), .W_div(4)) dm_hints_yellow (board_current_hints_yellow, board_current_hints_yellow_decimized[0],    board_current_hints_yellow_decimized[1]);
DIV_MOD #(.W_in(8), .W_div(4)) dm_propo_green  (GS.board.proposed_green,    board_current_proposed_green_decimized[0],  board_current_proposed_green_decimized[1]);
DIV_MOD #(.W_in(8), .W_div(4)) dm_propo_yellow (GS.board.proposed_yellow,   board_current_proposed_yellow_decimized[0], board_current_proposed_yellow_decimized[1]);


always @(posedge clk) begin
	
	//// ADVANCE COUNTERS ////
	
	cnth = temp_cnth1;
	temp_cnth1 = temp_cnth2;
	temp_cnth2 = cnth_fetch;
	//advance_counters_h(GS, cnth);
	advance_counters_h(GS, cnth_fetch);
	
	if(cnth.val == RES_H) begin // Jeśli skończyliśmy rysować linię
		advance_counters_v(GS, cntv);
	end
	
	
	//// FETCH ////
	cnth_fetch.drawing_stage = DRAWING_STAGE_NONE;
	if(GS.state_name == GS_GAME) begin
		board_current_line_index = GS.render.charlines - 1'd1 - cntv.charline + GS.board.scroll_offset;
	end
	if(!cnth_fetch.blanking && !cntv.blanking) begin
		case(GS.state_name)
			GS_MAIN_MENU: begin
				rom_addr = CHAR_;
				off_charline = cntv.charline - GS.render.title_menu_charlines_offset;
				if(cnth_fetch.val >= GS.render.title_subcols_offset) begin
					if(cnth_fetch.val == GS.render.title_subcols_offset) begin
						cnth_fetch.subcol  = 0;
						cnth_fetch.col     = 0;
						cnth_fetch.fontcol = 0;
						cnth_fetch.charcol = 0;
					end
					if(cntv.charline == GS.render.title_charlines_offset) begin
						// Title
						cnth_fetch.drawing_stage = MAIN_MENU_TITLE;
						cnth_fetch.pix_size 	    = GS.options.PIX_W + title_pixel_size_add;
						cntv.pix_size       		 = GS.options.PIX_H + title_pixel_size_add;
						`display_string_character_with_mask(TITLE, cnth_fetch.charcol, cntv.fontline)
					end else begin
						// Menu Entries
						cnth_fetch.drawing_stage = MAIN_MENU_OPTION;
						cntv.pix_size       = GS.options.PIX_H;
						cnth_fetch.pix_size = GS.options.PIX_W;
						case(off_charline)
							0: `display_string_character(PLAYVSCOMPUTER, cnth_fetch.charcol, cntv.fontline)
							1: `display_string_character(PLAYVSHUMAN,    cnth_fetch.charcol, cntv.fontline)
							2: `display_string_character(PLAYVSRIVAL,    cnth_fetch.charcol, cntv.fontline)
							3: `display_string_character(OPTIONS,        cnth_fetch.charcol, cntv.fontline)
							default: rom_addr = CHAR_;
						endcase
					end
				end
			end
			GS_OPTIONS: begin
				off_charline 				= cntv.charline -  GS.render.options_charlines_offset_selected + GS.navigation.selected_element;
				is_selected_option_line = cntv.charline == GS.render.options_charlines_offset_selected;
				if(cnth_fetch.val >= GS.render.options_values_subcols_offset) begin
					cnth_fetch.drawing_stage = OPTIONS_VALUES;
					cnth_fetch.start_subcols = GS.render.options_values_subcols_offset;
					if(is_selected_option_line) begin
						cnth_fetch.pix_size = GS.options.PIX_W;
						cntv.pix_size       = GS.options.PIX_H + 1'd1;
					end
				end else begin
					cnth_fetch.drawing_stage = OPTIONS_NAMES;
					cnth_fetch.start_subcols = GS.render.options_subcols_offset;
					if(is_selected_option_line) begin
						cnth_fetch.start_subcols += GS.render.options_add_subcols_offset_selected;
						cnth_fetch.pix_size = GS.options.PIX_W + 1'd1;
						cntv.pix_size       = GS.options.PIX_H + 1'd1;
					end
				end
				if(!is_selected_option_line) begin
					cnth_fetch.pix_size = GS.options.PIX_W;
					cntv.pix_size       = GS.options.PIX_H;
				end
				
				rom_addr = CHAR_;
				if(cnth_fetch.val >= cnth_fetch.start_subcols) begin
					if(cnth_fetch.val == cnth_fetch.start_subcols) begin
						cnth_fetch.subcol  = 0;
						cnth_fetch.col     = 0;
						cnth_fetch.fontcol = 0;
						cnth_fetch.charcol = 0;
					end
					case(cnth_fetch.drawing_stage)
						OPTIONS_VALUES: begin
							case(off_charline)
								1: `display_decimized_character(options_pin_colors, cnth_fetch.charcol, cntv.fontline)
								2: `display_decimized_character(options_pins_count, cnth_fetch.charcol, cntv.fontline)
								3: `display_decimized_character(options_guesses,    cnth_fetch.charcol, cntv.fontline)
								4: `display_decimized_character(options_PIX_W, cnth_fetch.charcol, cntv.fontline)
								5: `display_decimized_character(options_PIX_H, cnth_fetch.charcol, cntv.fontline)
								6: `display_decimized_character(options_palette_id, cnth_fetch.charcol, cntv.fontline)
								default: rom_addr = CHAR_;
							endcase
						end
						OPTIONS_NAMES: begin
							case(off_charline)
								0: `display_string_character(BACK,        cnth_fetch.charcol, cntv.fontline)
								1: `display_string_character(PINCOLORS,   cnth_fetch.charcol, cntv.fontline)
								2: `display_string_character(PINSCOUNT,   cnth_fetch.charcol, cntv.fontline)
								3: `display_string_character(GUESSES,     cnth_fetch.charcol, cntv.fontline)
								4: `display_string_character(PIXELWIDTH,  cnth_fetch.charcol, cntv.fontline)
								5: `display_string_character(PIXELHEIGHT, cnth_fetch.charcol, cntv.fontline)
								6: `display_string_character(PALETTE,     cnth_fetch.charcol, cntv.fontline)
								default: rom_addr = CHAR_;
							endcase
						end
					endcase
				end
				
			end
			GS_GAME: begin
				is_board_current_guess = cntv.charline == GS.render.charlines - 1'd1;
				if(cntv.charline == GS.render.board_text_dialog_charlines_offset && GS.board.dial_state != DIAL_NONE)
					cnth_fetch.drawing_stage = BOARD_TEXT_DIALOG;
				else if(GS.navigation.is_selected_sub &&
						  cntv.charline >= GS.render.board_tiles_dialog_charlines_offset && 
						  cntv.charline  < GS.render.board_tiles_dialog_charlines_offset + GS.render.board_tiles_dialog_height &&
						  cnth_fetch.val < GS.render.board_tiles_dialog_subcols_end)
																										cnth_fetch.drawing_stage = BOARD_TILE_DIALOG;
				else if(cnth_fetch.val >= GS.render.board_hints_subcols_offset)   cnth_fetch.drawing_stage = BOARD_HINTS;
				else if(cnth_fetch.val >= GS.render.board_border2_subcols_offset) cnth_fetch.drawing_stage = BOARD_BORDER_R;
				else if(cnth_fetch.val >= GS.render.board_tiles_subcols_offset)   cnth_fetch.drawing_stage = BOARD_TILES;
				else if(cnth_fetch.val >= GS.render.board_border1_subcols_offset) cnth_fetch.drawing_stage = BOARD_BORDER_L;
				else if(!is_board_current_guess && cnth_fetch.val >= GS.render.board_index_subcols_offset) cnth_fetch.drawing_stage = BOARD_INDEX;
				else if( is_board_current_guess && cnth_fetch.val >= GS.render.board_guess_subcols_offset) cnth_fetch.drawing_stage = BOARD_GUESS;
				else if( is_board_current_guess && cnth_fetch.val >= GS.render.board_exit_subcols_offset)  cnth_fetch.drawing_stage = BOARD_EXIT;
				case(cnth_fetch.drawing_stage)
					BOARD_TILE_DIALOG, BOARD_TEXT_DIALOG: cnth_fetch.start_subcols = 0;
					BOARD_HINTS:    cnth_fetch.start_subcols = GS.render.board_hints_subcols_offset;
					BOARD_BORDER_R: cnth_fetch.start_subcols = GS.render.board_border2_subcols_offset;
					BOARD_TILES:    cnth_fetch.start_subcols = GS.render.board_tiles_subcols_offset;
					BOARD_BORDER_L: cnth_fetch.start_subcols = GS.render.board_border1_subcols_offset;
					BOARD_INDEX:    cnth_fetch.start_subcols = GS.render.board_index_subcols_offset;
					BOARD_GUESS:    cnth_fetch.start_subcols = GS.render.board_guess_subcols_offset;
					BOARD_EXIT:     cnth_fetch.start_subcols = GS.render.board_exit_subcols_offset;
				endcase
				if(cnth_fetch.val == cnth_fetch.start_subcols) begin
					cnth_fetch.subcol  = 0;
					cnth_fetch.col     = 0;
					cnth_fetch.fontcol = 0;
					cnth_fetch.charcol = 0;
				end
				cnth_fetch.pix_size = GS.options.PIX_W;
				case(cnth_fetch.drawing_stage)
					BOARD_HINTS: begin // Hints
						if(cnth_fetch.charcol < 2) `display_decimized_character2(board_current_hints_yellow_decimized, cnth_fetch.charcol, cntv.fontline)
						else 								`display_decimized_character2(board_current_hints_green_decimized,  cnth_fetch.charcol-2'd2, cntv.fontline)
					end
					BOARD_TILES: begin // Tiles
						cnth_fetch.pix_size = GS.render.board_tile_pix_width;
						board_ram_raddr = (board_current_line_index - 1'd1) * max_pins_count + cnth_fetch.charcol;
						rom_addr = CHAR_;
					end
					BOARD_INDEX: begin // Indicies
						if(board_current_line_index > GS.board.guessed_count) begin
							rom_addr = CHAR_;
						end else if(cnth_fetch.charcol == 0) begin
							rom_addr = CHAR_Hash + (cntv.fontline << FONT_LINESHIFT);
						end else begin
							`display_decimized_character2(board_current_line_index_decimized, cnth_fetch.charcol-1'd1, cntv.fontline)
						end
					end
					BOARD_GUESS: `display_string_character_with_mask(GUESS, cnth_fetch.charcol, cntv.fontline) // GUESS button
					BOARD_EXIT:  `display_string_character_with_mask(EXIT,  cnth_fetch.charcol, cntv.fontline) // EXIT button
					BOARD_TEXT_DIALOG: begin
						case(GS.board.dial_state)
							DIAL_YOUWIN:		`display_string_character(YOUWIN, 		cnth_fetch.charcol, cntv.fontline)
							DIAL_YOULOSE:		`display_string_character(GAMEOVER,	 	cnth_fetch.charcol, cntv.fontline)
							DIAL_ENTERSECRET:	`display_string_character(ENTERSECRET, cnth_fetch.charcol, cntv.fontline)
							DIAL_HINTSGREEN:	`display_string_character(HINTSGREEN,	cnth_fetch.charcol, cntv.fontline)
							DIAL_HINTSYELLOW:	`display_string_character(HINTSYELLOW, cnth_fetch.charcol, cntv.fontline)
							DIAL_GUESSER:		`display_string_character(GUESSER,		cnth_fetch.charcol, cntv.fontline)
							DIAL_SETTER:		`display_string_character(SETTER,		cnth_fetch.charcol, cntv.fontline)
						endcase
						cnth_fetch.dialog_input_charcol = cnth_fetch.charcol - GS.render.board_text_dialog_input_charcols_offset;
						if(cnth_fetch.dialog_input_charcol < 2'd2) begin
							case(GS.board.dial_state)
								DIAL_HINTSGREEN:	`display_decimized_character2(board_current_proposed_green_decimized,  cnth_fetch.dialog_input_charcol, cntv.fontline)
								DIAL_HINTSYELLOW:	`display_decimized_character2(board_current_proposed_yellow_decimized, cnth_fetch.dialog_input_charcol, cntv.fontline)
							endcase
						end
					end
					default: begin
						rom_addr = CHAR_;
					end
				endcase
			end
		endcase
	end else if (cnth_fetch.blanking && GS.state_name == GS_GAME) begin
		if(cnth_fetch.val <= RES_H + 5'd10) begin
			board_ram_raddr = (board_current_line_index - 1'd1) * 2'd2 + ram_hints_offset;
			board_current_hints_yellow = board_ram_q;
		end else if(cnth_fetch.val <= RES_H + 5'd20) begin
			board_ram_raddr = (board_current_line_index - 1'd1) * 2'd2 + ram_hints_offset + 1'd1;
			board_current_hints_green = board_ram_q;
		end
	end
	
//	if(cnth_fetch.fontcol == 0 && cnth_fetch.subcol == 0) begin
//		off_fetch_char = cnth_fetch.charcol >= 2'd2 ? (cnth_fetch.charcol - 2'd2) : (-11'd1) ;
//		case(cntv.charline)
//			2: `display_string_character_with_mask(TITLE, off_fetch_char, cntv.fontline)
//			3: `display_string_character(TITLE, off_fetch_char, cntv.fontline)
//			4: `display_string_character_with_mask(PALETTE, off_fetch_char, cntv.fontline)
//			5: `display_string_character(OPTIONS,    off_fetch_char, cntv.fontline)
//			6: `display_string_character(HIGHSCORES, off_fetch_char, cntv.fontline)
//			7: `display_string_character_with_mask(BACK, off_fetch_char, cntv.fontline)
//			default: rom_addr = CHAR_;
//		endcase
//	end
	
	//// DRAW ////
	
	if(!cnth.blanking && !cntv.blanking) begin
	
		blink = !time_counter[16] && !time_counter[17];
		is_bg = (cntv.fontline == FONT_H || cnth.fontcol == FONT_W) || (~rom_q[FONT_W - 1 - (cnth.fontcol)]);
		case(GS.state_name)
			GS_MAIN_MENU: begin
				is_selected = (GS.navigation.selected_element == off_charline) && (cntv.fontline != FONT_H);
				case(cnth.drawing_stage)
					MAIN_MENU_TITLE:  color = is_bg ? GS.render.palette.bg : (cnth.val[2:0] + cntv.val[4:2]);
					MAIN_MENU_OPTION: color = get_palette_color(is_bg, is_selected);
					DRAWING_STAGE_NONE: color = GS.render.palette.bg;
				endcase
			end
			GS_OPTIONS: begin
				is_selected = (is_selected_option_line) && (cntv.fontline != FONT_H);
				if(	is_selected &&
						cnth.drawing_stage == OPTIONS_VALUES &&
						GS.navigation.is_selected_sub &&
						GS.navigation.selected_sub_element == cnth.charcol &&
						blink ) begin
					is_bg = 1'd1;
				end
				color = get_palette_color(is_bg, is_selected);
			end
			GS_GAME: begin
			
				case(cnth.drawing_stage)
					DRAWING_STAGE_NONE: color = GS.render.palette.bg;
					BOARD_HINTS: begin // Hints
						if(board_current_line_index <= GS.board.guessed_count &&
							!is_board_current_guess &&
							cnth.charcol < 3'd4) begin
								if(is_bg) color = (cnth.charcol < 2'd2) ? 3'b110 : 3'b010;
								else		 color = 3'b100;
						end else
							color = GS.render.palette.bg;
					end
					BOARD_BORDER_L, BOARD_BORDER_R: begin // Borders
						color = (cnth.val <= cnth.start_subcols + GS.render.board_border_subcols_width) ? GS.render.palette.text : color;
					end
					BOARD_TILE_DIALOG: begin // Tile Dialog
						temp_color_index = cnth.charcol[2:0] + GS.render.board_tiles_dialog_width * (cntv.charline[2:0] - GS.render.board_tiles_dialog_charlines_offset);
						is_selected =  (temp_color_index == GS.navigation.selected_sub_element) || 
											(temp_color_index == GS.navigation.selected_sub_element - GS.render.board_tiles_dialog_width &&
												cntv.fontline == FONT_H) || 
											(temp_color_index == GS.navigation.selected_sub_element - 1'd1 &&
												cnth.fontcol  == FONT_W);
						
						if(cntv.fontline != FONT_H && cnth.fontcol != FONT_W) begin
							if(temp_color_index >= GS.options.pin_colors || (blink && is_selected)) color = get_palette_color(1'd1, is_selected);
							else 																	 						color = get_pin_color(temp_color_index);
						end else begin
							color = (is_selected) ? GS.render.palette.selected_bg : GS.render.palette.bg;
							if((cntv.fontline == FONT_H && cntv.charline == GS.render.board_tiles_dialog_charlines_end) ||
							   (cnth.fontcol  == FONT_W && cnth.charcol  == GS.render.board_tiles_dialog_width - 1'd1)) begin
									color = GS.render.palette.text;
							end
						end
					end
					BOARD_TILES: begin // Tiles
						is_selected = (cnth.charcol == GS.navigation.selected_element - 2'd2);
						color = get_palette_color(1'd1, is_selected);
						if(cnth.fontcol != FONT_W && cntv.fontline != FONT_H) begin
							if(board_current_line_index <= GS.board.guessed_count) begin
								if(is_board_current_guess) color = get_pin_color(GS.board.current_guess[cnth.charcol]);
								else                       color = get_pin_color(board_ram_q[PIN_COLOR_W-1:0]);
							end
							if(cntv.charline == 0 && GS.options.debug) color = get_pin_color(GS.board.secret[cnth.charcol]);
						end
					end
					BOARD_GUESS: begin
						is_selected = GS.navigation.selected_element == 1'd1;
						color = get_palette_color(is_bg, is_selected);
					end
					BOARD_EXIT: begin
						is_selected = GS.navigation.selected_element == 1'd0;
						color = get_palette_color(is_bg, is_selected);
					end
					BOARD_INDEX: begin
						color = get_palette_color(is_bg, 1'd0);
					end
					BOARD_TEXT_DIALOG: begin
						if     (cntv.fontline == FONT_H && GS.board.dial_state == DIAL_HINTSGREEN)  color = C_GREEN;
						else if(cntv.fontline == FONT_H && GS.board.dial_state == DIAL_HINTSYELLOW) color = C_YELLOW;
						else    color = get_palette_color(is_bg || (blink && cnth.dialog_input_charcol < 2'd2), 1'd1);
					end
				endcase
				
				if(cntv.fontline == FONT_H) begin 
					// Upper border of color selection
					if(GS.navigation.is_selected_sub && 
						cntv.charline + 1'd1 == GS.render.board_tiles_dialog_charlines_offset &&
						cnth.val < GS.render.board_tiles_dialog_subcols_end) begin
							color = GS.render.palette.text;
					end else
					// Row Seperators
					if(cnth.drawing_stage == BOARD_BORDER_L || cnth.drawing_stage == BOARD_TILES) begin
						if( board_current_line_index < 2'd2 ||
							 cnth.val - GS.render.board_border1_subcols_end    <= GS.render.board_border_seperator_length ||
							 GS.render.board_border2_subcols_offset - cnth.val <= GS.render.board_border_seperator_length) begin
								color = GS.render.palette.text;
						 end
					end
				end
				
				if(cntv.charline >= GS.render.charlines) begin
						color = GS.render.palette.bg;
				end
				
			end
		endcase
	
		if(GS.options.debug && cntv.val <= 5 && cnth.val <= 5) begin
			color ^= 3'b100;
		end
		
		//color[0] ^= (cnth.charcol == 0 && cnth.fontcol == 0);
		//color[1] |= (cntv.charline == 3);
	end
end





endmodule