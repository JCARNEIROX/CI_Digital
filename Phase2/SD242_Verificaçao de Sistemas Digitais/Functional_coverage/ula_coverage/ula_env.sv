
class ula_env extends uvm_env;
    `uvm_component_utils(ula_env)
    
    ula_agent      agent;
    ula_scoreboard sb;
    ula_coverage   coverage;

    ula_env_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Obtém a configuração do ambiente
        if (!uvm_config_db #(ula_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("ENV_NO_CFG", "ula_env_config not found for env")

        // Passa a configuração do agente para o agente via config_db
        uvm_config_db #(ula_agent_config)::set(this, "agent", "cfg", cfg.agent_cfg);

        agent = ula_agent::type_id::create("agent", this);

        // Cria o scoreboard somente se habilitado
        if (cfg.has_scoreboard) begin
            sb = ula_scoreboard::type_id::create("sb", this);
        end

       coverage   = ula_coverage::type_id::create("coverage", this);
 
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect monitor's analysis port to scoreboard's import

        if (cfg.has_scoreboard) begin
            agent.agent_ap.connect(sb.analysis_imp);
        end

        agent.agent_ap.connect(coverage.analysis_export);

    endfunction
endclass
