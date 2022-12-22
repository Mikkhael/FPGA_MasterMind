module VGA_Game_Renderer(
	input wire 			clk,
	
	output wire 		rom_clk, 
	output reg  [(ADDR_W-1):0]	rom_addr = 0, 
	input  wire	[(FONT_W-1):0]     rom_q,
	
	input st_GAME_STATE GS,
	
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
} st_counters_h;

typedef struct{
	reg blanking;
	reg [10:0] val;
	reg [4:0] subline;
	reg [10:0] line;
	
	reg [ADDR_W-1:0] fontline;
	
	reg [10:0] charline;
	
	reg skip_spacing_once;
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
		if(++cnth.subcol == GS.options.PIX_W) begin
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
		
	end else if(~cnth.blanking) begin // Czy jesteśmy w sekcji kolorowego obrazu
		// Increment
		if(++cntv.subline == GS.options.PIX_H) begin
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



`define display_string_character(name, index, fontline) \
	rom_addr = (index < STR_``name``_LEN) ? (STR_``name[index] + (fontline << FONT_LINESHIFT)) : CHAR_;

`define display_string_character_with_mask(name, index, fontline) \
   begin \
	`display_string_character(name, index, fontline) \
	cnth_fetch.skip_spacing_once = (index < STR_``name``_LEN) && (STR_MASK_``name``[index]); \
	end
	


reg [10:0] off_fetch_char = 0;
reg is_selected = 0;
reg is_bg = 0;

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
	
	if(cnth_fetch.fontcol == 0 && cnth_fetch.subcol == 0) begin
		off_fetch_char = cnth_fetch.charcol >= 2'd2 ? (cnth_fetch.charcol - 2'd2) : (-11'd1) ;
		case(cntv.charline)
			2: `display_string_character_with_mask(TITLE, off_fetch_char, cntv.fontline)
			3: `display_string_character(TITLE, off_fetch_char, cntv.fontline)
			4: `display_string_character_with_mask(PALETTE, off_fetch_char, cntv.fontline)
			5: `display_string_character(OPTIONS,    off_fetch_char, cntv.fontline)
			6: `display_string_character(HIGHSCORES, off_fetch_char, cntv.fontline)
			7: `display_string_character_with_mask(BACK, off_fetch_char, cntv.fontline)
			default: rom_addr = CHAR_;
		endcase
	end
	
	//// DRAW ////
	
	is_selected = (GS.navigation.selected_element + 10'd2 == cntv.charline) && (cntv.fontline != FONT_H);
	is_bg = (cntv.fontline == FONT_H || cnth.fontcol == FONT_W) || (~rom_q[FONT_W - 1 - (cnth.fontcol)]);
	color = is_bg ? (is_selected ? GS.render.palette.selected_bg : GS.render.palette.bg) : (is_selected ? GS.render.palette.selected : GS.render.palette.text);
	
end





endmodule