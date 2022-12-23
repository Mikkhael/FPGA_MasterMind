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


// [Main Menu]
// Start Game = 0
// Options = 1
// Highscores = 2

typedef struct {
	reg [3:0] selected_element;
	
} st_GS_NAVIGATION;


typedef struct {
	reg [4:0] PIX_W;
	reg [4:0] PIX_H;
	reg [2:0] palette_id;
} st_GS_OPTIONS;

typedef struct {
	reg [2:0] text;
	reg [2:0] bg;
	reg [2:0] selected;
	reg [2:0] selected_bg;
} st_GS_PALETTE;

typedef struct {
	reg values_updated;
	reg [10:0] charlines;
	reg [10:0] charcols;
	// Main Menu
	reg [10:0] title_subcols_offset;
	reg [10:0] title_charlines_offset;
	reg [10:0] title_menu_charlines_offset;
	// Options Menu
	reg [10:0] options_charlines_offset_selected;
	reg [10:0] options_add_subcols_offset_selected;
	reg [10:0] options_charcols_offset;
	// Palette
	st_GS_PALETTE palette;
} st_GS_RENDER;

typedef struct {
	GAME_STATE_NAME 	state_name;
	st_GS_NAVIGATION	navigation;
	st_GS_OPTIONS	 	options;
	st_GS_RENDER      render;
} st_GAME_STATE;


// PALETTES

parameter reg [2:0] palettes_count = 2'd3;
parameter st_GS_PALETTE palettes [0:2] = '{ '{
	text          : 3'b111,
	bg            : 3'b000,
	selected      : 3'b100,
	selected_bg   : 3'b001
}, '{
	text          : 3'b111,
	bg            : 3'b000,
	selected      : 3'b000,
	selected_bg   : 3'b100
}, '{
	text          : 3'b010,
	bg            : 3'b101,
	selected      : 3'b000,
	selected_bg   : 3'b111
}};


// Constants

parameter reg [7:0] title_menu_charlines_offset_add = 3;
parameter reg [4:0] title_pixel_size_add = 4;
