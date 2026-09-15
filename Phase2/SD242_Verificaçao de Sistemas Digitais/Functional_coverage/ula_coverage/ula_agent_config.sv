
`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_agent_config extends uvm_object;
    `uvm_object_utils(ula_agent_config)

    bit is_active = UVM_ACTIVE;               // Habilita scoreboard por padrão

    function new(string name = "ula_env_config");
        super.new(name);
        //agent_cfg = ula_agent_config::type_id::create("agent_cfg");
    endfunction
endclass
