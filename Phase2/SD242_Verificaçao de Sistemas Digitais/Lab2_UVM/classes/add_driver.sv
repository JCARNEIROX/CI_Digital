class add_driver extends uvm_driver #(add_item);
    `uvm_component_utils(add_driver)
    
    dut_vif_t vif;
    add_item req;
    add_agent_config cfg;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(dut_vif_t)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set")
        end
        if (!uvm_config_db#(add_agent_config)::get(this, "", "cfg", cfg))
            cfg = add_agent_config::type_id::create("cfg");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        // Wait until the HDL wrapper completes reset.
        wait(vif.rst_n == 1'b1);
        
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_transaction(add_item i_trans);
        if (cfg.driver_uses_clocking_block) begin
            @(vif.tb_cb);
            vif.tb_cb.w_en    <= i_trans.w_en;
            vif.tb_cb.r_en    <= i_trans.r_en;
            vif.tb_cb.addr    <= i_trans.addr;
            vif.tb_cb.data_in <= i_trans.data_in;
        end else begin
            @(negedge vif.clk);
            vif.w_en    <= i_trans.w_en;
            vif.r_en    <= i_trans.r_en;
            vif.addr    <= i_trans.addr;
            vif.data_in <= i_trans.data_in;
        end
        `uvm_info("DRV", $sformatf("Driving: %s", i_trans.convert2string()), UVM_MEDIUM)
    endtask
    
endclass
