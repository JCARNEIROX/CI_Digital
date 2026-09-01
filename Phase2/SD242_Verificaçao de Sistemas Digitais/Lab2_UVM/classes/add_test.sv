class add_test extends uvm_test;
    `uvm_component_utils(add_test)
    
    add_env env;
    add_sequence seq;
    add_test_config cfg;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = add_test_config::type_id::create("cfg");
        cfg.apply_plusargs();
        uvm_config_db#(add_env_config)::set(this, "env", "cfg", cfg.env_cfg);
        uvm_config_db#(add_agent_config)::set(this, "env.agent", "cfg", cfg.env_cfg.agent_cfg);
        env = add_env::type_id::create("env", this);
        seq = add_sequence::type_id::create("seq");
        seq.num_transactions = cfg.num_transactions;
        seq.read_latency = cfg.env_cfg.read_latency;
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        if (cfg.env_cfg.agent_cfg.is_active == UVM_ACTIVE) begin
            seq.start(env.agent.sequencer);
            #100; // Time for the last delayed read response.
        end else begin
            `uvm_info(get_type_name(), "Passive agent selected: no sequence is started", UVM_LOW)
        end
        phase.drop_objection(this);
    endtask
    
endclass
