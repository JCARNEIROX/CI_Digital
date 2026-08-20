package add_pkg;
    // Imports necessários
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    // Import dos arquivos das classes separados 
    // Lembrar de colocar no terminal ou Makefile:
    // xrun -sv +incdir+./classes add_pkg.sv tb_top.sv
    `include "add_item.sv"        
    `include "add_sequence.sv"    
    `include "add_sequencer.sv"   
    `include "add_driver.sv"      
    `include "add_monitor.sv"     
    `include "add_agent.sv"       
    `include "add_scboard.sv"     
    `include "add_env.sv"         
    `include "add_test.sv"        
  
endpackage : add_pkg
