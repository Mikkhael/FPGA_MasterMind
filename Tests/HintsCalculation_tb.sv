`timescale 1ns/1ps
//`include "../common.sv"


module HintsCalculation_tb;

reg CLK0;

reg BTN_RAW_LEFT ;
reg BTN_RAW_DOWN ;
reg BTN_RAW_RIGHT;
reg BTN_RAW_UP   ;
reg BTN_RAW_ENTER;
reg BTN_RAW_DEBUG;

reg LED0;
reg LED1;
reg LED2;
reg LED3;

wire VGA_R;
wire VGA_G;
wire VGA_B;
wire VGA_HSYNC;
wire VGA_VSYNC;

Main_Game game(
	CLK0,

	BTN_RAW_LEFT ,
	BTN_RAW_DOWN ,
	BTN_RAW_RIGHT,
	BTN_RAW_UP   ,
	BTN_RAW_ENTER,
	BTN_RAW_DEBUG,

	LED0,
	LED1,
	LED2,
	LED3,

	VGA_R,
	VGA_G,
	VGA_B,
	VGA_HSYNC,
	VGA_VSYNC
);


always #1 CLK0 = ~CLK0;


int i = 0;

initial begin

	#10000;
	$display("Start");
	BTN_RAW_ENTER = 1;
	#100;
	BTN_RAW_ENTER = 0;
	$display("Waiting for generated secret");
	#100;
	while(!game.GS.board.is_guess_uploaded) begin
		#100;
	end
	
	$display("Secret: ");
	for(i=0; i<20; i++) begin
		$write("%h, ", VGA_R); //GS_out.board.secret[i]);
	end
	
	$stop;

end


endmodule