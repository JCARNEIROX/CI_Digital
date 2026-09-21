
#Pasta do RTL
set PROJECT_DIR /prj/ci/workarea/aluno3/ProjetosCarneiro/CI_Digital/Phase2/SD232_Analise_Estatica_Timing/RISCV/MC
set HDL_DIR ${PROJECT_DIR}/rtl
#Pasta da Biblioteca de timing
set LIB_DIR /pdk/gpdk045/gsclib045_svt_v4.7/gsclib045/timing
#Pasta da Biblioteca fisica
set LEF_DIR /pdk/gpdk045/gsclib045_svt_v4.7/gsclib045/lef
#Modulo principal (top)
set HDL_NAME "datapath_mc"
#Arquivos HDL - verilog
set HDL_FILES "adder.v control.v extendImm.v mux4.v regfile.v alu.v mux2.v pc.v datapath_mc.v"


#Biblioteca pessimista
set WORST_LIST {slow_vdd1v0_basicCells.lib} 
#Biblioteca otimista
set BEST_LIST {fast_vdd1v2_basicCells.lib} 
#Biblioteca fisica
set LEF_LIST {gsclib045_tech.lef gsclib045_macro.lef}

##preserve hierarchy
set_db auto_ungroup none

#Set the search paths to the libraries and the HDL files
set_db hdl_search_path "${HDL_DIR}"

#set_db lib_search_path "${LIB_DIR} ${LEF_DIR}"
set_db lib_search_path "${LIB_DIR}"

set_db library "${WORST_LIST}"

read_hdl -sv ${HDL_FILES}

elaborate ${HDL_NAME}

set_top_module ${HDL_NAME}

#check_design -unresolved ${HDL_NAME}

read_sdc ${PROJECT_DIR}/constraints/${HDL_NAME}.sdc

syn_generic ${HDL_NAME}

syn_map ${HDL_NAME} 

report_timing > ${PROJECT_DIR}/reports/${HDL_NAME}_timing.rpt
report_area > ${PROJECT_DIR}/reports/${HDL_NAME}_area.rpt
report_power > ${PROJECT_DIR}/reports/${HDL_NAME}_power.rpt

write_hdl ${HDL_NAME} > ${PROJECT_DIR}/netlist/${HDL_NAME}.v

