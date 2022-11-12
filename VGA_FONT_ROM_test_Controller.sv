module VGA_FONT_ROM_test_Controller # (
	parameter FNT_H  = 6, // Font height
	parameter FNT_W  = 4, // Font width
	parameter FNT_C  = 16, // Font characters count
	parameter ADDR_SIZE    = 7, // Width of address bus for FONT ROM
	
	parameter PIX_W = 10, // Clock pulses per pixel
	parameter PIX_H = 5, // Lines per pixel
	
	// VGA parameters
	parameter RES_H = 800, // Color pulses
	parameter RES_V = 600, // Color lines
	
	parameter BLK_HF = 40,  // Blank Front Porch
	parameter BLK_HT = 128, // Blank Time
	parameter BLK_HB = 88,  // Blank Back Porch
	
	parameter BLK_VF = 1,   // Blank Front Porch
	parameter BLK_VT = 4,   // Blank Time
	parameter BLK_VB = 23   // Blank Back Porch
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

st_counters fetch_counters = '{cnt_h: (FNT_W+1) * PIX_W, char: 1, default:0};
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


reg [10:0] circ_x = 0;
reg [10:0] circ_y = 0;
reg [10:0] circ_r = 0;

reg [21:0] circ_x2 = 0;
reg [21:0] circ_y2 = 0;
reg [21:0] circ_r2 = 0;

always @(posedge clk) begin
	
	advance_counters(draw_counters);
	advance_counters(fetch_counters);
	
	if(fetch_counters.col == 0 && fetch_counters.subcol == 0) begin
		curr_line = rom_q;
		if(fetch_counters.row <= 2 || fetch_counters.row > 6) begin
			rom_addr = (fetch_counters.char % 16) + fetch_counters.lineoff;
		end else begin
			if(fetch_counters.char > 2 || fetch_counters.char <= 6) begin
				rom_addr = nums[fetch_counters.row - 3][3 + 3 - fetch_counters.char] + fetch_counters.lineoff;
			end
		end
	end
	
	
	if(draw_counters.col == FNT_W) begin
		color = 3'b000;
	end else if(draw_counters.line == FNT_H) begin
		color = 3'b000;
	end else begin
		if(draw_counters.row <= 2 || draw_counters.row > 6) begin
			color = curr_line[3 - (draw_counters.col)] ? 3'b100 : 3'b000;
		end else begin
			if(draw_counters.char <= 2 || draw_counters.char > 6) begin
				color = 3'b000;
			end else begin
				color = curr_line[3 - (draw_counters.col)] ? ((draw_counters.row == curr_num + 3) ? 3'b101 : 3'b001) : 3'b000;
			end
		end
	end
	
	
	if(nums[3][0][1:0] == 0) begin // Parabolokoło
		circ_x = draw_counters.cnt_h - (50 + nums[0][2:1]);
		circ_y = draw_counters.cnt_v - (50 + nums[1][2:1]);
		circ_r = 4  + nums[2][2:1];
		
		circ_x2 = circ_x * circ_x;
		circ_y2 = circ_y * circ_y;
		circ_r2 = circ_r * circ_r;
		
		if(circ_x2 + circ_y2 <= circ_r2) begin
			color[1] = 1;
		end
	end else if (nums[3][0][1:0] == 1) begin // Fajerwerkoło
		circ_x = draw_counters.cnt_h - (50 + nums[0][2:1]);
		circ_y = draw_counters.cnt_v - (50 + nums[1][2:1]);
		circ_r = 4  + nums[2][2:1];
		
		circ_x2 = circ_x * circ_x;
		circ_y2 = circ_y * circ_y;
		circ_r2 = circ_r * circ_r;
		
		if(circ_x2[10:0] + circ_y2[10:0] <= circ_r2[10:0]) begin
			color[1] = 1;
		end
	end else if (nums[3][0][1:0] == 2) begin // Fajerwerkoło ale inne
	
		circ_x = (50 + nums[0][2:1]);
		circ_y = (50 + nums[1][2:1]);
		circ_r = (4  + nums[2][2:1]);
		
		if((draw_counters.cnt_h - circ_x) * (draw_counters.cnt_h - circ_x) +
			(draw_counters.cnt_v - circ_y) * (draw_counters.cnt_v - circ_y) <=
			(circ_r) * (circ_r)) begin
				color[1] = 1;
		end
	end else if (nums[3][0][1:0] == 3) begin // Kołokoło
		if(draw_counters.cnt_h >= (50 + nums[0][2:1]))
			circ_x = draw_counters.cnt_h - (50 + nums[0][2:1]);
		else
			circ_x = (50 + nums[0][2:1]) - draw_counters.cnt_h;
			
		if(draw_counters.cnt_v >= (50 + nums[1][2:1]))
			circ_y = draw_counters.cnt_v - (50 + nums[1][2:1]);
		else
			circ_y = (50 + nums[1][2:1]) - draw_counters.cnt_v;
			
		circ_r = 4  + nums[2][2:1];
		
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