module flash_TEST(

input wire CLK0,

input wire BTN_RAW_LEFT ,
input wire BTN_RAW_DOWN ,
input wire BTN_RAW_RIGHT,
input wire BTN_RAW_UP   ,
input wire BTN_RAW_ENTER,
input wire BTN_RAW_DEBUG,

output wire LED0,
output wire LED1,
output wire LED2,
output wire LED3,

output reg VGA_R = 0,
output reg VGA_G = 0,
output reg VGA_B = 0,
output reg VGA_HSYNC = 0,
output reg VGA_VSYNC = 0
);

wire pll_areset = 0;

wire CLK_PLL;
wire CLK_PLL2;
wire CLK_VGA;
PLL main_pll(pll_areset, CLK0, CLK_PLL, CLK_PLL2, CLK_VGA);

wire BTN_DEB_LEFT  , BTN_EDGE_LEFT;
wire BTN_DEB_DOWN  , BTN_EDGE_DOWN;
wire BTN_DEB_RIGHT , BTN_EDGE_RIGHT;
wire BTN_DEB_UP    , BTN_EDGE_UP;
wire BTN_DEB_ENTER , BTN_EDGE_ENTER;
wire BTN_DEB_DEBUG , BTN_EDGE_DEBUG;

wire BTN_RAW_DEBUG_NEGATED = ~BTN_RAW_DEBUG;

DEBOUNCE deb_left (CLK_PLL, BTN_RAW_LEFT , 	BTN_DEB_LEFT );
DEBOUNCE deb_down (CLK_PLL, BTN_RAW_DOWN , 	BTN_DEB_DOWN );
DEBOUNCE deb_right(CLK_PLL, BTN_RAW_RIGHT, 	BTN_DEB_RIGHT);
DEBOUNCE deb_ip   (CLK_PLL, BTN_RAW_UP   , 	BTN_DEB_UP   );
DEBOUNCE deb_enter(CLK_PLL, BTN_RAW_ENTER, 	BTN_DEB_ENTER);
DEBOUNCE deb_debug(CLK_PLL, BTN_RAW_DEBUG_NEGATED, 	BTN_DEB_DEBUG);
EDGE_NEG edge_left (CLK_PLL, BTN_DEB_LEFT ,  BTN_EDGE_LEFT );
EDGE_NEG edge_down (CLK_PLL, BTN_DEB_DOWN ,  BTN_EDGE_DOWN );
EDGE_NEG edge_right(CLK_PLL, BTN_DEB_RIGHT,  BTN_EDGE_RIGHT);
EDGE_NEG edge_ip   (CLK_PLL, BTN_DEB_UP   ,  BTN_EDGE_UP   );
EDGE_NEG edge_enter(CLK_PLL, BTN_DEB_ENTER,  BTN_EDGE_ENTER);
EDGE_NEG edge_debug(CLK_PLL, BTN_DEB_DEBUG,  BTN_EDGE_DEBUG);


reg [3:0] LEDS = 0;
assign {LED3, LED2, LED1, LED0} = ~LEDS;

// CLK_f = 500 kHz
// CLK_T = 1/500000 s
// 1s ~ (1.048s) = 2^19 * CLK_T
reg [31:0] time_counter = 0;


wire        avmm_clock = CLK_PLL;    
reg         avmm_reset_n  = 0;              
               
reg         avmm_csr_addr = 1;           
reg         avmm_csr_read = 0;           
reg  [31:0] avmm_csr_writedata = 0;      
reg         avmm_csr_write = 0;          
wire [31:0] avmm_csr_readdata;       

reg  [12:0] avmm_data_addr = 0;          
reg         avmm_data_read = 0;          
reg  [31:0] avmm_data_writedata = 0;     
reg         avmm_data_write = 0;         
wire [31:0] avmm_data_readdata;      
wire        avmm_data_waitrequest;   
wire        avmm_data_readdatavalid; 
reg  [1:0]  avmm_data_burstcount = 1;       

flash flash1(
	avmm_clock,                  
	avmm_csr_addr,          
	avmm_csr_read,          
	avmm_csr_writedata,     
	avmm_csr_write,         
	avmm_csr_readdata,      
	avmm_data_addr,         
	avmm_data_read,         
	avmm_data_writedata,    
	avmm_data_write,        
	avmm_data_readdata,     
	avmm_data_waitrequest,  
	avmm_data_readdatavalid,
	avmm_data_burstcount,   
	avmm_reset_n 
);


reg [3:0] stage = 0;


reg [31:0] last_read = 8'b11110111;

reg [31:0] disp = 0;
reg [10:0] disp_offset = 0;
reg read_delay = 0;
reg wait_for_read = 0;

always @(posedge CLK_PLL) begin
	
	
	case(stage)
		0: begin // Read Status Register
			
			if(BTN_EDGE_UP && !wait_for_read) begin
				
				wait_for_read = 1;
				avmm_csr_read = 1;
				avmm_csr_addr = 0;
				
			end else if(wait_for_read) begin
				
				wait_for_read = 0;
				avmm_csr_read = 0;
				last_read = avmm_csr_readdata;
				
			end
			
		end
		1: begin // Read Control Register
			
			if(BTN_DEB_DOWN && !wait_for_read) begin
				
				avmm_csr_write = 1;
				avmm_csr_writedata = last_read ^ (32'b1 << 23);
				avmm_csr_addr = 1;
				
			end else begin
				
				avmm_csr_write = 0;
				
			end
			
			if(BTN_EDGE_UP && !wait_for_read) begin
				
				wait_for_read = 1;
				avmm_csr_read = 1;
				avmm_csr_addr = 1;
				
			end
			
			if(wait_for_read) begin
				
				wait_for_read = 0;
				avmm_csr_read = 0;
				last_read = avmm_csr_readdata;
				
			end
			
		end
	endcase

	
	if(BTN_EDGE_ENTER && !wait_for_read) begin
		last_read = stage;
		if(++stage >= 2) begin
			stage = 0;
		end
	end
	
	if(BTN_EDGE_LEFT && !wait_for_read) begin
		if(++disp_offset >= (32 - 4)) begin
			disp_offset = (31 - 4);
		end
	end
	if(BTN_EDGE_RIGHT && !wait_for_read) begin
		if(--disp_offset >= (32 - 4)) begin
			disp_offset = 0;
		end
	end
	
	disp = last_read >> disp_offset;
	LEDS = disp[3:0];
	
	time_counter += 1'd1;
end

endmodule