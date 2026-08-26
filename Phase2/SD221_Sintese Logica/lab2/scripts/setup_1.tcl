
#Pasta do RTL
set PROJECT_DIR /prj/ci/workarea/aluno3/ProjetosCarneiro/SD221/lab2/rtl
#Pasta da Biblioteca de timing
set LIB_DIR /pdk/gpdk045/gsclib045_svt_v4.7/gsclib045/timing
#Pasta da Biblioteca fisica
set LEF_DIR /pdk/gpdk045/gsclib045_svt_v4.7/gsclib045/lef
#Modulo principal (top)
set HDL_NAME "riscv_datapath"
#Arquivos HDL - verilog
set HDL_FILES riscv_datapath.v 

#Biblioteca pessimista
set WORST_LIST {slow_vdd1v0_basicCells.lib} 
#Biblioteca otimista
set BEST_LIST {fast_vdd1v2_basicCells.lib} 
#Biblioteca fisica
set LEF_LIST {gsclib045_tech.lef gsclib045_macro.lef}


#Set the search paths to the libraries and the HDL files
set_db hdl_search_path "${PROJECT_DIR}"

set_db lib_search_path "${LIB_DIR} ${LEF_DIR}"

set_db library "${WORST_LIST}"

read_hdl ${HDL_FILES}

elaborate ${HDL_NAME}

set_top_module ${HDL_NAME}

check_design -unresolved ${HDL_NAME}

read_sdc ${PROJECT_DIR}/constraints/${HDL_NAME}.sdc

syn_generic ${HDL_NAME}

syn_map ${HDL_NAME}

report_qor > ../reports/setup1/qor.rpt
report_power -unit W > ../reports/setup1/power.rpt
get_db hnet:i_data[0] .lp_computed_probability 
get_db hnet:d_we .lp_computed_probability 

# segunda parte:

# enable high-effort power optimization
#set_db design_power_effort high

# optimize for both leakage and dynamic power equally
#set_db opt_leakage_to_dynamic_ratio 0.5


#syn_generic ${HDL_NAME}

#syn_map ${HDL_NAME}

#report_qor
#report_power -unit W

#Tercera parte
#syn_opt

#report_qor
#report_power -unit W
#get_db hnet:i_data[0] .lp_computed_probability
#get_db hnet:d_we .lp_computed_probability

#report_timing > ${PROJECT_DIR}/${HDL_NAME}_timing.rpt

#write_hdl ${HDL_NAME} > ${PROJECT_DIR}/netlist/${HDL_NAME}.v

