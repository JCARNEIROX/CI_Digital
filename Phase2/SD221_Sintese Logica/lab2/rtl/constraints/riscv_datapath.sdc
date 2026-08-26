create_clock -name clock -period 5 [get_ports clk]
set_clock_uncertainty 1 [get_clocks clock]
set_clock_latency 1 [get_clocks clock]
set_ideal_net [get_nets clk]
set_ideal_net [get_nets rst]

