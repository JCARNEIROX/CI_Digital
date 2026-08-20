
`include "uvm_macros.svh"
import uvm_pkg::*;

class add_item extends uvm_sequence_item;
    `uvm_object_utils(add_item)
    
    logic [31:0] data_in;
    logic [31:0] data_out;
    
    // Constraints para valores razoáveis
    constraint reasonable_values {
        data_in inside {[0:7'hFFFFFFFF]};
    }
    
    function new(string name = "add_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("data_in=0x%8h, data_out=0x%8h", 
                         data_in, data_out);
    endfunction
    
endclass

///////////////////////////////////////////////////////////


class add_sequence extends uvm_sequence #(add_item);
    `uvm_object_utils(add_sequence)
    
    rand int num_transactions = 10;
    
    function new(string name = "add_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        add_item trans_item;
        
        for (int i = 0; i < num_transactions; i++) begin
            trans_item = add_item::type_id::create($sformatf("add_item%0d", i));
            start_item(trans_item);
            if (!trans_item.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            finish_item(trans_item);
            `uvm_info("SEQ", $sformatf("Generated: %s", trans_item.convert2string()), UVM_LOW)
        end
    endtask
    
endclass

///////////////////////////////////////////////////////////

class add_sequencer extends uvm_sequencer #(add_item);
    `uvm_component_utils(add_sequencer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

///////////////////////////////////////////////////////////

class add_driver extends uvm_driver #(add_item);
    `uvm_component_utils(add_driver)
    
    virtual soma_if vif;
    add_item req;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soma_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_transaction(add_item i_trans);
        @(posedge vif.clk);
        vif.data_in <= i_trans.data_in;
        `uvm_info("DRV", $sformatf("Driving: %s", i_trans.convert2string()), UVM_MEDIUM)
        
        // Aguarda um ciclo para o DUT processar
        @(posedge vif.clk);
    endtask
    
endclass

///////////////////////////////////////////////////////////

class add_monitor extends uvm_monitor;
    `uvm_component_utils(add_monitor)
    
    virtual soma_if vif;

    add_item item_transact;
    
    uvm_analysis_port #(add_item) mon_ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction // new
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db #(virtual soma_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Interface nao encontrada!")
        end
        
        item_transact = add_item::type_id::create("item_transact");
    endfunction // build_phase
    
    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            item_transact.data_in	= vif.data_in;
            item_transact.data_out = vif.data_out;
            
            mon_ap.write(item_transact);

            `uvm_info(get_type_name(), item_transact.convert2string(), UVM_MEDIUM)
        end
    endtask // run_phase
    
endclass

///////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////

class add_scboard extends uvm_scoreboard;
    `uvm_component_utils(add_scboard)

    add_item item;
    
    // Analysis export implementation
    uvm_analysis_imp #(add_item, add_scboard) agent_aep;

    // Report Counters
    int compared_pass;
    int compared_fail;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        compared_pass = 0;
        compared_fail = 0;
    endfunction

    task run_phase(uvm_phase phase);
        // todo
    endtask

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_aep  = new("agent_aep" , this);
        item = add_item::type_id::create("item");

    endfunction

    function void write(add_item t);
        logic [7:0] expected_result;

        if (expected_result == t.result) begin
            compared_pass++;
            `uvm_info(get_type_name(), 
                      $sformatf("PASS: %s", t.convert2string()), 
                      UVM_MEDIUM)
        end else begin
            compared_fail++;
            `uvm_error(get_type_name(), 
                       $sformatf("FAIL: %s Expected result=0x%8h", 
                                 t.convert2string(), expected_result))
        end
    endfunction
endclass

///////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////
