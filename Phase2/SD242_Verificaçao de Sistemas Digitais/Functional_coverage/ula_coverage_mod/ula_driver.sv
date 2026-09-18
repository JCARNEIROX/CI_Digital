class ula_driver extends uvm_driver #(ula_item);
    `uvm_component_utils(ula_driver)

    virtual ula_if vif;
    ula_item req;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ula_if)::get(this, "", "vif", vif)) begin
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
    
    virtual task drive_transaction(ula_item i_trans);
        // Só aplica entradas em uma borda com reset desativado e conhecido.
        do begin
            @(posedge vif.clk);
        end while (vif.rst_n !== 1'b1);
        vif.a <= i_trans.a;
        vif.b <= i_trans.b;
        vif.opr <= i_trans.opr;
        `uvm_info("DRV", $sformatf("Driving: %s", i_trans.convert2string()), UVM_HIGH)

        // Aguarda um ciclo para o DUT processar
        @(posedge vif.clk);
    endtask

endclass

