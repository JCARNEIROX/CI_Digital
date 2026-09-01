class add_monitor extends uvm_monitor;
    `uvm_component_utils(add_monitor)
    
    dut_vif_t vif;
    
    uvm_analysis_port #(add_item) mon_ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction // new
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db #(dut_vif_t)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Interface nao encontrada!")
        end
        
    endfunction // build_phase
    
    task run_phase(uvm_phase phase);
        add_item item_transact;

        forever begin
            @(posedge vif.clk);
            #1ps;
            if (!vif.rst_n)
                continue;

            // Create a fresh object because analysis subscribers retain it.
            item_transact = add_item::type_id::create("item_transact");
            item_transact.w_en     = vif.w_en;
            item_transact.r_en     = vif.r_en;
            item_transact.addr     = vif.addr;
            item_transact.data_in  = vif.data_in;
            item_transact.data_out = vif.data_out;
            mon_ap.write(item_transact);

            `uvm_info(get_type_name(), item_transact.convert2string(), UVM_MEDIUM)
        end
    endtask // run_phase
    
endclass
