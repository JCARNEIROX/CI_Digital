set_db init_lib_search_path ../LIB/
set_db init_hdl_search_path ../RTL/
read_libs slow_vdd1v0_basicCells.lib
read_hdl counter.v
elaborate 
read_sdc ../constraints/constraints_top.sdc



set_db syn_generic_effort medium
syn_generic
set_db syn_map_effort medium
syn_map
set_db syn_opt_effort medium
syn_opt


syn_opt -incremental

write_hdl > outputs/counter_netlist.v
write_sdc > outputs/counter_sdc.sdc
write_sdf -nonegchecks -edges check_edge -timescale ns -recrem split  -setuphold split > outputs/delays.sdf


