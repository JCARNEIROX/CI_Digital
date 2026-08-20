class add_env extends uvm_env;
    `uvm_component_utils(add_env)
    
    add_agent   agent;
    add_scboard scboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent   = add_agent::type_id::create("agent", this);
	scboard = add_scboard::type_id::create("scboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	agent.agent_ap.connect(scboard.agent_aep);
    endfunction
    
endclass