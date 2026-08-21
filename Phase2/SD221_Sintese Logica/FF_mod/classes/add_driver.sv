class add_driver extends uvm_driver #(add_item);
    `uvm_component_utils(add_driver)
    
    virtual register_if vif;
    add_item req;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual register_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        // esperar o rest ser desativado pelo tb_top
        wait(vif.rst_n == 1'b1);
        
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_transaction(add_item i_trans);
        @(posedge vif.clk);
        vif.data_in <= i_trans.data_in;
        vif.enable <= i_trans.enable;
        `uvm_info("DRV", $sformatf("Driving: %s", i_trans.convert2string()), UVM_MEDIUM)
        
        // Aguarda um ciclo para o DUT processar
        @(posedge vif.clk);
    endtask
    
endclass