module SubSegmentDisplay(
	input  wire [4:0]  Value,
	output reg  [7:0]  Segments
);

always @(Value) begin
	
	//  aa
	// f  b
	// f  b
	//  gg
	// e  c
	// e  c  
	//  dd  .
	
	case(Value[3:0])
		//                  .gfedcba
		4'h0: Segments = 8'b00111111;
		4'h1: Segments = 8'b00000110;
		4'h2: Segments = 8'b01011011;
		4'h3: Segments = 8'b01001111;
		4'h4: Segments = 8'b01100110;
		4'h5: Segments = 8'b01101101;
		4'h6: Segments = 8'b01111101;
		4'h7: Segments = 8'b00000111;
		4'h8: Segments = 8'b01111111;
		4'h9: Segments = 8'b01101111;
		4'ha: Segments = 8'b01110111;
		4'hb: Segments = 8'b01111100;
		4'hc: Segments = 8'b00111001;
		4'hd: Segments = 8'b01011110;
		4'he: Segments = 8'b01111001;
		4'hf: Segments = 8'b01110001;
	endcase
	Segments[7] = Value[4];

end

endmodule

module SegmentDisplay(
	input  wire  		Clk,
	input  wire [4:0] Values [0:3],
	output reg  [3:0] EnableOut = 0,
	output reg  [7:0] SegOut = 0
);
	
reg [2:0] EnI = 0;

reg [7:0] Segs [0:3];
SubSegmentDisplay sub1(Values[0], Segs[0]);
SubSegmentDisplay sub2(Values[1], Segs[1]);
SubSegmentDisplay sub3(Values[2], Segs[2]);
SubSegmentDisplay sub4(Values[3], Segs[3]);

always @(posedge Clk) begin
	EnI <= EnI + 1'd1;
	if(EnI[0] == 0) begin
		EnableOut <= 4'b0000;
		SegOut <= 8'd0;
	end
	else begin
		EnableOut <= 4'b0001 << EnI[2:1];
		SegOut <= Segs[EnI[2:1]];
	end
//	EnI <= EnI + 1'd1;
//	SegOut <= Segs[EnI];
//	EnableOut <= 4'b0001 << EnI;
end

endmodule