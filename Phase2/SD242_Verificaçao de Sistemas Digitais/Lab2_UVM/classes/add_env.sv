class add_env extends uvm_env;
    `uvm_component_utils(add_env)
    
    add_agent   agent;
    add_scboard scboard;
    add_coverage coverage;
    add_env_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(add_env_config)::get(this, "", "cfg", cfg))
            cfg = add_env_config::type_id::create("cfg");

        uvm_config_db#(add_agent_config)::set(this, "agent", "cfg", cfg.agent_cfg);
        uvm_config_db#(add_env_config)::set(this, "scboard", "cfg", cfg);
        agent   = add_agent::type_id::create("agent", this);
        if (cfg.has_scoreboard)
            scboard = add_scboard::type_id::create("scboard", this);
        if (cfg.has_coverage)
            coverage = add_coverage::type_id::create("coverage", this);
        `uvm_info(get_type_name(),
                  $sformatf("scoreboard=%0b coverage=%0b sync=%0b latency=%0d",
                            cfg.has_scoreboard, cfg.has_coverage,
                            cfg.synchronize_components, cfg.read_latency), UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (scboard != null)
            agent.agent_ap.connect(scboard.agent_aep);
        if (coverage != null)
            agent.agent_ap.connect(coverage.analysis_export);
    endfunction
    
endclass
