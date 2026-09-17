`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_test extends uvm_test;
    `uvm_component_utils(ula_test)
    
    ula_env env;
    ula_sequence seq;
    ula_env_config env_cfg;

    int clock_delay;
    int requested_transactions;
    int requested_corners;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Cria e configura a configuração do ambiente
        env_cfg = ula_env_config::type_id::create("env_cfg");
        
        // Exemplo 1: Agente ATIVO com scoreboard HABILITADO
        env_cfg.agent_cfg.is_active = UVM_ACTIVE;
        env_cfg.has_scoreboard      = 1'b1;

	if ($value$plusargs("CLOCK_DELAY=%d", clock_delay))
            `uvm_info(get_name(), $sformatf("Usando %0d CLOCK_DELAY", clock_delay), UVM_LOW)
        // Exemplo 2: Agente PASSIVO com scoreboard DESABILITADO
        // env_cfg.agent_cfg.is_active = UVM_PASSIVE;
        // env_cfg.has_scoreboard      = 1'b0;

        // Armazena no config_db para que o ambiente possa recuperar
        uvm_config_db #(ula_env_config)::set(this, "env", "cfg", env_cfg);

        env = ula_env::type_id::create("env", this);
        seq = ula_sequence::type_id::create("seq");
        if ($value$plusargs("NUM_TRANSACTIONS=%d", requested_transactions)) begin
            if (requested_transactions < 0)
                `uvm_fatal("TEST_CFG", "NUM_TRANSACTIONS deve ser >= 0")
            seq.num_transactions = requested_transactions;
        end
        if ($value$plusargs("RUN_CORNERS=%d", requested_corners)) begin
            if (!(requested_corners inside {0, 1}))
                `uvm_fatal("TEST_CFG", "RUN_CORNERS deve ser 0 ou 1")
            seq.run_corners = requested_corners;
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #100; // Tempo extra para finalizar
        phase.drop_objection(this);
    endtask
    
endclass
