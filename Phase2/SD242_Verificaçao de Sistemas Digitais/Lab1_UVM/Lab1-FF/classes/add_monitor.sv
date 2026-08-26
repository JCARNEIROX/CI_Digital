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
            item_transact.a	= vif.a;
            item_transact.b 	= vif.b;
	    item_transact.result = vif.result;
	    item_transact.carry_o = vif.carry_o;
            
            mon_ap.write(item_transact);

            `uvm_info(get_type_name(), item_transact.convert2string(), UVM_MEDIUM)
        end
    endtask // run_phase
    
endclass