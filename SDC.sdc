create_clock -name main_clk -period 100.000 [get_ports CLK0]
derive_pll_clocks
derive_clock_uncertainty

set_false_path -from [get_ports S?]

set_false_path -to [get_ports VGA_*]
set_false_path -to [get_ports SEG_*]
set_false_path -to [get_ports LED?]
set_false_path -to [get_ports DS?]