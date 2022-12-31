

module RNG_tb();

wire [31:0] rng_out;

reg en = 0;
reg clk = 0;
reg [31:0] seed = 0;

int fd;

int i = 0;
int last_proc = -1;

always #1 clk = ~clk;

parameter initial_seed = 8'b10010001;
parameter tests = 100000;

reg [1:0] state = 0;

RNG rng(clk, en, seed, rng_out);

initial begin
	fd = $fopen("random_numbers.txt", "w");
end

always @(posedge clk) begin
	case(state)
		0: begin seed = initial_seed; state = 1; $write("BEGIN\n"); end
		1: begin seed = 0;            state = 2; end
		2: begin en = 1;              state = 3; end
		3: begin
			if(i >= tests) begin
				$write("STOP\n");
				$fclose(fd);
				$stop;
			end
			if(last_proc != 100 * i / tests) begin
				last_proc = 100 * i / tests;
				$write("%d%%\n", last_proc);
			end
			$fwrite(fd, "%d\n", rng_out);
			i += 1'd1;
		end
	endcase
end

endmodule