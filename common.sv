`include "generated_params.vh"

	
//// VGA Timings ////


////// 800 x 600 , 40 MHz pixel clock //////

//parameter logic [10:0] RES_H = 11'd800; // Color pulses
//parameter logic [10:0] RES_V = 11'd600; // Color lines
//parameter logic [10:0] BLK_HF = 11'd40;  // Blank Front Porch
//parameter logic [10:0] BLK_HT = 11'd128; // Blank Time
//parameter logic [10:0] BLK_HB = 11'd88;  // Blank Back Porch
//parameter logic [10:0] BLK_VF = 11'd1;   // Blank Front Porch
//parameter logic [10:0] BLK_VT = 11'd4;   // Blank Time
//parameter logic [10:0] BLK_VB = 11'd23;   // Blank Back Porch
//parameter logic HSYNC_POLARITY = 1;
//parameter logic VSYNC_POLARITY = 1;

////// 640 x 480 , 25,175 MHz pixel clock //////

parameter logic [10:0] RES_H = 11'd640; // Color pulses
parameter logic [10:0] RES_V = 11'd480; // Color lines
parameter logic [10:0] BLK_HF = 11'd16; // Blank Front Porch
parameter logic [10:0] BLK_HT = 11'd96; // Blank Time
parameter logic [10:0] BLK_HB = 11'd48; // Blank Back Porch
parameter logic [10:0] BLK_VF = 11'd10; // Blank Front Porch
parameter logic [10:0] BLK_VT = 11'd2;  // Blank Time
parameter logic [10:0] BLK_VB = 11'd33; // Blank Back Porch
parameter logic HSYNC_POLARITY = 0;
parameter logic VSYNC_POLARITY = 0;

///////////////////

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

typedef enum logic [3:0] {
	DIAL_NONE, DIAL_YOUWIN, DIAL_YOULOSE, DIAL_ENTERSECRET, 
	DIAL_HINTSGREEN, DIAL_HINTSYELLOW, DIAL_GUESSER, DIAL_SETTER} DIAL_STATE;

typedef enum logic [1:0] {GAMEMODE_RANDOM = 2'd0, GAMEMODE_CUSTOM = 2'd1, GAMEMODE_RIVAL = 2'd2} ENUM_GAME_MODE;
	
typedef struct {
	ENUM_GAME_MODE gamemode;
	reg [7:0] guessed_count;
	reg [7:0] scroll_offset;
	reg [PIN_COLOR_W-1:0] current_guess [0:max_pins_count-1];
	
	reg is_guess_entered;
	reg is_guess_uploading;
	reg is_guess_uploaded;
	
	DIAL_STATE dial_state;
	
	reg [PIN_POS_W-1:0] calculated_green;
	reg [PIN_POS_W-1:0] calculated_yellow;
	
	reg [PIN_POS_W-1:0] proposed_green;
	reg [PIN_POS_W-1:0] proposed_yellow;
	
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
	reg [10:0] board_tiles_subcols_available;
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
	
	
	reg [PIN_COLOR_W-1:0] board_tiles_dialog_width;
	reg [PIN_COLOR_W-1:0] board_tiles_dialog_height;
	reg [4:0] board_tiles_dialog_charlines_offset;
	reg [10:0] board_tiles_dialog_subcols_end;
	reg [4:0] board_tiles_dialog_charlines_end;
	reg [2:0] board_text_dialog_charlines_offset;
	reg [10:0] board_text_dialog_input_charcols_offset;
	// Palette
	st_GS_PALETTE palette;
} st_GS_RENDER;

parameter [4:0] STAR_POS_W = 5'd6;
parameter [4:0] STAR_STAGE_W = 5'd3;
parameter [4:0] STARS_X_W = 5'd4;
parameter [4:0] STARS_Y_W = 5'd4;
parameter [5:0] STAR_W = STAR_POS_W * 2'd2 + STAR_STAGE_W + 2'd3;

typedef struct packed {
	reg [STAR_POS_W-1:0] pos_x;
	reg [STAR_POS_W-1:0] pos_y;
	reg [STAR_STAGE_W-1:0] stage;
	reg [2:0] color;
} st_STAR;

typedef struct {
	reg [10:0] x;
	reg [10:0] y;
	reg [10:0] p;
	reg [10:0] r;
} st_FIREWORK;

typedef struct {
	GAME_STATE_NAME 	state_name;
	st_GS_NAVIGATION	navigation;
	st_GS_OPTIONS	 	options;
	st_GS_RENDER      render;
	st_GS_BOARD			board;
	st_FIREWORK			firework;
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

parameter reg [2:0] C_RED     = 3'b100;
parameter reg [2:0] C_GREEN   = 3'b010;
parameter reg [2:0] C_BLUE    = 3'b001;
parameter reg [2:0] C_CYAN    = 3'b011;
parameter reg [2:0] C_MAGENTA = 3'b101;
parameter reg [2:0] C_YELLOW  = 3'b110;
parameter reg [2:0] C_WHITE   = 3'b111;
parameter reg [2:0] C_BLACK   = 3'b000;

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
	// Yellow BG
	text          : 3'b000,
	bg            : 3'b110,
	selected      : 3'b100,
	selected_bg   : 3'b111
}};


//parameter reg [PIN_COLOR_W-1:0] PIN_COLOR_NONE = {PIN_COLOR_W{1'd1}};
parameter reg [1:0][2:0] pin_colorset [0:max_pin_colors-1] = '{
// Main 6
	{C_RED,     C_RED},
	{C_GREEN,   C_GREEN},
	{C_BLUE,    C_BLUE},
	{C_YELLOW,  C_YELLOW},
	{C_MAGENTA, C_MAGENTA},
	{C_CYAN,    C_CYAN},
// Mixed Red 5 (=11)
	{C_RED,     C_GREEN},
	{C_RED,     C_BLUE},
	{C_RED,     C_YELLOW},
	{C_RED,     C_MAGENTA},
	{C_RED,     C_CYAN},
// Mixed Green 4 (=15)
	{C_GREEN,   C_BLUE},
	{C_GREEN,   C_YELLOW},
	{C_GREEN,   C_MAGENTA},
	{C_GREEN,   C_CYAN},
// Mixed Blue 3 (=18)
	{C_BLUE,    C_YELLOW},
	{C_BLUE,    C_MAGENTA},
	{C_BLUE,    C_CYAN},
// Mixed Yellow 2 (=20)
	{C_YELLOW,  C_MAGENTA},
	{C_YELLOW,  C_CYAN},
// Mixed Magenta 21 (=21)
	{C_MAGENTA, C_CYAN}
};

//parameter reg [23:0] hdmi_pin_colorset [0:max_pin_colors-1] = '{
//
//	24'hFF2222,
//	24'h22FF22,
//	24'h2222FF,
//	24'hFFFF22,
//	24'hFF22FF,
//	24'h22FFFF,
//	
//	24'hFF5555,
//	24'h55FF55,
//	24'h5555FF,
//	24'hFFFF55,
//	24'hFF55FF,
//	24'h55FFFF,
//	
//	24'hFFAAAA,
//	24'hAAFFAA,
//	24'hAAAAFF,
//	24'hFFFFAA,
//	24'hFFAAFF,
//	24'hAAFFFF,
//	
//	24'h222222,
//	24'h555555,
//	24'hAAAAAA
//};


// Constants

parameter reg [7:0] title_menu_charlines_offset_add = 3;
parameter reg [4:0] title_pixel_size_add = 4;
