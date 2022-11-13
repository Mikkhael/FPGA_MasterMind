module VGA_FONT_ROM_test_Controller # (
	parameter FNT_H  = 4'd6, // Font height
	parameter FNT_W  = 4'd4, // Font width
	parameter FNT_C  = 5'd16, // Font characters count
	parameter ADDR_SIZE    = 4'd7, // Width of address bus for FONT ROM
	
	parameter PIX_W = 3'd1, // Clock pulses per pixel
	parameter PIX_H = 3'd1, // Lines per pixel
	
	// VGA parameters
	parameter RES_H = 11'd800, // Color pulses
	parameter RES_V = 11'd600, // Color lines
	
	parameter BLK_HF = 11'd40,  // Blank Front Porch
	parameter BLK_HT = 11'd128, // Blank Time
	parameter BLK_HB = 11'd88,  // Blank Back Porch
	
	parameter BLK_VF = 11'd1,   // Blank Front Porch
	parameter BLK_VT = 11'd4,   // Blank Time
	parameter BLK_VB = 11'd23   // Blank Back Porch
)(
	input wire 			clk,
	
	output wire 		rom_clk, 
	output reg  [(ADDR_SIZE-1):0]	rom_addr = 0, 
	input  wire	[(FNT_W-1):0]     rom_q,
	
	input  wire [3:0][3:0] nums [0:3],
	input  wire [1:0]  curr_num,
	
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

reg [2:0] color = 3'b000;

assign RGB   = (cnt.h <  RES_H          && cnt.v < RES_V) ? color : 3'b000;
assign HSYNC = (cnt.h >= RES_H + BLK_HF && cnt.h < RES_H + BLK_HF + BLK_HT);
assign VSYNC = (cnt.v >= RES_V + BLK_VF && cnt.v < RES_V + BLK_VF + BLK_VT);

//assign RGB   = (draw_counters.cnt_h <  800 && draw_counters.cnt_v < 600) ? color : 3'b000;
//assign HSYNC = (draw_counters.cnt_h >= 840 && draw_counters.cnt_h < 968);
//assign VSYNC = (draw_counters.cnt_v >= 601 && draw_counters.cnt_v < 605);

//assign RGB   = (cnt_h <  800 && cnt_v < 600) ? color : 3'b000;
//assign HSYNC = (cnt_h >= 840 && cnt_h < 968);
//assign VSYNC = (cnt_v >= 601 && cnt_v < 605);


assign rom_clk = clk;

reg [(FNT_W-1):0] curr_line = 0;

reg [10:0] circ_x = 0;
reg [10:0] circ_y = 0;
reg [10:0] circ_r = 0;

reg [21:0] circ_x2 = 0;
reg [21:0] circ_y2 = 0;
reg [21:0] circ_r2 = 0;

reg is_blanking_h = 0;
reg is_blanking_v = 0;

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
	
	if(cnt.col == 0 && cnt.subcol == 0) begin // Czy zaczął się nowy znak
		curr_line = rom_q; // Przepisz poprzedni znak do buforu
		if(cnt.row <= 2 || cnt.row > 6) begin //
			//rom_addr = (cnt.fetch_char % 16) + cnt.lineoff;
			rom_addr = (cnt.char[3:0]) + cnt.lineoff;
		end else begin
			if(cnt.fetch_char > 2 || cnt.fetch_char <= 6) begin
				rom_addr = nums[cnt.row - 3][3 + 3 - cnt.fetch_char] + cnt.lineoff;
			end
		end
	end
	
	//// DRAW ////
	
	if(cnt.col == FNT_W) begin
		color = 3'b000;
	end else if(cnt.line == FNT_H) begin
		color = 3'b000;
	end else begin
		if(cnt.row <= 2 || cnt.row > 6) begin
			color = curr_line[3 - (cnt.col)] ? 3'b100 : 3'b000;
		end else begin
			if(cnt.char <= 2 || cnt.char > 6) begin
				color = 3'b000;
			end else begin
				color = curr_line[3 - (cnt.col)] ? ((cnt.row == curr_num + 3) ? 3'b101 : 3'b001) : 3'b000;
			end
		end
	end
	
	
	circ_x = cnt.h - (11'd400 + nums[0][2:1]);
	circ_y = cnt.v - (11'd300 + nums[1][2:1]);
	circ_r = 11'd4  + nums[2][2:1];
	
	if(nums[3][0][1:0] == 2) begin // Parabolokoło
		circ_x2 = circ_x * circ_x;
		circ_y2 = circ_y * circ_y;
		circ_r2 = circ_r * circ_r;
		if(circ_x2 + circ_y2 <= circ_r2) begin
			color[1] = 1;
		end
	end else if (nums[3][0][1:0] == 0) begin // Fajerwerkoło		
		circ_x2 = circ_x * circ_x;
		circ_y2 = circ_y * circ_y;
		circ_r2 = circ_r * circ_r;
		if(circ_x2[10:0] + circ_y2[10:0] <= circ_r2[10:0]) begin
			color[1] = 1;
		end
	end else if (nums[3][0][1:0] == 1) begin // Kołokoło
		if(circ_x[10]) circ_x = ~circ_x + 1'd1;
		if(circ_y[10]) circ_y = ~circ_y + 1'd1;
		circ_x2 = circ_x * circ_x;
		circ_y2 = circ_y * circ_y;
		circ_r2 = circ_r * circ_r;
		if(circ_x2 + circ_y2 <= circ_r2) begin
			color[1] = 1;
		end
	end

	
	
//	if(draw_counters.char + 1 == fetch_counters.char) begin
//		color[0] = 1;
//	end
//	if(draw_counters.char == fetch_counters.char) begin
//		color[1] = 1;
//	end
	

//	draw_counters.cnt_h = draw_counters.cnt_h + 1'd1;
//	if(draw_counters.cnt_h == 1056) begin
//		draw_counters.cnt_h = 0;
//		draw_counters.cnt_v = draw_counters.cnt_v + 1'd1;
//		if(draw_counters.cnt_v == 628) begin
//			draw_counters.cnt_v = 0;
//		end
//	end

//	color[2] = ~draw_counters.cnt_h[0];
//	color[1] = ~draw_counters.cnt_v[0];
//	color[0] = 0;

//	cnt_h = cnt_h + 1'd1;
//	if(cnt_h == 1056) begin
//		cnt_h = 0;
//		cnt_v = cnt_v + 1'd1;
//		if(cnt_v == 628) begin
//			cnt_v = 0;
//		end
//	end
//
//	color[2] = ~cnt_h[1];
//	color[1] = ~cnt_v[1];
//	color[0] = 0;
	
end





endmodule