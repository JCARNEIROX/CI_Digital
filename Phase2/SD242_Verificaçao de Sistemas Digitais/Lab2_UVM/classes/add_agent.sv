class add_agent extends uvm_agent;
    `uvm_component_utils(add_agent)
    
    add_driver    driver;
    add_sequencer sequencer;
    add_monitor   monitor;
    add_agent_config cfg;

    uvm_analysis_port #(add_item) agent_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(add_agent_config)::get(this, "", "cfg", cfg))
            cfg = add_agent_config::type_id::create("cfg");

        is_active = cfg.is_active;
        uvm_config_db#(add_agent_config)::set(this, "driver", "cfg", cfg);
        uvm_config_db#(add_agent_config)::set(this, "monitor", "cfg", cfg);
        if (cfg.monitor_collects_transactions)
            monitor = add_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            driver = add_driver::type_id::create("driver", this);
            sequencer = add_sequencer::type_id::create("sequencer", this);
        end

        agent_ap = new("agent_ap",this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (monitor != null)
            monitor.mon_ap.connect(agent_ap);
        if (is_active == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
    
endclass
