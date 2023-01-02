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


typedef enum logic [2:0] {GS_MAIN_MENU, GS_OPTIONS, GS_GAME, GS_GENERATE_PINS} GAME_STATE_NAME;

parameter GS_MAIN_MENU_ELEMENTS = 3;


// [Main Menu]
// Start Game = 0
// Options = 1
// Highscores = 2

typedef struct {
	reg [7:0] selected_element;
	reg [7:0] selected_sub_element;
	reg is_selected_sub;
} st_GS_NAVIGATION;

parameter reg [2:0] PIX_VALUE_W = 3'd6;
parameter reg [2:0] PIN_COLOR_W = 3'd5;
parameter reg [2:0] PIN_POS_W   = 3'd5;
parameter reg [PIN_COLOR_W-1:0] max_pin_colors = 5'd21;
parameter reg [PIN_POS_W-1:0]   max_pins_count = 5'd20;
parameter reg [7:0] max_guesses    = 8'd99;

parameter reg [11:0] ram_hints_offset = max_pins_count * max_guesses;

typedef struct {
	reg [PIN_COLOR_W-1:0] pin_colors;
	reg [PIN_POS_W-1:0]   pins_count;
	reg [7:0] guesses;
	reg [PIX_VALUE_W-1:0] PIX_W;	
	reg [PIX_VALUE_W-1:0] PIX_H;  
	reg [2:0] palette_id; 

	reg debug;  		
} st_GS_OPTIONS;


typedef struct {
	reg is_vs_human;
	reg [7:0] guessed_count;
	reg [7:0] scroll_offset;
	reg [PIN_COLOR_W-1:0] current_guess [0:max_pins_count-1];
	
	reg is_guess_entered;
	reg is_guess_uploading;
	reg is_guess_uploaded;
	
	reg [PIN_POS_W-1:0] calculated_green;
	reg [PIN_POS_W-1:0] calculated_yellow;
	
	reg [max_pins_count-1:0] analyzed_guess;
	reg [max_pins_count-1:0] analyzed_secret;

	reg [PIN_COLOR_W-1:0] secret [0:max_pins_count-1];
} st_GS_BOARD;

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
	reg [10:0] pixels_H;
	// Main Menu
	reg [10:0] title_subcols_offset;
	reg [10:0] title_charlines_offset;
	reg [10:0] title_menu_charlines_offset;
	// Options Menu
	reg [10:0] options_charlines_offset_selected;
	reg [10:0] options_add_subcols_offset_selected;
	reg [10:0] options_subcols_offset;
	reg [10:0] options_values_subcols_offset;
	// Board
	reg [5:0]  board_tile_pix_width;
	reg [10:0] board_tiles_pixels_available;
	reg [10:0] board_index_subcols_offset;
	reg [10:0] board_border1_subcols_offset;
	reg [10:0] board_border1_subcols_end;
	reg [10:0] board_border2_subcols_offset;
	reg [10:0] board_border_subcols_width;
	reg [10:0] board_tiles_subcols_offset;
	reg [10:0] board_hints_subcols_offset;
	reg [10:0] board_border_seperator_length;
	reg [10:0] board_exit_subcols_offset;
	reg [10:0] board_guess_subcols_offset;
	// Palette
	st_GS_PALETTE palette;
} st_GS_RENDER;

typedef struct {
	GAME_STATE_NAME 	state_name;
	st_GS_NAVIGATION	navigation;
	st_GS_OPTIONS	 	options;
	st_GS_RENDER      render;
	st_GS_BOARD			board;
} st_GAME_STATE;

// DECIMALIZER

parameter GS_DECIM_options_pin_colors_LEN = 2'd2;
parameter GS_DECIM_options_pins_count_LEN = 2'd2;
parameter GS_DECIM_options_guesses_LEN = 2'd2;
parameter GS_DECIM_options_PIX_W_LEN = 2'd2;
parameter GS_DECIM_options_PIX_H_LEN = 2'd2;
parameter GS_DECIM_options_palette_id_LEN = 1'd1;

typedef struct {
	reg [GS_DECIM_options_pin_colors_LEN-1:0][3:0] 		options_pin_colors;
	reg [GS_DECIM_options_pins_count_LEN-1:0][3:0] 		options_pins_count;
	reg [GS_DECIM_options_guesses_LEN-1:0][3:0] 		   options_guesses;
	reg [GS_DECIM_options_PIX_W_LEN-1:0][3:0] 		   options_PIX_W;
	reg [GS_DECIM_options_PIX_H_LEN-1:0][3:0] 	   	options_PIX_H;
	reg [GS_DECIM_options_palette_id_LEN-1:0][3:0]     options_palette_id;
} st_GS_DECIMALIZED;

module GS_DECIMALIZER(
	input  st_GAME_STATE GS,
	output st_GS_DECIMALIZED GS_decim
);

	DIV_MOD #(.W_in(PIN_COLOR_W), .W_div(4)) dm1(GS.options.pin_colors, GS_decim.options_pin_colors[0], GS_decim.options_pin_colors[1]);
	DIV_MOD #(.W_in(PIN_POS_W),   .W_div(4)) dm2(GS.options.pins_count, GS_decim.options_pins_count[0], GS_decim.options_pins_count[1]);
	DIV_MOD #(.W_in(8), .W_div(4))           dm3(GS.options.guesses, GS_decim.options_guesses[0], GS_decim.options_guesses[1]);
	DIV_MOD #(.W_in(PIX_VALUE_W), .W_div(4)) dm4(GS.options.PIX_W, GS_decim.options_PIX_W[0], GS_decim.options_PIX_W[1]);
	DIV_MOD #(.W_in(PIX_VALUE_W), .W_div(4)) dm5(GS.options.PIX_H, GS_decim.options_PIX_H[0], GS_decim.options_PIX_H[1]);
	assign GS_decim.options_palette_id = GS.options.palette_id;
endmodule

parameter reg [10:0] powers_of_10 [0:3] = '{11'd1, 11'd10, 11'd100, 11'd1000};

// PALETTES

parameter reg [2:0] palettes_count = 3'd5;
parameter st_GS_PALETTE palettes [0:4] = '{ 
'{
	// BLack & White with Blue Selection
	text          : 3'b111, 
	bg            : 3'b000,
	selected      : 3'b100,
	selected_bg   : 3'b001
}, '{
	// BLack & White with Red Selection
	text          : 3'b111, 
	bg            : 3'b000,
	selected      : 3'b010,
	selected_bg   : 3'b100
}, '{
   // White & Black with Red Selection
	text          : 3'b000,
	bg            : 3'b111,
	selected      : 3'b001,
	selected_bg   : 3'b100
}, '{
	// Cyan BG
	text          : 3'b010,
	bg            : 3'b011,
	selected      : 3'b110,
	selected_bg   : 3'b101
},  '{
	// Tellow BG
	text          : 3'b000,
	bg            : 3'b110,
	selected      : 3'b100,
	selected_bg   : 3'b111
}};


// Constants

parameter reg [7:0] title_menu_charlines_offset_add = 3;
parameter reg [4:0] title_pixel_size_add = 4;
