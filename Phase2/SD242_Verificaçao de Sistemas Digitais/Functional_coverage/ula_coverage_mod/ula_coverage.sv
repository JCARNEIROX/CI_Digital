`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_coverage extends uvm_subscriber #(ula_item);
    `uvm_component_utils(ula_coverage)
    ula_item item;

    // Covergroup para operações e resultados
    covergroup cg_ula;
        // Cobertura das operações
        opr_cp : coverpoint item.opr {
            bins add = {ula_item::OP_ADD};
            bins sub = {ula_item::OP_SUB};
            bins mul = {ula_item::OP_MUL};
            bins div = {ula_item::OP_DIV};
            bins and_op = {ula_item::OP_AND};
            bins or_op  = {ula_item::OP_OR};
            bins not_op = {ula_item::OP_NOT};
        }

        // Cobertura dos operandos
        a_val : coverpoint item.a {
            bins low  = {[0:100]};
            bins mid  = {[1000:2000]};
            bins high = {[32'hFFFFFF00:32'hFFFFFFFF]};
        }

        b_val : coverpoint item.b {
            bins low  = {[0:100]};
            bins mid  = {[1000:2000]};
            bins high = {[32'hFFFFFF00:32'hFFFFFFFF]};
        }

        // Cobertura dos resultados
        result_cp : coverpoint item.result {
            bins zero     = {0};
            bins non_zero = default;
        }

        // Cobertura do carry/overflow
        carry_cp : coverpoint item.carry_o {
            bins no_carry = {0};
            bins carry    = {1};
        }

        // Cobertura do sinal zero
        zero_cp : coverpoint item.zero {
            bins is_zero    = {1};
            bins not_zero   = {0};
        }

        // Cross importante: operação × carry
        opr_carry_cross : cross opr_cp, carry_cp;

        // Cross operação × zero
        opr_zero_cross : cross opr_cp, zero_cp;
    endgroup

    // Construtor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_ula = new();
        item   = new("item");
    endfunction

    // Método write chamado pelo analysis port
    function void write(ula_item t);
        if(t == null) return;
        item = t;
        cg_ula.sample();
    endfunction


    virtual function void report_phase(uvm_phase phase);
        real coverage = cg_ula.get_coverage();
        `uvm_info("COV", $sformatf("=== COBERTURA FUNCIONAL: %.2f%% ===", coverage), UVM_LOW)
     // $display("CG1 Coverage %.2f%%",cg_ula.cp_player_pts.get_coverage() );
     // $display("CG2 Coverage %.2f%%",cg_ula.cp_dealer_pts.get_coverage() );
     // $display("CG3 Coverage %.2f%%",cg_ula.cp_resultado.get_coverage() );
     // $display("CG4 Coverage %.2f%%",cg_ula.cp_player_bust_trans.get_coverage() );
    endfunction

endclass

