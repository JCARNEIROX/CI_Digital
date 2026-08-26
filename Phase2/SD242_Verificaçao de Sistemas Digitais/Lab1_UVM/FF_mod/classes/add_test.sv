class add_test extends uvm_test;
    `uvm_component_utils(add_test)
    
    add_env env;
    add_sequence seq;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = add_env::type_id::create("env", this);
        seq = add_sequence::type_id::create("seq");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #100; // Tempo extra para finalizar
        phase.drop_objection(this);
    endtask
    
endclass