###############################################################
## Library setup
###############################################################

set_db init_lib_search_path ../LIB/
set_db init_hdl_search_path ../RTL/
read_libs slow_vdd1v0_basicCells.lib

####################################################################
## Load Design
####################################################################

read_hdl x3_curto.v
elaborate
check_design -unresolved

####################################################################
## Constraints Setup
####################################################################

read_sdc ../constraints/constraints_top.sdc

####################################################################################################
## Synthesis Effort
####################################################################################################

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

####################################################################################################
## Synthesizing to generic 
####################################################################################################

syn_generic

####################################################################################################
## Synthesizing to gates
####################################################################################################

syn_map

#######################################################################################################
## Optimize Netlist
#######################################################################################################

syn_opt

#################################
### Reports
#################################

report_timing > reports/report_timing.rpt
report_power  > reports/report_power.rpt
report_area   > reports/report_area.rpt
report_qor    > reports/report_qor.rpt

#################################
### Outputs
#################################
write_db x3_curto -to_file design.db
write_hdl > outputs/x3_curto_netlist.v
write_sdc > outputs/x3_curto_sdc.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge  -setuphold split > outputs/delays.sdf
