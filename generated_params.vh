parameter ADDR_W = 4'd9;
parameter FONT_H = 3'd5;
parameter FONT_W = 3'd4;
parameter FONT_CHARS = 6'd39;
parameter FONT_LINEOFF = 7'd64;
parameter FONT_LINESHIFT = 3'd6;
parameter CHAR_0 = 1'd0;
parameter CHAR_1 = 1'd1;
parameter CHAR_2 = 2'd2;
parameter CHAR_3 = 2'd3;
parameter CHAR_4 = 3'd4;
parameter CHAR_5 = 3'd5;
parameter CHAR_6 = 3'd6;
parameter CHAR_7 = 3'd7;
parameter CHAR_8 = 4'd8;
parameter CHAR_9 = 4'd9;
parameter CHAR_A = 4'd10;
parameter CHAR_B = 4'd11;
parameter CHAR_C = 4'd12;
parameter CHAR_D = 4'd13;
parameter CHAR_E = 4'd14;
parameter CHAR_F = 4'd15;
parameter CHAR_G = 5'd16;
parameter CHAR_H = 5'd17;
parameter CHAR_I = 5'd18;
parameter CHAR_J = 5'd19;
parameter CHAR_K = 5'd20;
parameter CHAR_L = 5'd21;
parameter CHAR_M = 5'd22;
parameter CHAR_N = 5'd23;
parameter CHAR_O = 5'd24;
parameter CHAR_P = 5'd25;
parameter CHAR_Q = 5'd26;
parameter CHAR_R = 5'd27;
parameter CHAR_S = 5'd28;
parameter CHAR_T = 5'd29;
parameter CHAR_U = 5'd30;
parameter CHAR_V = 5'd31;
parameter CHAR_W = 6'd32;
parameter CHAR_X = 6'd33;
parameter CHAR_Y = 6'd34;
parameter CHAR_Z = 6'd35;
parameter CHAR_  = 6'd36;
parameter CHAR_ArrowR = 6'd37;
parameter CHAR_ArrowL = 6'd38;
parameter LSPRITE_MM_LEN = 2'd2;
parameter LSPRITE_Mind_LEN = 3'd4;
parameter LSPRITE_MM = 6'd39;
parameter LSPRITE_Mind = 6'd41;
parameter STR_TITLE_LEN = 4'd11;
parameter STR_OPTIONS_LEN = 3'd7;
parameter STR_HIGHSCORES_LEN = 4'd10;
parameter STR_BACK_LEN = 4'd10;
parameter STR_PIXELWIDTH_LEN = 4'd12;
parameter STR_PIXELHEIGHT_LEN = 4'd12;
parameter STR_PALETTE_LEN = 3'd7;
parameter logic [8:0] STR_TITLE [11] = '{39,40,10,28,29,14,27,41,42,43,44};
parameter logic [8:0] STR_OPTIONS [7] = '{24,25,29,18,24,23,28};
parameter logic [8:0] STR_HIGHSCORES [10] = '{17,18,16,17,28,12,24,27,14,28};
parameter logic [8:0] STR_BACK [10] = '{38,38,36,11,10,12,20,36,38,38};
parameter logic [8:0] STR_PIXELWIDTH [12] = '{25,18,33,14,21,36,32,18,13,29,17,36};
parameter logic [8:0] STR_PIXELHEIGHT [12] = '{25,18,33,14,21,36,17,14,18,16,17,29};
parameter logic [8:0] STR_PALETTE [7] = '{25,10,21,14,29,29,14};
