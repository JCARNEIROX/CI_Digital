`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_coverage extends uvm_subscriber #(ula_item);
    `uvm_component_utils(ula_coverage)
    ula_item item;
    real coverage_goal = 95.0;
    int unsigned samples_observed = 0;

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

        // SUB deve exercitar emprestimo, igualdade e diferenca positiva.
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

        // Zero e nao zero sao alcancaveis em TODAS as operacoes.
        // Ex.: AND(0, max)=0; OR(0, 0)=0; NOT(max)=0.
        opr_zero_cross : cross opr_cp, zero_cp;
    endgroup

    // Construtor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_ula = new();
        item   = new("item");
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("COV_GOAL=%f", coverage_goal));
        if (coverage_goal < 0.0 || coverage_goal > 100.0)
            `uvm_fatal("COV_CFG", "COV_GOAL deve estar entre 0 e 100")
    endfunction

    // Método write chamado pelo analysis port
    function void write(ula_item t);
        if(t == null) return;
        item = t;
        cg_ula.sample();
        samples_observed++;
    endfunction


    function void report_metric(string metric, real percent,
                                int covered, int total, int csv);
        `uvm_info("COV_DETAIL",
            $sformatf("%s: %.2f%% (%0d/%0d bins)", metric, percent, covered, total),
            UVM_LOW)
        if (csv != 0)
            $fdisplay(csv, "%s,%.6f,%0d,%0d", metric, percent, covered, total);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        real coverage, percent;
        int covered, total, csv;
        super.report_phase(phase);
        coverage = cg_ula.get_inst_coverage();
        `uvm_info("COV", $sformatf("=== COBERTURA FUNCIONAL: %.2f%% ===", coverage), UVM_LOW)
        `uvm_info("COV_SAMPLES", $sformatf("Amostras observadas=%0d", samples_observed), UVM_LOW)

        csv = $fopen("ula_coverage.csv", "w");
        if (csv == 0)
            `uvm_warning("COV_CSV", "Nao foi possivel abrir ula_coverage.csv; consulte o log")
        else
            $fdisplay(csv, "metric,percent,covered_bins,total_bins");

        percent = cg_ula.opr_cp.get_inst_coverage(covered, total);
        report_metric("opr_cp", percent, covered, total, csv);
        percent = cg_ula.a_val.get_inst_coverage(covered, total);
        report_metric("a_val", percent, covered, total, csv);
        percent = cg_ula.b_val.get_inst_coverage(covered, total);
        report_metric("b_val", percent, covered, total, csv);
        percent = cg_ula.result_cp.get_inst_coverage(covered, total);
        report_metric("result_cp", percent, covered, total, csv);
        percent = cg_ula.carry_cp.get_inst_coverage(covered, total);
        report_metric("carry_cp", percent, covered, total, csv);
        percent = cg_ula.zero_cp.get_inst_coverage(covered, total);
        report_metric("zero_cp", percent, covered, total, csv);
        percent = cg_ula.sub_order_cp.get_inst_coverage(covered, total);
        report_metric("sub_order_cp", percent, covered, total, csv);
        percent = cg_ula.div_denominator_cp.get_inst_coverage(covered, total);
        report_metric("div_denominator_cp", percent, covered, total, csv);
        percent = cg_ula.alternating_pair_cp.get_inst_coverage(covered, total);
        report_metric("alternating_pair_cp", percent, covered, total, csv);
        percent = cg_ula.opr_a_cross.get_inst_coverage(covered, total);
        report_metric("opr_a_cross", percent, covered, total, csv);
        percent = cg_ula.opr_b_cross.get_inst_coverage(covered, total);
        report_metric("opr_b_cross", percent, covered, total, csv);
        percent = cg_ula.logical_pattern_cross.get_inst_coverage(covered, total);
        report_metric("logical_pattern_cross", percent, covered, total, csv);
        percent = cg_ula.opr_carry_cross.get_inst_coverage(covered, total);
        report_metric("opr_carry_cross", percent, covered, total, csv);
        percent = cg_ula.opr_zero_cross.get_inst_coverage(covered, total);
        report_metric("opr_zero_cross", percent, covered, total, csv);
        if (csv != 0) $fclose(csv);

        if (samples_observed == 0 || coverage < coverage_goal)
            `uvm_error("COV_GOAL",
                $sformatf("Meta nao atingida: %.2f%%; meta=%.2f%%", coverage, coverage_goal))
        else
            `uvm_info("COV_GOAL",
                $sformatf("Meta atingida: %.2f%%; meta=%.2f%%", coverage, coverage_goal), UVM_LOW)
    endfunction

endclass
