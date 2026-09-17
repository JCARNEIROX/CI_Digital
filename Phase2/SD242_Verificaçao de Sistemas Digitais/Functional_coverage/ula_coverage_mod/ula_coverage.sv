`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_coverage extends uvm_subscriber #(ula_item);
    `uvm_component_utils(ula_coverage)
    ula_item item;

    // Covergroup para operações e resultados
    covergroup cg_ula;
        option.per_instance = 1;

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

        // Corner cases individuais: um hit em low/high nao substitui estes bins.
        // Faixas disjuntas cobrem tambem os valores entre low, mid e high.
        a_val : coverpoint item.a {
            bins zero  = {32'd0};
            bins one   = {32'd1};
            bins max_unsigned = {32'hFFFFFFFF};
            bins alternating_10 = {32'hAAAAAAAA}; // Testar OR e AND com 10101010
            bins alternating_01 = {32'h55555555}; // Facilitar identificação de erros nas operações bitwise
            bins low  = {[32'd2:32'd100]};
            bins mid  = {[32'd1000:32'd2000]};
            bins high = {[32'hFFFFFF00:32'hFFFFFFFE]};
            bins other_values = {
                [32'd101:32'd999],
                [32'd2001:32'h55555554],
                [32'h55555556:32'hAAAAAAA9],
                [32'hAAAAAAAB:32'hFFFFFEFF]
            };
        }

        b_val : coverpoint item.b {
            bins zero  = {32'd0};
            bins one   = {32'd1};
            bins max_unsigned = {32'hFFFFFFFF};
            bins alternating_10 = {32'hAAAAAAAA};
            bins alternating_01 = {32'h55555555};
            bins low  = {[32'd2:32'd100]};
            bins mid  = {[32'd1000:32'd2000]};
            bins high = {[32'hFFFFFF00:32'hFFFFFFFE]};
            bins other_values = {
                [32'd101:32'd999],
                [32'd2001:32'h55555554],
                [32'h55555556:32'hAAAAAAA9],
                [32'hAAAAAAAB:32'hFFFFFEFF]
            };
        }

        // Bins explicitos participam da metrica, ao contrario de bins default.
        result_cp : coverpoint item.result {
            bins zero = {64'd0};
            bins one  = {64'd1};
            bins other_32_bits = {[64'd2:64'h00000000FFFFFFFE]};
            bins max_32_bits = {64'h00000000FFFFFFFF};
            bins above_32_bits = {
                [64'h0000000100000000:64'hFFFFFFFFFFFFFFFE]
            };
            bins max_64_bits = {64'hFFFFFFFFFFFFFFFF}; // SUB: 0 - 1
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

        // Cada operacao deve exercitar cada categoria de A e B.
        opr_a_cross : cross opr_cp, a_val;
        opr_b_cross : cross opr_cp, b_val {
            // NOT usa somente A; B nao afeta o resultado.
            ignore_bins unused_b = binsof(opr_cp.not_op);
        }

        // Emprestimo e igualdade sao cenarios validos, mesmo que as
        // constraints atuais ainda impecam sua geracao aleatoria.
        sub_order_cp : coverpoint ((item.a < item.b) ? 0 :
                                  (item.a == item.b) ? 1 : 2)
            iff (item.opr == ula_item::OP_SUB) {
            bins borrow = {0};
            bins equal_operands = {1};
            bins positive_difference = {2};
        }

        div_denominator_cp : coverpoint item.b
            iff (item.opr == ula_item::OP_DIV) {
            bins divide_by_zero = {32'd0};
            bins divide_by_one = {32'd1};
            bins other_divisors = {[32'd2:32'hFFFFFFFF]};
        }

        // Verifica que os padroes alternados foram usados juntos nas
        // operacoes binarias, alem dos hits individuais em cada operando.
        alternating_pair_cp : coverpoint {item.a, item.b}
            iff (item.opr inside {ula_item::OP_AND, ula_item::OP_OR}) {
            bins complementary_10_01 = {64'hAAAAAAAA55555555};
            bins complementary_01_10 = {64'h55555555AAAAAAAA};
            bins equal_10 = {64'hAAAAAAAAAAAAAAAA};
            bins equal_01 = {64'h5555555555555555};
        }

        logical_pattern_cross : cross opr_cp, alternating_pair_cp {
            ignore_bins non_logical = binsof(opr_cp) intersect {
                ula_item::OP_ADD, ula_item::OP_SUB, ula_item::OP_MUL,
                ula_item::OP_DIV, ula_item::OP_NOT
            };
        }

        // Apenas AND, OR e NOT nunca geram carry neste RTL.
        // SUB com emprestimo e DIV por zero continuam sendo metas validas.
        opr_carry_cross : cross opr_cp, carry_cp {
            ignore_bins logical_carry =
                (binsof(opr_cp) intersect {
                    ula_item::OP_AND, ula_item::OP_OR, ula_item::OP_NOT
                }) && binsof(carry_cp.carry);
        }

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
        real coverage;
        super.report_phase(phase);
        coverage = cg_ula.get_inst_coverage();
        `uvm_info("COV", $sformatf("=== COBERTURA FUNCIONAL: %.2f%% ===", coverage), UVM_LOW)
    endfunction

endclass

