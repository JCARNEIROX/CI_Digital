set_db init_lib_search_path ../LIB/
set_db init_hdl_search_path ./RTL/
read_libs slow_vdd1v0_basicCells.lib
read_hdl decisions.v
elaborate 

syn_generic
syn_map

gui_show


