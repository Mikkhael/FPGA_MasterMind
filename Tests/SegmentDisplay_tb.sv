task display_clock(
	input [7:0] seg,
	input [3:0] en
); 

automatic int row = 0;
automatic int eni = 0;
begin
	for (row = 0; row < 7; row = row + 1) begin
		$write("   ");
		for (eni = 0; eni < 4; eni = eni + 1) begin
				if(en & (4'b0001 << eni)) begin
					if(row == 0) 					if(seg[0]) $write(" ##   ") ; else $write("      ");
					if(row == 1 || row == 2) 	if(seg[5]) $write("#  "   ) ; else $write("   ");
					if(row == 1 || row == 2) 	if(seg[1]) $write(   "#  ") ; else $write("   ");
					if(row == 3) 					if(seg[6]) $write(" ##   ") ; else $write("      ");
					if(row == 4 || row == 5) 	if(seg[4]) $write("#  "   ) ; else $write("   ");
					if(row == 4 || row == 5) 	if(seg[2]) $write(   "#  ") ; else $write("   ");
					if(row == 6) 					if(seg[3]) $write(" ## "  ) ; else $write("    ");
					if(row == 6) 					if(seg[7]) $write(    "# ") ; else $write("  ");
				end else
					$write("      ");
		end
		$display("");
	end
end
endtask

module SegmentDisplay_tb();

reg Clk = 0;
always #2 Clk = !Clk;


reg  [4:0] Values [0:3];
wire [3:0] EnableOuts;
wire [7:0] SegOuts;

SegmentDisplay u1(Clk, Values, EnableOuts, SegOuts);


integer i = 0;
reg [4:0] val = 5'h0;

initial begin
	for(i = 0; i< 300; i = i + 1) begin
		#1;
		Values[0] = val;
		Values[1] = val + 16;
		Values[2] = val;
		Values[3] = val + 16;
		if(i % 12 == 11) begin
			val = val + 1;
		end
		$display("Val %h, I = %d:", val, i);
		display_clock(SegOuts, EnableOuts);
	end
	$stop;
end

endmodule