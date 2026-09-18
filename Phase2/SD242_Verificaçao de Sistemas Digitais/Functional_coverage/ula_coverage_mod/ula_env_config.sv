
`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_env_config extends uvm_object;
    `uvm_object_utils(ula_env_config)

    bit has_scoreboard = 1'b1; // Habilita o scoreboard por padrão

    ula_agent_config agent_cfg; // Configuração do agente

    function new(string name = "ula_env_config");
        super.new(name);
        agent_cfg = ula_agent_config::type_id::create("agent_cfg");
    endfunction
endclass
