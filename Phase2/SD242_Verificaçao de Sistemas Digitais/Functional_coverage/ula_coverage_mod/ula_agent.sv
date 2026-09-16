class ula_agent extends uvm_agent;
    `uvm_component_utils(ula_agent)
    
    ula_driver    driver;
    ula_sequencer sequencer;
    ula_monitor   monitor;

    ula_agent_config cfg;
    uvm_analysis_port #(ula_item) agent_ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        agent_ap = new("agent_ap", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Obtém a configuração do agente
        if (!uvm_config_db #(ula_agent_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("AGENT_NO_CFG", "ula_agent_config not found for agent")

	if (cfg.is_active == UVM_ACTIVE) begin
           driver = ula_driver::type_id::create("driver", this);
           sequencer = ula_sequencer::type_id::create("sequencer", this);
	end

        monitor = ula_monitor::type_id::create("monitor",this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
	if (cfg.is_active == UVM_ACTIVE) begin
           driver.seq_item_port.connect(sequencer.seq_item_export);
	end
        monitor.item_collected_port.connect(agent_ap);
    endfunction
    
endclass
