
`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_agent_config extends uvm_object;
    `uvm_object_utils(ula_agent_config)

    bit is_active = UVM_ACTIVE; // Agente ativo por padrão

    function new(string name = "ula_agent_config");
        super.new(name);
    endfunction
endclass
