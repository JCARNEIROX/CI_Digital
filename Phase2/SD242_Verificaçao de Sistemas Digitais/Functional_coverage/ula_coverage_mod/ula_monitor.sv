class ula_monitor extends uvm_monitor;
    `uvm_component_utils(ula_monitor)
    
    virtual ula_if vif;
    uvm_analysis_port #(ula_item) item_collected_port;
    
    ula_item trans_collected;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ula_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set")
        end
        trans_collected = ula_item::type_id::create("trans_collected");
    endfunction
    
    task run_phase(uvm_phase phase);
        ula_item trans;
        forever begin
            @(posedge vif.clk or negedge vif.rst_n);
            if (!vif.rst_n) continue;
            trans = ula_item::type_id::create("trans");
            trans.opr     = vif.opr;
            trans.a       = vif.a;
            trans.b       = vif.b;
            trans.result  = vif.result;
            trans.carry_o = vif.carry_o;
            trans.zero    = vif.zero;
            item_collected_port.write(trans);
        end
    endtask
    
endclass
