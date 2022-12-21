module VGA_Game_Renderer # (
	parameter PIX_W = 3'd5, // Clock pulses per pixel
	parameter PIX_H = 3'd5 // Lines per pixel
)(
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
} st_counters_h;

typedef struct{
	reg blanking;
	reg [10:0] val;
	reg [4:0] subline;
	reg [10:0] line;
	
	reg [10:0] fontline;
	
	reg [10:0] charline;
} st_counters_v;

st_counters_h cnth       = '{default: 0, val: (H_TIME_TOTAL - 4), blanking: 1};
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
		cnth.charcol = -1;
		
	end else if(~cnth.blanking) begin // Czy jesteśmy w sekcji kolorowego obrazu
		// Increment
		cnth.subcol = cnth.subcol + 1'd1;
		if(cnth.subcol == PIX_W) begin
			cnth.subcol = 0;
			cnth.col = cnth.col + 1'd1;
			// Advance displayed font pixel
			cnth.fontcol = cnth.fontcol + 1'd1;
			if(cnth.fontcol == FONT_W + 1) begin
				cnth.fontcol = 0;
				cnth.charcol = cnth.charcol + 1'd1;
			end
		end
	end
	
	cnth.val = cnth.val + 1'd1;
	if(cnth.val == H_TIME_TOTAL) begin
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
		
	end else if(~cnth.blanking) begin // Czy jesteśmy w sekcji kolorowego obrazu
		// Increment
		cntv.subline = cntv.subline + 1'd1;
		if(cntv.subline == PIX_H) begin
			cntv.subline = 0;
			cntv.line = cntv.line + 1'd1;
			// Advance displayed font pixel
			cntv.fontline = cntv.fontline + 1'd1;
			if(cntv.fontline == FONT_H + 1) begin
				cntv.fontline = 0;
				cntv.charline = cntv.charline + 1'd1;
			end
		end
	end
	
	cntv.val = cntv.val + 1'd1;
	if(cntv.val == V_TIME_TOTAL) begin
		cntv.val = 0;
		cntv.blanking = 0;
	end
	
endtask

reg [10:0] off_fetch_char = 0;


always @(posedge clk) begin
	
	//// ADVANCE COUNTERS ////
	
	advance_counters_h(GS, cnth);
	advance_counters_h(GS, cnth_fetch);
	
	if(cnth.val == RES_H) begin // Jeśli skończyliśmy rysować linię
		advance_counters_v(GS, cntv);
	end
	
	
	//// FETCH ////
	
	// TODO : TO IMPROVE
//	if(cnth_fetch.col == 0 && cnth_fetch.subcol == 0) begin // Czy zaczął się nowy znak
//		off_fetch_char = cnth_fetch.charcol - 2'd2 - (GS.main_menu.selected_element + 10'd2 == cntv.charline);
//		case(cntv.charline)
//			2: if(off_fetch_char < STR_TITLE_LEN)	rom_addr = STR_TITLE[off_fetch_char]	+ (cntv.fontline << FONT_LINESHIFT);
//			3: if(off_fetch_char < STR_OPTS_LEN)	rom_addr = STR_OPTS[off_fetch_char]		+ (cntv.fontline << FONT_LINESHIFT);
//			5: if(off_fetch_char < STR_TEST_LEN)	rom_addr = STR_TEST[off_fetch_char]		+ (cntv.fontline << FONT_LINESHIFT);
//			default: rom_addr = 320;
//		endcase
//	end
	
	if(cnth_fetch.fontcol == 0 && cnth_fetch.subcol == 0) begin
		off_fetch_char = cnth_fetch.charcol >= 2'd2 ? (cnth_fetch.charcol - 2'd2) : (400) ;
		case(cntv.charline)
			2: rom_addr = (off_fetch_char < STR_TITLE_LEN) ? (STR_TITLE[off_fetch_char] + (cntv.fontline << FONT_LINESHIFT)) : CHAR_;
			3: rom_addr = (off_fetch_char < STR_OPTS_LEN)  ? (STR_OPTS[off_fetch_char]  + (cntv.fontline << FONT_LINESHIFT)) : CHAR_;
			5: rom_addr = (off_fetch_char < STR_TEST_LEN)  ? (STR_TEST[off_fetch_char]	 + (cntv.fontline << FONT_LINESHIFT)) : CHAR_;
			default: rom_addr = CHAR_;
		endcase
	end
	
	//rom_addr = (cntv.fontline << FONT_LINESHIFT) + (cnth_fetch.charcol + cntv.charline*2);
	
	//// DRAW ////
	
	color =  (GS.main_menu.selected_element + 10'd2 == cntv.charline) ? (GS.options.color + 3'd2) : (GS.options.color + 3'd1);
	if(cntv.fontline != FONT_H && cnth.fontcol != FONT_W) begin
		color = rom_q[3 - (cnth.fontcol)] ? GS.options.color : color;
	end
	
end





endmodule