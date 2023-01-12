module BUZZER_CONTROLER (
	input wire clk,
	input wire [31:0] note_period,
	output wire out
);

	reg [31:0] note_counter = 0;
	assign out = note_counter < (note_period >> 1);

	always @(posedge clk) begin
		if(note_counter >= note_period) begin
			note_counter <= 0;
		end else begin
			note_counter <= note_counter + 1'd1;
		end
	end

endmodule

parameter NOTE_Pulse_Per_Sec = 1000000;
parameter [31:0] NOTE_E4  = NOTE_Pulse_Per_Sec/329.63;
parameter [31:0] NOTE_F4  = NOTE_Pulse_Per_Sec/349.23;
parameter [31:0] NOTE_Fs4 = NOTE_Pulse_Per_Sec/369.99;
parameter [31:0] NOTE_A4  = NOTE_Pulse_Per_Sec/440;
parameter [31:0] NOTE_As4 = NOTE_Pulse_Per_Sec/466.16;
parameter [31:0] NOTE_C5  = NOTE_Pulse_Per_Sec/523.25;
parameter [31:0] NOTE_A6  = NOTE_Pulse_Per_Sec/1760;


parameter [31:0] NOTE_A5 = NOTE_Pulse_Per_Sec/880;

typedef struct packed {
	reg [31:0] period;
	reg [31:0] duration;
} st_NOTE;

parameter TUNE_Victory_LEN = 3'd4;
parameter st_NOTE TUNE_Victory_NOTES [0:TUNE_Victory_LEN-1] = '{
	'{NOTE_A4, NOTE_Pulse_Per_Sec / 4},
	'{NOTE_F4, NOTE_Pulse_Per_Sec / 4},
	'{NOTE_A4, NOTE_Pulse_Per_Sec / 4},
	'{NOTE_C5, NOTE_Pulse_Per_Sec}
};

parameter TUNE_GameOver_LEN = 3'd4;
parameter st_NOTE TUNE_GameOver_NOTES [0:TUNE_GameOver_LEN-1] = '{
	'{NOTE_Fs4, NOTE_Pulse_Per_Sec / 4},
	'{NOTE_As4, NOTE_Pulse_Per_Sec / 4},
	'{NOTE_Fs4, NOTE_Pulse_Per_Sec / 4},
	'{NOTE_E4,  NOTE_Pulse_Per_Sec}
};

typedef enum logic [1:0] {TUNE_None, TUNE_BTN, TUNE_Victory, TUNE_GameOver} TUNE_ID;

module MUSIC_PLAYER (
	input clk,
	input new_tune,
	input TUNE_ID tune_id,
	output wire buzzer_out
);

	reg [31:0] current_note_period   = 0;
	reg [31:0] current_note_duration = 0;
	BUZZER_CONTROLER buzzer_controler(clk, current_note_period, buzzer_out);
	
	reg [31:0] duration_counter = 0;
	reg [2:0] note_counter = 0;
	TUNE_ID current_tune = TUNE_None;
	
	always @(posedge clk) begin
		if(new_tune) begin
			duration_counter  <= 0;
			note_counter 		<= 0;
			current_tune 	   <= tune_id;
			current_note_period   <= 0;
			current_note_duration <= 0;
		end else begin
		
			if(duration_counter >= current_note_duration) begin
				duration_counter <= 0;
				case(current_tune)
					TUNE_None: begin
						current_note_period   <= 0;
						current_note_duration <= 0;
					end
					TUNE_BTN: begin
						if(note_counter < 3'd1) begin
							current_note_period   <= NOTE_A6;
							current_note_duration <= NOTE_Pulse_Per_Sec / 20;
							note_counter <= note_counter + 1'd1;
						end else begin
							current_note_period   <= 0;
							current_note_duration <= 0;
							current_tune <= TUNE_None;
						end
					end
					TUNE_Victory: begin
						if(note_counter < TUNE_Victory_LEN) begin
							current_note_period   <= TUNE_Victory_NOTES[note_counter].period;
							current_note_duration <= TUNE_Victory_NOTES[note_counter].duration;
							note_counter <= note_counter + 1'd1;
						end else begin
							current_note_period   <= 0;
							current_note_duration <= 0;
							current_tune <= TUNE_None;
						end
					end
					TUNE_GameOver: begin
						if(note_counter < TUNE_GameOver_LEN) begin
							current_note_period   <= TUNE_GameOver_NOTES[note_counter].period;
							current_note_duration <= TUNE_GameOver_NOTES[note_counter].duration;
							note_counter <= note_counter + 1'd1;
						end else begin
							current_note_period   <= 0;
							current_note_duration <= 0;
							current_tune <= TUNE_None;
						end
					end
				endcase
			end else begin
				duration_counter <= duration_counter + 1'd1;
			end
		end
	end
	
endmodule
