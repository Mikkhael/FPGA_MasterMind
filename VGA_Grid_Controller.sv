module VGA_Grid_Controller(
	input wire 			clk,
	output wire [2:0] RGB,
	output wire 		HSYNC,
	output wire			VSYNC
);

reg [10:0] cnt_h  = 1055;
reg [9:0]  cnt_v  = 627;

reg [2:0] color = 3'b000;

assign RGB   = (cnt_h <  800 && cnt_v < 600) ? color : 3'b000;
assign HSYNC = (cnt_h >= 840 && cnt_h < 968);
assign VSYNC = (cnt_v >= 601 && cnt_v < 605);


always @(posedge clk) begin
	
	if(cnt_h == 1055) begin
		cnt_h = 0;
		if(cnt_v == 627) begin
			cnt_v = 0;
		end else begin
			cnt_v = cnt_v + 10'd1;
		end
	end else begin
		cnt_h = cnt_h + 11'd1;
	end
	
	color = 3'b000;
	if(cnt_h[1] ^ cnt_v[1]) begin
		color = color + 3'b001;
	end
	if(cnt_h[3] ^ cnt_v[3]) begin
		color = color + 3'b010;
	end
	if(cnt_h[5] ^ cnt_v[5]) begin
		color = color + 3'b100;
	end
	
	
end





endmodule