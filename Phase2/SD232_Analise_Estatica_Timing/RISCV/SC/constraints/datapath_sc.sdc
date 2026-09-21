create_clock -name clock -period 20 [get_ports clk]
set_clock_uncertainty 1 [get_clocks clock]
set_input_delay 1 -clock clock [all_inputs]
set_ideal_net [get_nets clk]
set_ideal_net [get_nets rst]

