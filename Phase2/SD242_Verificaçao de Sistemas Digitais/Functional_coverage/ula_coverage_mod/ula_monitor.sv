`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_monitor extends uvm_monitor;
    `uvm_component_utils(ula_monitor)

    virtual ula_if vif;
    uvm_analysis_port #(ula_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ula_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        ula_item trans;
        forever begin
            @(posedge vif.clk or negedge vif.rst_n);
            if (vif.rst_n !== 1'b1) begin
                continue;
            end

            // Antes do primeiro estimulo, as entradas ainda podem estar em X.
            if ($isunknown(vif.opr) || $isunknown(vif.a) || $isunknown(vif.b)) begin
                continue;
            end

            // Captura as mesmas entradas que o DUT usa nesta borda,
            // antes das atribuicoes nao bloqueantes do driver.
            trans = ula_item::type_id::create("trans");
            trans.opr     = vif.opr;
            trans.a       = vif.a;
            trans.b       = vif.b;

            // As saidas registradas ja estao estaveis na borda de descida.
            // Se houver reset durante a espera, descarta esta amostra.
            @(negedge vif.clk or negedge vif.rst_n);
            if (vif.rst_n !== 1'b1) begin
                continue;
            end
            trans.result  = vif.result;
            trans.carry_o = vif.carry_o;
            trans.zero    = vif.zero;
            item_collected_port.write(trans);
        end
    endtask

endclass
