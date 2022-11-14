//`include "game_state.vh"

module VGA_Game_Renderer # (
	parameter FNT_H  = 4'd5, // Font height
	parameter FNT_W  = 4'd4, // Font width
	parameter FNT_C  = 7'd64, // Font characters count
	parameter ADDR_SIZE = 5'd9, // Width of address bus for FONT ROM
	
	parameter PIX_W = 3'd5, // Clock pulses per pixel
	parameter PIX_H = 3'd5, // Lines per pixel
	
	// VGA Timings
	logic [10:0] RES_H = 11'd800, // Color pulses
	logic [10:0] RES_V = 11'd600, // Color lines
	
	logic [10:0] BLK_HF = 11'd40,  // Blank Front Porch
	logic [10:0] BLK_HT = 11'd128, // Blank Time
	logic [10:0] BLK_HB = 11'd88,  // Blank Back Porch
	
	logic [10:0] BLK_VF = 11'd1,   // Blank Front Porch
	logic [10:0] BLK_VT = 11'd4,   // Blank Time
	logic [10:0] BLK_VB = 11'd23   // Blank Back Porch
)(
	input wire 			clk,
	
	output wire 		rom_clk, 
	output reg  [(ADDR_SIZE-1):0]	rom_addr = 0, 
	input  wire	[(FNT_W-1):0]     rom_q,
	
	input st_GAME_STATE GS,
	
	output wire [2:0] RGB,
	output wire 		HSYNC,
	output wire			VSYNC
);

localparam H_TIME_TOTAL = RES_H + BLK_HF + BLK_HT + BLK_HB;
localparam V_TIME_TOTAL = RES_V + BLK_VF + BLK_VT + BLK_VB;

typedef struct{
	reg [10:0] h;
	reg [10:0] v;
	
	reg [10:0] fetch_char;
	
	reg [10:0] char;
	reg [3:0] col;
	reg [3:0] subcol;
	
	reg [10:0] row;
	reg [3:0] line;
	reg [(ADDR_SIZE-1):0] lineoff;
	reg [3:0] subline;
	
} st_counters;

st_counters cnt = '{fetch_char:1, default:0};
reg [(FNT_W-1):0] curr_line = 0;

reg [2:0] color = 3'b000;

assign RGB   = (cnt.h <  RES_H          && cnt.v < RES_V) ? color : 3'b000;
assign HSYNC = (cnt.h >= RES_H + BLK_HF && cnt.h < RES_H + BLK_HF + BLK_HT);
assign VSYNC = (cnt.v >= RES_V + BLK_VF && cnt.v < RES_V + BLK_VF + BLK_VT);

assign rom_clk = clk;

reg is_blanking_h = 0;
reg is_blanking_v = 0;

reg off_fetch_char = 0;

always @(posedge clk) begin
	
	//// ADVANCE COUNTERS ////
	
	if(cnt.h == RES_H) begin // Czy skończyło się wyświetlanie lini
		is_blanking_h = 1;
		// Horizontal Reset
		cnt.char = ~11'd0;
		cnt.fetch_char = 0;
		cnt.col = 0;
		cnt.subcol = 0;
		
		if(cnt.v == RES_V) begin // Czy skończył się wyświetlanie klatki
			is_blanking_v = 1;
			// Vertical Reset
			cnt.row = 0;
			cnt.line = 0;
			cnt.lineoff = 0;
			cnt.subline = 0;
		end else if (~is_blanking_v) begin
			// Vertical Increment
			cnt.subline = cnt.subline + 1'd1;
			if(cnt.subline == PIX_H) begin
				cnt.subline = 0;
				cnt.line = cnt.line + 1'd1;
				cnt.lineoff = cnt.lineoff + FNT_C;
				if(cnt.line == FNT_H + 1) begin
					cnt.line = 0;
					cnt.lineoff = 0;
					cnt.row = cnt.row + 1'd1;
				end
			end
		end		
	end else if(~is_blanking_h) begin
		// Horizontal Increment
		cnt.subcol = cnt.subcol + 1'd1;
		if(cnt.subcol == PIX_W) begin
			cnt.subcol = 0;
			cnt.col = cnt.col + 1'd1;
			if(cnt.col == FNT_W + 1) begin
				cnt.col = 0;
				cnt.char = cnt.char + 1'd1;
				cnt.fetch_char = cnt.char + 1'd1;
			end
		end
	end
	
	cnt.h = cnt.h + 1'd1;
	if(cnt.h == H_TIME_TOTAL) begin
		cnt.h = 0;
		is_blanking_h = 0;
		cnt.v = cnt.v + 1'd1;
		if(cnt.v == V_TIME_TOTAL) begin
			cnt.v = 0;
			is_blanking_v = 0;
		end
	end
	
	//// FETCH ////
	
	// TODO : TO IMPROVE
	if(cnt.col == 0 && cnt.subcol == 0) begin // Czy zaczął się nowy znak
		off_fetch_char = cnt.fetch_char - 2;
		curr_line = rom_q; // Przepisz poprzedni znak do buforu
		if(cnt.row == 2 && off_fetch_char <= 3) begin
			rom_addr = (STR_TITLE[off_fetch_char]) + cnt.lineoff;
		end else if(cnt.row == 3 && off_fetch_char <= 3) begin
			rom_addr = (STR_OPTS[off_fetch_char]) + cnt.lineoff;
		end else if(cnt.row == 5 &&  off_fetch_char <= 3) begin
			rom_addr = (STR_TEST[off_fetch_char]) + cnt.lineoff;
		end else begin
			rom_addr = 0;
		end
	end
	
	//// DRAW ////
	
	if(cnt.col == FNT_W) begin
		color = 3'b000;
	end else if(cnt.line == FNT_H) begin
		color = 3'b000;
	end else begin
//		color = curr_line[3 - (cnt.col)] ? ((cnt.row + 2 == GS.main_menu.selected_element) ? 3'b111 : GS.options.color) : 3'b000;
		color = curr_line[3 - (cnt.col)] ? 3'b111 : 3'b000;
	end
	
end





endmodule