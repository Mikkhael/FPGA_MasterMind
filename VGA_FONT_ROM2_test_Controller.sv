module VGA_FONT_ROM2_test_Controller # (
	parameter FNT_H  = 4'd6, // Font height
	parameter FNT_W  = 4'd4, // Font width
	parameter FNT_C  = 8'd64, // Font characters count
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


typedef struct {
	reg [10:0] cnt_h;
	reg [10:0] cnt_v;
	
	reg [10:0] char;
	reg [10:0] row;
	reg [3:0] line;
	reg [(ADDR_SIZE-1):0] lineoff;
	reg [3:0] subline;
	reg [3:0] col;
	reg [3:0] subcol;
} st_counters;

st_counters draw_counters = '{default:0};


reg [2:0] color = 3'b000;

assign RGB   = (draw_counters.cnt_h <  RES_H          && draw_counters.cnt_v < RES_V) ? color : 3'b000;
assign HSYNC = (draw_counters.cnt_h >= RES_H + BLK_HF && draw_counters.cnt_h < RES_H + BLK_HF + BLK_HT);
assign VSYNC = (draw_counters.cnt_v >= RES_V + BLK_VF && draw_counters.cnt_v < RES_V + BLK_VF + BLK_VT);

//assign RGB   = (draw_counters.cnt_h <  800 && draw_counters.cnt_v < 600) ? color : 3'b000;
//assign HSYNC = (draw_counters.cnt_h >= 840 && draw_counters.cnt_h < 968);
//assign VSYNC = (draw_counters.cnt_v >= 601 && draw_counters.cnt_v < 605);

//assign RGB   = (cnt_h <  800 && cnt_v < 600) ? color : 3'b000;
//assign HSYNC = (cnt_h >= 840 && cnt_h < 968);
//assign VSYNC = (cnt_v >= 601 && cnt_v < 605);


assign rom_clk = clk;

reg [(FNT_W-1):0] curr_line = 0;

task automatic advance_counters( 
	ref st_counters c
);
begin

	c.subcol = c.subcol + 1'd1;
	if(c.subcol == PIX_W) begin
		c.subcol = 0;
		c.col = c.col + 1'd1;
		if(c.col == FNT_W + 1) begin
			// New Char
			c.col = 0;
			c.char = c.char + 1'd1;
		end
	end
	
	c.cnt_h = c.cnt_h + 1'd1;
	if(c.cnt_h == H_TIME_TOTAL) begin
		c.cnt_h = 0;
		
		c.char = 0;
		c.col = 0;
		c.subcol = 0;
		
		c.subline = c.subline + 1'd1;
		if(c.subline == PIX_H) begin
			c.subline = 0;
			c.line = c.line + 1'd1;
			c.lineoff = c.lineoff + FNT_C;
			if(c.line == FNT_H + 1) begin
				c.line = 0;
				c.lineoff = 0;
				c.row = c.row + 1'd1;
			end
		end
		
		c.cnt_v = c.cnt_v + 1'd1;
		if(c.cnt_v == V_TIME_TOTAL) begin
			c.cnt_v = 0;
			c.char = 0;
			c.col = 0;
			c.subcol = 0;
			c.subline = 0;
			c.line = 0;
			c.lineoff = 0;
			c.row = 0;
		end
	end
	
	
end
endtask

always @(negedge clk) begin
	
	if(draw_counters.col == FNT_W) begin
		color = 3'b000;
	end else if(draw_counters.line == FNT_H) begin
		color = 3'b000;
	end else begin
		if(draw_counters.row <= 2 || draw_counters.row > 6) begin
			color = curr_line[3 - (draw_counters.col)] ? 3'b001 : 3'b000;
		end else begin
			if(draw_counters.char <= 2 || draw_counters.char > 6) begin
				color = 3'b000;
			end else begin
				color = curr_line[3 - (draw_counters.col)] ? ((draw_counters.row == curr_num + 3) ? 3'b101 : 3'b100) : 3'b000;
			end
		end
	end
	
	
	advance_counters(draw_counters);
	
	
	if(draw_counters.col == 0 && draw_counters.subcol == 0) begin
		curr_line = rom_q;
		if(draw_counters.row <= 2 || draw_counters.row > 6) begin
			rom_addr = (draw_counters.row[3:0]) + draw_counters.lineoff;
		end else begin
			if(draw_counters.char > 2 || draw_counters.char <= 6) begin
				rom_addr = nums[draw_counters.row - 3][3 + 3 - draw_counters.char] + draw_counters.lineoff;
			end
		end
	end
	
	
end





endmodule