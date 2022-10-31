module VGA_Basic_Controller_tb();

wire [2:0] RGB;
wire HSYNC, VSYNC;
reg [2:0] color = 3'b111;
reg clk = 0;

VGA_Basic_Controller vgatb(clk, color, RGB, HSYNC, VSYNC);

wire [10:0] cnt_h;
wire [9:0] cnt_v;

assign cnt_h = vgatb.cnt_h;
assign cnt_v = vgatb.cnt_v;

int i = 0;

initial begin
	#10;
	for(i = 0; i < 1056 * 628 * 2 + 1000; i = i + 1) begin
		clk = ~clk;
		#5;
	end;
	
	$stop;

end

endmodule