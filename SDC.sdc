create_clock -name main_clk -period 100.000 [get_ports CLK0]
derive_pll_clocks

create_generated_clock -name vga_from_tmds_clk -source [get_pins {main_pll|altpll_component|auto_generated|pll1|clk[3]}] -divide_by 10 [get_registers {CLK_DIV_BY_10:tmds_div|out}]

derive_clock_uncertainty



set_false_path -from [get_ports BTN_*]
#set_false_path -from [get_ports S?]

set_false_path -to [get_ports VGA_*]
set_false_path -to [get_ports LED?]
set_false_path -to [get_ports HDMI_*]
#set_false_path -to [get_ports SEG_*]
#set_false_path -to [get_ports DS?]