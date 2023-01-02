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
	reg [3:0] board_drawing_stage;
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

//reg [10:0] off_fetch_char = 0;
reg [10:0] off_charline  = 0;
reg [10:0] start_subcols = 0;
reg options_is_values = 0;
reg is_selected = 0;
reg is_bg = 0;
reg blink = 0;


reg [10:0] board_current_line_index   = 0;
reg [7:0]  board_current_hints_green  = 0;
reg [7:0]  board_current_hints_yellow = 0;

reg [1:0][3:0] board_current_line_index_decimized   = 0;
reg [1:0][3:0] board_current_hints_green_decimized  = 0;
reg [1:0][3:0] board_current_hints_yellow_decimized = 0;

DIV_MOD #(.W_in(8), .W_div(4)) dm_index        (board_current_line_index,   board_current_line_index_decimized[0],   board_current_line_index_decimized[1]);
DIV_MOD #(.W_in(8), .W_div(4)) dm_hints_green  (board_current_hints_green,  board_current_hints_green_decimized[0],  board_current_hints_green_decimized[1]);
DIV_MOD #(.W_in(8), .W_div(4)) dm_hints_yellow (board_current_hints_yellow, board_current_hints_yellow_decimized[0], board_current_hints_yellow_decimized[1]);

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
	if(GS.state_name == GS_GAME) begin
		board_current_line_index = GS.render.charlines - 1'd1 - cntv.charline + GS.board.scroll_offset;
	end
	if(!cnth_fetch.blanking && !cntv.blanking) begin
		case(GS.state_name)
			GS_MAIN_MENU: begin
				// Dont display anything until you reach correct offset, then reset counters to 0
				if(cnth_fetch.val == GS.render.title_subcols_offset) begin
					cnth_fetch.subcol  = 0;
					cnth_fetch.col     = 0;
					cnth_fetch.fontcol = 0;
					cnth_fetch.charcol = 0;
				end else if(cnth_fetch.val < GS.render.title_subcols_offset) begin
					cnth_fetch.charcol = -11'd1;
				end
				if(cntv.charline == GS.render.title_charlines_offset) begin
					// Title
					cntv.pix_size       = GS.options.PIX_H + title_pixel_size_add;
					cnth_fetch.pix_size = GS.options.PIX_W + title_pixel_size_add;
					if(cnth_fetch.fontcol == 0 && cnth_fetch.subcol == 0) begin
						`display_string_character_with_mask(TITLE, cnth_fetch.charcol, cntv.fontline)
					end
				end else begin
					// Menu Entries
					cntv.pix_size       = GS.options.PIX_H;
					cnth_fetch.pix_size = GS.options.PIX_W;
					if(cnth_fetch.fontcol == 0 && cnth_fetch.subcol == 0) begin
						off_charline = cntv.charline - GS.render.title_menu_charlines_offset;
						case(off_charline)
							0: `display_string_character_with_mask(PLAYVSCOMPUTER, cnth_fetch.charcol, cntv.fontline)
							1: `display_string_character_with_mask(PLAYVSHUMAN,    cnth_fetch.charcol, cntv.fontline)
							2: `display_string_character_with_mask(OPTIONS,        cnth_fetch.charcol, cntv.fontline)
							3: `display_string_character_with_mask(HIGHSCORES,     cnth_fetch.charcol, cntv.fontline)
							default: rom_addr = CHAR_;
						endcase
					end
				end
			end
			GS_OPTIONS: begin
				options_is_values = cnth_fetch.val >= GS.render.options_values_subcols_offset;
				off_charline = cntv.charline - GS.render.options_charlines_offset_selected + GS.navigation.selected_element;
				start_subcols = options_is_values ? GS.render.options_values_subcols_offset : GS.render.options_subcols_offset;
				if(cntv.charline == GS.render.options_charlines_offset_selected) begin // Selected Element line
					// Add margin
					start_subcols += options_is_values ? 1'd0 : GS.render.options_add_subcols_offset_selected;
					// Increase size
					cnth_fetch.pix_size = GS.options.PIX_W + (options_is_values ? 1'd0 : 1'd1);
					cntv.pix_size       = GS.options.PIX_H + 1'd1;
				end else begin
					// Revert increased size
					cnth_fetch.pix_size = GS.options.PIX_W;
					cntv.pix_size       = GS.options.PIX_H;
				end
				if(cnth_fetch.val >= start_subcols) begin
					if(cnth_fetch.val == start_subcols) begin
						cnth_fetch.subcol  = 0;
						cnth_fetch.col     = 0;
						cnth_fetch.fontcol = 0;
						cnth_fetch.charcol = 0;
					end
					if(cnth_fetch.fontcol == 0 && cnth_fetch.subcol == 0) begin
						if(options_is_values) begin
							case(off_charline)
								1: `display_decimized_character(options_pin_colors, cnth_fetch.charcol, cntv.fontline)
								2: `display_decimized_character(options_pins_count, cnth_fetch.charcol, cntv.fontline)
								3: `display_decimized_character(options_guesses,    cnth_fetch.charcol, cntv.fontline)
								4: `display_decimized_character(options_PIX_W, cnth_fetch.charcol, cntv.fontline)
								5: `display_decimized_character(options_PIX_H, cnth_fetch.charcol, cntv.fontline)
								6: `display_decimized_character(options_palette_id, cnth_fetch.charcol, cntv.fontline)
								default: rom_addr = CHAR_;
							endcase
						end else begin
							case(off_charline)
								0: `display_string_character_with_mask(BACK,        cnth_fetch.charcol, cntv.fontline)
								1: `display_string_character_with_mask(PINCOLORS,   cnth_fetch.charcol, cntv.fontline)
								2: `display_string_character_with_mask(PINSCOUNT,   cnth_fetch.charcol, cntv.fontline)
								3: `display_string_character_with_mask(GUESSES,     cnth_fetch.charcol, cntv.fontline)
								4: `display_string_character_with_mask(PIXELWIDTH,  cnth_fetch.charcol, cntv.fontline)
								5: `display_string_character_with_mask(PIXELHEIGHT, cnth_fetch.charcol, cntv.fontline)
								6: `display_string_character_with_mask(PALETTE,     cnth_fetch.charcol, cntv.fontline)
								default: rom_addr = CHAR_;
							endcase
						end
					end
				end else begin
					rom_addr = CHAR_;
				end
			end
			GS_GAME: begin
				cnth_fetch.board_drawing_stage = 3'd7;
				if     (cnth_fetch.val >= GS.render.board_hints_subcols_offset)   cnth_fetch.board_drawing_stage = 3'd0;
				else if(cnth_fetch.val >= GS.render.board_border2_subcols_offset) cnth_fetch.board_drawing_stage = 3'd1;
				else if(cnth_fetch.val >= GS.render.board_tiles_subcols_offset)   cnth_fetch.board_drawing_stage = 3'd2;
				else if(cnth_fetch.val >= GS.render.board_border1_subcols_offset) cnth_fetch.board_drawing_stage = 3'd3;
				else if(cntv.charline + 1'd1 != GS.render.charlines && cnth_fetch.val >= GS.render.board_index_subcols_offset) cnth_fetch.board_drawing_stage = 3'd4;
				else if(cntv.charline + 1'd1 == GS.render.charlines && cnth_fetch.val >= GS.render.board_guess_subcols_offset) cnth_fetch.board_drawing_stage = 3'd5;
				else if(cntv.charline + 1'd1 == GS.render.charlines && cnth_fetch.val >= GS.render.board_exit_subcols_offset)  cnth_fetch.board_drawing_stage = 3'd6;
				case(cnth_fetch.board_drawing_stage)
					0: cnth_fetch.start_subcols = GS.render.board_hints_subcols_offset;
					1: cnth_fetch.start_subcols = GS.render.board_border2_subcols_offset;
					2: cnth_fetch.start_subcols = GS.render.board_tiles_subcols_offset;
					3: cnth_fetch.start_subcols = GS.render.board_border1_subcols_offset;
					4: cnth_fetch.start_subcols = GS.render.board_index_subcols_offset;
					5: cnth_fetch.start_subcols = GS.render.board_guess_subcols_offset;
					6: cnth_fetch.start_subcols = GS.render.board_exit_subcols_offset;
				endcase
				if(cnth_fetch.val == cnth_fetch.start_subcols) begin
					cnth_fetch.subcol  = 0;
					cnth_fetch.col     = 0;
					cnth_fetch.fontcol = 0;
					cnth_fetch.charcol = 0;
				end
				cnth_fetch.pix_size = GS.options.PIX_W;
				case(cnth_fetch.board_drawing_stage)
					0: begin // Hints
						if(cnth_fetch.charcol < 2) begin
							`display_decimized_character2(board_current_hints_yellow_decimized, cnth_fetch.charcol, cntv.fontline)
						end else begin
							`display_decimized_character2(board_current_hints_green_decimized,  cnth_fetch.charcol-2'd2, cntv.fontline)
						end
					end
					2: begin // Tiles
						cnth_fetch.pix_size = GS.render.board_tile_pix_width;
						board_ram_raddr = (board_current_line_index - 1'd1) * max_pins_count + cnth_fetch.charcol;
						rom_addr = CHAR_;
					end
					4: begin // Indicies
						if(board_current_line_index > GS.board.guessed_count) begin
							rom_addr = CHAR_;
						end else if(cnth_fetch.charcol == 0) begin
							rom_addr = CHAR_Hash + (cntv.fontline << FONT_LINESHIFT);
						end else begin
							`display_decimized_character2(board_current_line_index_decimized, cnth_fetch.charcol-1'd1, cntv.fontline)
						end
					end
					5: `display_string_character_with_mask(GUESS, cnth_fetch.charcol, cntv.fontline) // GUESS button
					6: `display_string_character_with_mask(EXIT,  cnth_fetch.charcol, cntv.fontline) // EXIT button
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
		is_selected = 0; //(GS.navigation.selected_element + 10'd2 == cntv.charline) && (cntv.fontline != FONT_H);
		case(GS.state_name)
			GS_MAIN_MENU: is_selected = (GS.navigation.selected_element + GS.render.title_menu_charlines_offset == cntv.charline) && (cntv.fontline != FONT_H);
			GS_OPTIONS:   is_selected = (GS.render.options_charlines_offset_selected == cntv.charline) && (cntv.fontline != FONT_H);
			GS_GAME:		  case(GS.navigation.selected_element)
				0: is_selected = (cnth.board_drawing_stage == 3'd6);
				1: is_selected = (cnth.board_drawing_stage == 3'd5);
				default: is_selected = (cnth.board_drawing_stage == 3'd2 && cnth.charcol == GS.navigation.selected_element - 2'd2);
			endcase
		endcase
		
		// Blinking
		blink = time_counter[17];
		if(	GS.state_name == GS_OPTIONS && // Digits in advanced options modifying
				is_selected &&
				GS.navigation.is_selected_sub &&
				GS.navigation.selected_sub_element == cnth.charcol &&
				cnth.val >= GS.render.options_values_subcols_offset &&
				blink ) begin
			is_bg = 1'd1;
		end else if(GS.state_name == GS_GAME && is_selected && blink) begin // Game board elements
			is_bg = 1'd1;
		end else begin
			is_bg = (cntv.fontline == FONT_H || cnth.fontcol == FONT_W) || (~rom_q[FONT_W - 1 - (cnth.fontcol)]);
		end
		
		color = is_bg ? (is_selected ? GS.render.palette.selected_bg : GS.render.palette.bg) : (is_selected ? GS.render.palette.selected : GS.render.palette.text);
		
		
		if(GS.state_name == GS_GAME) begin
			case(cnth.board_drawing_stage)
				0: begin // Hints
					color = GS.render.palette.bg;
					if(board_current_line_index <= GS.board.guessed_count &&
					   cntv.charline + 1'd1 != GS.render.charlines &&
						cnth.charcol < 3'd4) begin
							if(is_bg) color = (cnth.charcol < 2'd2) ? 3'b110 : 3'b010;
							else		 color = 3'b100;
					end
				end
				1,3: begin // Borders
					color = (cnth.val <= cnth.start_subcols + GS.render.board_border_subcols_width) ? GS.render.palette.text : color;
				end
				2: begin // Tiles
					if(cnth.fontcol != FONT_W && 
					   cntv.fontline != FONT_H && 
						board_current_line_index <= GS.board.guessed_count &&
						cnth.charcol < GS.options.pins_count) begin
							if(cntv.charline + 1'd1 == GS.render.charlines) begin
								color = (is_selected && blink) ? GS.render.palette.selected_bg : GS.board.current_guess[cnth.charcol][2:0];
							end else begin
								color = board_ram_q[2:0];
							end
					end
					if(cnth.fontcol != FONT_W && 
					   cntv.fontline != FONT_H &&
						cntv.charline == 0 && 
						GS.options.debug &&
						cnth.charcol < GS.options.pins_count) begin
							color = GS.board.secret[cnth.charcol][2:0];
					end
				end
			endcase
			
			if(cntv.fontline == FONT_H) begin // Row Seperators
				if(( (cntv.charline >= GS.render.charlines - 2'd2) && (cnth.board_drawing_stage == 2'd3 || cnth.board_drawing_stage == 2'd2) ) ||
				   cnth.val - GS.render.board_border1_subcols_end    <= GS.render.board_border_seperator_length ||
					GS.render.board_border2_subcols_offset - cnth.val <= GS.render.board_border_seperator_length)
				color = GS.render.palette.text;
			end
		end
		
		if(GS.state_name == GS_GAME && cntv.charline >= GS.render.charlines) begin
				color = GS.render.palette.bg;
		end
		
		if(GS.state_name == GS_MAIN_MENU) begin
			if(cntv.charline == GS.render.title_charlines_offset) begin
				color = is_bg ? color : (cnth.val[2:0] + cntv.val[4:2]); // TODO: random
			end
		end
		
		if(GS.options.debug && cntv.val <= 5 && cnth.val <= 5) begin
			color ^= 3'b100;
		end
		
		//color[0] |= (cntv.fontline == 0);
		//color[1] |= (cntv.charline == 3);
	end
end





endmodule