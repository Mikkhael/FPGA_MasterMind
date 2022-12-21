`include "generated_params.vh"


	
//// VGA Timings ////

parameter logic [10:0] RES_H = 11'd800; // Color pulses
parameter logic [10:0] RES_V = 11'd600; // Color lines

parameter logic [10:0] BLK_HF = 11'd40;  // Blank Front Porch
parameter logic [10:0] BLK_HT = 11'd128; // Blank Time
parameter logic [10:0] BLK_HB = 11'd88;  // Blank Back Porch

parameter logic [10:0] BLK_VF = 11'd1;   // Blank Front Porch
parameter logic [10:0] BLK_VT = 11'd4;   // Blank Time
parameter logic [10:0] BLK_VB = 11'd23;   // Blank Back Porch

parameter H_TIME_TOTAL = RES_H + BLK_HF + BLK_HT + BLK_HB;
parameter V_TIME_TOTAL = RES_V + BLK_VF + BLK_VT + BLK_VB;

//// Game State Machine Types ////


typedef enum logic [1:0] {GS_MAIN_MENU, GS_OPTIONS} GAME_STATE_NAME;

parameter GS_MAIN_MENU_ELEMENTS = 3;

typedef struct {
	reg [1:0] selected_element;
} st_GS_MAIN_MENU;


typedef struct {
	reg [2:0] color;
} st_GS_OPTIONS;

typedef struct {
	GAME_STATE_NAME 	state_name;
	st_GS_MAIN_MENU	main_menu;
	st_GS_OPTIONS	 	options;
} st_GAME_STATE;


