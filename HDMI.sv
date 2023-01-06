module TMDS_ENCODER(
	input wire clk,
	input wire [7:0] data,
	input wire [1:0] ctrl,
	input wire is_blanking,
	output reg [9:0] out = 0
);
	
	reg [8:0] qm = 0;
	reg signed [7:0] cnt = 0;


	function [3:0] count_ones(input [7:0] val);
		count_ones = 
					val[0] + 
					val[1] + 
					val[2] + 
					val[3] + 
					val[4] + 
					val[5] + 
					val[6] + 
					val[7];
	endfunction

	wire [3:0] N1_data = count_ones(data);
	wire [3:0] N1_qm	 = count_ones(qm[7:0]);
	//wire [3:0] N0_data = count_ones(~data);
	wire [3:0] N0_qm	 = count_ones(~qm[7:0]);

	always_comb begin
		if(N1_data > 4 || (N1_data == 4 && data[0]  == 0)) begin
			qm[0] = data[0];
			qm[1] = qm[0] ~^ data[1];
			qm[2] = qm[1] ~^ data[2];
			qm[3] = qm[2] ~^ data[3];
			qm[4] = qm[3] ~^ data[4];
			qm[5] = qm[4] ~^ data[5];
			qm[6] = qm[5] ~^ data[6];
			qm[7] = qm[6] ~^ data[7];
			qm[8] = 0;
		end else begin
			qm[0] = data[0];
			qm[1] = qm[0]  ^ data[1];
			qm[2] = qm[1]  ^ data[2];
			qm[3] = qm[2]  ^ data[3];
			qm[4] = qm[3]  ^ data[4];
			qm[5] = qm[4]  ^ data[5];
			qm[6] = qm[5]  ^ data[6];
			qm[7] = qm[6]  ^ data[7];
			qm[8] = 1;
		end
	end

		
	always_ff @(posedge clk) begin
		if(is_blanking) begin
			
			case(ctrl)
				2'b00: out <= 10'b1101010100;
				2'b01: out <= 10'b0010101011;
				2'b10: out <= 10'b0101010100;
				2'b11: out <= 10'b1010101011;
			endcase
			
		end else begin
			if(cnt == 0 || N1_qm == N0_qm) begin
				
				out[9] 	<= ~qm[8];
				out[8] 	<= qm[8];
				out[7:0] <= qm[8] ? qm[7:0] : ~qm[7:0];
				
				if(qm[8] == 0) begin
					cnt <= cnt + N0_qm - N1_qm;
				end else begin
					cnt <= cnt + N1_qm - N0_qm;
				end
				
			end else if(
				(cnt > 0 && N1_qm > N0_qm) ||
				(cnt < 0 && N0_qm > N1_qm)
			) begin
				out[9] 	<= 1;
				out[8] 	<= qm[8];
				out[7:0] <= ~qm[7:0];
				cnt <= cnt + 2'd2*(qm[8]) + N0_qm - N1_qm;
			end else begin
				out[9] 	<= 0;
				out[8] 	<= qm[8];
				out[7:0] <= qm[7:0];
				cnt <= cnt - 2'd2*(~qm[8]) + N1_qm - N0_qm;
			end
		end
	end

endmodule

module TMDS_SHIFT_REGISTER(
	input wire clk,
	input wire [9:0] in,
	output wire  out
);

	reg [3:0] counter = 0;
	reg [9:0] out_temp = 0;

	assign out = out_temp[0];

	always_ff @(posedge clk) begin
		if(counter == 4'd9) begin
			counter  <= 0;
			out_temp <= in;
		end else begin
			counter  	  <= counter + 1'd1;
			out_temp[8:0] <= out_temp[9:1];
		end
	end

endmodule

module VGA_TO_HDMI(
	input clk,
	input clk_bit,
	
	input [2:0] color,
	//input [PIN_COLOR_W-1:0] color_index,
	input is_blanking,
	input hsync,
	input	vsync,
	
	output [2:0] tmds_bits
);
	
//	wire [7:0] color_0 = (color_index == PIN_COLOR_NONE) ? (color[0] ? 8'b11111111 : 8'b00000000) : 8'b10101010;//hdmi_pin_colorset[color_index][7:0];
//	wire [7:0] color_1 = (color_index == PIN_COLOR_NONE) ? (color[1] ? 8'b11111111 : 8'b00000000) : 8'b10101010;//hdmi_pin_colorset[color_index][15:8];
//	wire [7:0] color_2 = (color_index == PIN_COLOR_NONE) ? (color[2] ? 8'b11111111 : 8'b00000000) : 8'b10101010;//hdmi_pin_colorset[color_index][23:16];

	wire [7:0] color_0 = (color[0] ? 8'b11111111 : 8'b00000000);
	wire [7:0] color_1 = (color[1] ? 8'b11111111 : 8'b00000000);
	wire [7:0] color_2 = (color[2] ? 8'b11111111 : 8'b00000000);
	
	wire [9:0] tmds_out_0;
	wire [9:0] tmds_out_1;
	wire [9:0] tmds_out_2;
	
	
	TMDS_ENCODER tmds0(
		clk,
		color_0,
		{vsync, hsync},
		is_blanking,
		tmds_out_0
	);
	TMDS_ENCODER tmds1(
		clk,
		color_1,
		2'b00,
		is_blanking,
		tmds_out_1
	);
	TMDS_ENCODER tmds2(
		clk,
		color_2,
		2'b00,
		is_blanking,
		tmds_out_2
	);
	
	TMDS_SHIFT_REGISTER tmds_shift_0(clk_bit, tmds_out_0, tmds_bits[0]);
	TMDS_SHIFT_REGISTER tmds_shift_1(clk_bit, tmds_out_1, tmds_bits[1]);
	TMDS_SHIFT_REGISTER tmds_shift_2(clk_bit, tmds_out_2, tmds_bits[2]);
	
endmodule
