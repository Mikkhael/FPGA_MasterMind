`include "strings.vh"


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


