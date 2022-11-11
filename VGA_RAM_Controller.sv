module VGA_RAM_Controller(
	input wire 			clk,
	
	output wire 		ram_rdclk, 
	output reg  [3:0]	ram_rdaddr = 0, 
	input  wire	[7:0] ram_q,
	
	output wire [2:0] RGB,
	output wire 		HSYNC,
	output wire			VSYNC
);

reg [10:0] cnt_h  = 1055;
reg [9:0]  cnt_v  = 627;
reg [1:0] cell_h = 0;
reg [1:0] cell_v = 0;

reg [10:0] cnt_h_2  = 2;
reg [9:0]  cnt_v_2  = 0;
reg [1:0] cell_h_2 = 0;
reg [1:0] cell_v_2 = 0;

reg [2:0] color = 3'b000;

assign RGB   = (cnt_h <  800 && cnt_v < 600) ? color : 3'b000;
assign HSYNC = (cnt_h >= 840 && cnt_h < 968);
assign VSYNC = (cnt_v >= 601 && cnt_v < 605);

assign ram_rdclk = clk;


task advance_counters( inout [10:0] cnt_h, inout [9:0] cnt_v, inout [1:0] cell_h, inout [1:0] cell_v);
begin

	if(cnt_h == 1055) begin
		cnt_h = 0;
		if(cnt_v == 627) begin
			cnt_v = 0;
		end else begin
			cnt_v = cnt_v + 1'd1;
		end
	end else begin
		cnt_h = cnt_h + 1'd1;
	end
	
	case(cnt_h)
		11'd000 : cell_h = 2'd0;
		11'd200 : cell_h = 2'd1;
		11'd400 : cell_h = 2'd2;
		11'd600 : cell_h = 2'd3;
	endcase
	case(cnt_v)
		10'd000 : cell_v = 2'd0;
		10'd150 : cell_v = 2'd1;
		10'd300 : cell_v = 2'd2;
		10'd450 : cell_v = 2'd3;
	endcase
	
end
endtask

always @(posedge clk) begin
	
	advance_counters(cnt_h, cnt_v, cell_h, cell_v);
	advance_counters(cnt_h_2, cnt_v_2, cell_h_2, cell_v_2);
	
	ram_rdaddr = {cell_h_2, cell_v_2};
	
	color = cnt_h[1] ? ram_q[2:0] : ram_q[5:3];
end





endmodule