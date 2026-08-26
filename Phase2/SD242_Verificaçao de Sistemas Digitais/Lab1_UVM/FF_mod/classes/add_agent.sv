class add_agent extends uvm_agent;
    `uvm_component_utils(add_agent)
    
    add_driver    driver;
    add_sequencer sequencer;
    add_monitor   monitor;

    uvm_analysis_port #(add_item) agent_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        driver = add_driver::type_id::create("driver", this);
        sequencer = add_sequencer::type_id::create("sequencer", this);
	    monitor = add_monitor::type_id::create("monitor", this);

        agent_ap = new("agent_ap",this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_ap = monitor.mon_ap;
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
    
endclass