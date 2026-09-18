// Gerado por preparar.py. Edite os fontes na pasta superior e gere novamente.
`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

// BEGIN SOURCE: ula_item.sv

class ula_item extends uvm_sequence_item;
    `uvm_object_utils(ula_item)

    rand logic [31:0] a;
    rand logic [31:0] b;
    rand logic [2:0] opr;
    logic [63:0] result;
    logic carry_o;
    logic zero;

    // Operações (mesmos códigos usados no RTL)
    localparam logic [2:0] OP_ADD = 3'b000;
    localparam logic [2:0] OP_SUB = 3'b001;
    localparam logic [2:0] OP_MUL = 3'b010;
    localparam logic [2:0] OP_DIV = 3'b011;
    localparam logic [2:0] OP_AND = 3'b100;
    localparam logic [2:0] OP_OR  = 3'b101;
    localparam logic [2:0] OP_NOT = 3'b110;

    constraint opr_val {
        opr inside {[OP_ADD:OP_NOT]};
    }

    constraint reasonable_values {
        a inside {[32'd1000:32'd2000]};
        b inside {[32'd1000:32'd2000]};
    }

    // SUB com a <= b e DIV por zero sao comportamentos definidos no RTL.
    // Não os excluímos: precisam aparecer nos testes e no coverage.

    function new(string name = "ula_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s: opr=%0d a=0x%08h b=0x%08h -> result=0x%016h carry=%0b zero=%0b",
                         get_type_name(), opr, a, b, result, carry_o, zero);
    endfunction
    
endclass

class facil_transaction extends ula_item;
    `uvm_object_utils(facil_transaction)

    constraint reasonable_values {
        a inside {[0:32'd100]};
        b inside {[32'd0:32'd100]};
    }

    function new(string name = "facil_transaction");
        super.new(name);
    endfunction

endclass

class limite_transaction extends ula_item;
    `uvm_object_utils(limite_transaction)

    constraint reasonable_values {
        a inside {[32'hFFFFFF00:32'hFFFFFFFF]};
        b inside {[32'hFFFFFF00:32'hFFFFFFFF]};
    }

    function new(string name = "limite_transaction");
        super.new(name);
    endfunction

endclass

class corner_transaction extends ula_item;
    `uvm_object_utils(corner_transaction)

    constraint reasonable_values {
        a inside {32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555};
        b inside {32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555};
    }

    function new(string name = "corner_transaction");
        super.new(name);
    endfunction
endclass

class full_range_transaction extends ula_item;
    `uvm_object_utils(full_range_transaction)

    constraint reasonable_values {
        a inside {[32'd0:32'hFFFFFFFF]};
        b inside {[32'd0:32'hFFFFFFFF]};
    }

    function new(string name = "full_range_transaction");
        super.new(name);
    endfunction
endclass

// END SOURCE: ula_item.sv

// BEGIN SOURCE: ula_driver.sv
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


// END SOURCE: ula_driver.sv

// BEGIN SOURCE: ula_monitor.sv
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

// END SOURCE: ula_monitor.sv

// BEGIN SOURCE: ula_sequencer.sv
class ula_sequencer extends uvm_sequencer #(ula_item);
    `uvm_component_utils(ula_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass


// END SOURCE: ula_sequencer.sv

// BEGIN SOURCE: ula_sequence.sv
class ula_sequence extends uvm_sequence #(ula_item);
    `uvm_object_utils(ula_sequence)

    // Configuração, não variáveis rand: o teste define estes valores.
    int unsigned num_transactions = 1000; // Quantidade da fase aleatória.
    bit run_corners = 1;
    int unsigned directed_count = 0;
    int unsigned type_count[5] = '{default: 0};

    typedef enum int unsigned {
        ITEM_MID, ITEM_LOW, ITEM_HIGH, ITEM_CORNER, ITEM_FULL
    } item_kind_t;

    function new(string name = "ula_sequence");
        super.new(name);
    endfunction

    // Atribuição dirigida não usa randomize() nem as restrições de sorteio.
    task send_directed(logic [2:0] operation,
                       logic [31:0] operand_a, logic [31:0] operand_b);
        ula_item trans;
        trans = ula_item::type_id::create("directed_item");
        start_item(trans);
        trans.opr = operation;
        trans.a   = operand_a;
        trans.b   = operand_b;
        finish_item(trans);
        directed_count++;
    endtask

    task send_corner_cases();
        // Um representante de cada bin de A/B, incluindo other_values.
        logic [31:0] values[9] = '{
            32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555,
            32'd2, 32'd1000, 32'hFFFFFFFE, 32'd101
        };

        // Seis operações binárias: 6 * 9 * 9 = 486 transações.
        for (int op = ula_item::OP_ADD; op <= ula_item::OP_OR; op++) begin
            foreach (values[i]) begin
                foreach (values[j]) begin
                    send_directed(op[2:0], values[i], values[j]);
                end
            end
        end

        // NOT não usa B: nove transações bastam para as categorias de A.
        foreach (values[i]) begin
            send_directed(ula_item::OP_NOT, values[i], 32'd0);
        end

        // Fronteiras adicionais da multiplicação em torno de 2**32.
        send_directed(ula_item::OP_MUL, 32'd65535, 32'd65535);
        send_directed(ula_item::OP_MUL, 32'd65536, 32'd65536);
        send_directed(ula_item::OP_MUL, 32'd65535, 32'd65536);
        send_directed(ula_item::OP_MUL, 32'd65536, 32'd65535);
    endtask

    virtual task body();
        ula_item trans_item;
        item_kind_t item_kind;

        directed_count = 0;
        foreach (type_count[i]) begin
            type_count[i] = 0;
        end
        if (run_corners) begin
            send_corner_cases();
        end

        for (int unsigned i = 0; i < num_transactions; i++) begin
            // O enum permite os cinco tipos com o mesmo peso no sorteio.
            if (!std::randomize(item_kind)) begin
                `uvm_fatal("SEQ_RANDOM", "Falha no sorteio do tipo de item")
            end

            case (item_kind)
                ITEM_MID:    trans_item = ula_item::type_id::create("mid_item");
                ITEM_LOW:    trans_item = facil_transaction::type_id::create("low_item");
                ITEM_HIGH:   trans_item = limite_transaction::type_id::create("high_item");
                ITEM_CORNER: trans_item = corner_transaction::type_id::create("corner_item");
                ITEM_FULL:   trans_item = full_range_transaction::type_id::create("full_item");
                default: `uvm_fatal("SEQ_KIND", "Tipo de item inválido")
            endcase

            start_item(trans_item);
            if (!trans_item.randomize()) begin
                `uvm_fatal("SEQ_RANDOM", "Falha ao randomizar operandos/operacao")
            end
            finish_item(trans_item);
            type_count[item_kind]++;
        end

        `uvm_info("SEQ_SUMMARY",
            $sformatf("Dirigidas=%0d Aleatorias=%0d Total=%0d | mid=%0d low=%0d high=%0d corner=%0d full=%0d",
                      directed_count, num_transactions, directed_count + num_transactions,
                      type_count[ITEM_MID], type_count[ITEM_LOW], type_count[ITEM_HIGH],
                      type_count[ITEM_CORNER], type_count[ITEM_FULL]), UVM_LOW)
    endtask
endclass

// END SOURCE: ula_sequence.sv

// BEGIN SOURCE: ula_agent_config.sv

`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_agent_config extends uvm_object;
    `uvm_object_utils(ula_agent_config)

    bit is_active = UVM_ACTIVE; // Agente ativo por padrão

    function new(string name = "ula_agent_config");
        super.new(name);
    endfunction
endclass

// END SOURCE: ula_agent_config.sv

// BEGIN SOURCE: ula_agent.sv
class ula_agent extends uvm_agent;
    `uvm_component_utils(ula_agent)

    ula_driver    driver;
    ula_sequencer sequencer;
    ula_monitor   monitor;

    ula_agent_config cfg;
    uvm_analysis_port #(ula_item) agent_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        agent_ap = new("agent_ap", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Obtém a configuração do agente
        if (!uvm_config_db#(ula_agent_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("AGENT_NO_CFG", "ula_agent_config not found for agent")
        end

        if (cfg.is_active == UVM_ACTIVE) begin
            driver    = ula_driver::type_id::create("driver", this);
            sequencer = ula_sequencer::type_id::create("sequencer", this);
        end

        monitor = ula_monitor::type_id::create("monitor", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        monitor.item_collected_port.connect(agent_ap);
    endfunction

endclass

// END SOURCE: ula_agent.sv

// BEGIN SOURCE: ula_scoreboard.sv

`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ula_scoreboard)

    // Recebe transações observadas pelo monitor.
    uvm_analysis_imp #(ula_item, ula_scoreboard) analysis_imp;

    // Estatísticas
    int num_matches;
    int num_mismatches;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_imp = new("analysis_imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        num_matches    = 0;
        num_mismatches = 0;
    endfunction

    // Chamado sempre que o monitor publica uma transação.
    function void write(ula_item trans);
        ula_item expected;
        expected = ula_item::type_id::create("expected");

        // Calcula as saídas esperadas pelo modelo de referência.
        compute_expected(trans, expected);

        // Compara as saídas esperadas com as observadas.
        if (expected.result  !== trans.result ||
            expected.carry_o !== trans.carry_o ||
            expected.zero    !== trans.zero) begin

            `uvm_error("SCOREBOARD_MISMATCH",
                $sformatf({"opr=%0d a=0x%08h b=0x%08h | ",
                           "Esperado: result=0x%016h carry=%0b zero=%0b | ",
                           "Observado: result=0x%016h carry=%0b zero=%0b"},
                          trans.opr, trans.a, trans.b,
                          expected.result, expected.carry_o, expected.zero,
                          trans.result, trans.carry_o, trans.zero)
            )
            num_mismatches++;
        end else begin
            `uvm_info("SCOREBOARD_MATCH",
                $sformatf("Match: result=%0d, carry_o=%0b, zero=%0b",
                          trans.result, trans.carry_o, trans.zero),
                UVM_HIGH)
            num_matches++;
        end
    endfunction

    // Modelo de referência que replica o comportamento da ULA.
    function void compute_expected(ula_item in, ula_item out);
        logic [63:0] temp_result;
        logic        overflow;

        temp_result = 64'b0;
        overflow    = 1'b0;

        case (in.opr)
            ula_item::OP_ADD: begin
                temp_result = {32'b0, in.a} + {32'b0, in.b};
                overflow    = temp_result[32];
            end

            ula_item::OP_SUB: begin
                temp_result = {32'b0, in.a} - {32'b0, in.b};
                overflow    = temp_result[32];
            end

            ula_item::OP_MUL: begin
                temp_result = {32'b0, in.a} * {32'b0, in.b};
                overflow    = |temp_result[63:32];
            end

            ula_item::OP_DIV: begin
                if (in.b == 32'b0) begin
                    temp_result = 64'b0;
                    overflow    = 1'b1;
                end else begin
                    temp_result = {32'b0, in.a / in.b};
                    overflow    = 1'b0;
                end
            end

            ula_item::OP_AND: begin
                temp_result = {32'b0, in.a & in.b};
                overflow    = 1'b0;
            end

            ula_item::OP_OR: begin
                temp_result = {32'b0, in.a | in.b};
                overflow    = 1'b0;
            end

            ula_item::OP_NOT: begin
                temp_result = {32'b0, ~in.a};
                overflow    = 1'b0;
            end

            default: begin
                temp_result = 64'b0;
                overflow    = 1'b0;
            end
        endcase

        out.result  = temp_result;
        out.carry_o = overflow;
        out.zero    = (out.result == 64'b0);
    endfunction

    // Exibe as estatísticas finais.
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("Scoreboard summary: Matches=%0d, Mismatches=%0d",
                      num_matches, num_mismatches),
            UVM_LOW)
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if ((num_matches + num_mismatches) == 0)
            `uvm_error("SCOREBOARD_EMPTY", "Nenhuma amostra foi conferida")
    endfunction

endclass

// END SOURCE: ula_scoreboard.sv

// BEGIN SOURCE: ula_coverage.sv
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

        // Corner cases individuais: um hit em low/high não substitui estes bins.
        // Faixas disjuntas cobrem também os valores entre low, mid e high.
        a_val : coverpoint item.a {
            bins zero           = {32'd0};
            bins one            = {32'd1};
            bins max_unsigned   = {32'hFFFFFFFF};
            bins alternating_10 = {32'hAAAAAAAA};
            bins alternating_01 = {32'h55555555};
            bins low            = {[32'd2:32'd100]};
            bins mid            = {[32'd1000:32'd2000]};
            bins high           = {[32'hFFFFFF00:32'hFFFFFFFE]};
            bins other_values = {
                [32'd101:32'd999],
                [32'd2001:32'h55555554],
                [32'h55555556:32'hAAAAAAA9],
                [32'hAAAAAAAB:32'hFFFFFEFF]
            };
        }

        b_val : coverpoint item.b {
            bins zero           = {32'd0};
            bins one            = {32'd1};
            bins max_unsigned   = {32'hFFFFFFFF};
            bins alternating_10 = {32'hAAAAAAAA};
            bins alternating_01 = {32'h55555555};
            bins low            = {[32'd2:32'd100]};
            bins mid            = {[32'd1000:32'd2000]};
            bins high           = {[32'hFFFFFF00:32'hFFFFFFFE]};
            bins other_values = {
                [32'd101:32'd999],
                [32'd2001:32'h55555554],
                [32'h55555556:32'hAAAAAAA9],
                [32'hAAAAAAAB:32'hFFFFFEFF]
            };
        }

        // Bins explícitos participam da métrica, ao contrário de bins default.
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

        // Cada operação deve exercitar cada categoria de A e B.
        opr_a_cross : cross opr_cp, a_val;
        opr_b_cross : cross opr_cp, b_val {
            // NOT usa somente A; B nao afeta o resultado.
            ignore_bins unused_b = binsof(opr_cp.not_op);
        }

        // SUB deve exercitar empréstimo, igualdade e diferença positiva.
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

        // Verifica que os padrões alternados foram usados juntos nas
        // operações binárias, além dos hits individuais em cada operando.
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
        // SUB com empréstimo e DIV por zero continuam sendo metas válidas.
        opr_carry_cross : cross opr_cp, carry_cp {
            ignore_bins logical_carry =
                (binsof(opr_cp) intersect {
                    ula_item::OP_AND, ula_item::OP_OR, ula_item::OP_NOT
                }) && binsof(carry_cp.carry);
        }

        // Zero e não zero são alcançáveis em todas as operações.
        // Ex.: AND(0, max)=0; OR(0, 0)=0; NOT(max)=0.
        opr_zero_cross : cross opr_cp, zero_cp;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_ula = new();
        cg_ula.start();
        item   = new("item");
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("COV_GOAL=%f", coverage_goal));
        if (coverage_goal < 0.0 || coverage_goal > 100.0)
            `uvm_fatal("COV_CFG", "COV_GOAL deve estar entre 0 e 100")
    endfunction

    // Chamado pelo analysis port para amostrar a transação observada.
    function void write(ula_item t);
        if (t == null) begin
            return;
        end
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
        if (csv != 0) begin
            $fclose(csv);
        end

        if (samples_observed == 0 || coverage < coverage_goal)
            `uvm_error("COV_GOAL",
                $sformatf("Meta nao atingida: %.2f%%; meta=%.2f%%", coverage, coverage_goal))
        else
            `uvm_info("COV_GOAL",
                $sformatf("Meta atingida: %.2f%%; meta=%.2f%%", coverage, coverage_goal), UVM_LOW)
    endfunction

endclass

// END SOURCE: ula_coverage.sv

// BEGIN SOURCE: ula_env_config.sv

`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_env_config extends uvm_object;
    `uvm_object_utils(ula_env_config)

    bit has_scoreboard = 1'b1; // Habilita o scoreboard por padrão

    ula_agent_config agent_cfg; // Configuração do agente

    function new(string name = "ula_env_config");
        super.new(name);
        agent_cfg = ula_agent_config::type_id::create("agent_cfg");
    endfunction
endclass

// END SOURCE: ula_env_config.sv

// BEGIN SOURCE: ula_env.sv

class ula_env extends uvm_env;
    `uvm_component_utils(ula_env)

    ula_agent      agent;
    ula_scoreboard sb;
    ula_coverage   coverage;

    ula_env_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Obtém a configuração do ambiente
        if (!uvm_config_db#(ula_env_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("ENV_NO_CFG", "ula_env_config not found for env")
        end

        // Passa a configuração do agente para o agente via config_db
        uvm_config_db#(ula_agent_config)::set(this, "agent", "cfg", cfg.agent_cfg);

        agent = ula_agent::type_id::create("agent", this);

        // Cria o scoreboard somente quando habilitado.
        if (cfg.has_scoreboard) begin
            sb = ula_scoreboard::type_id::create("sb", this);
        end

        coverage = ula_coverage::type_id::create("coverage", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.has_scoreboard) begin
            agent.agent_ap.connect(sb.analysis_imp);
        end

        agent.agent_ap.connect(coverage.analysis_export);
    endfunction
endclass

// END SOURCE: ula_env.sv

// BEGIN SOURCE: ula_test.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_test extends uvm_test;
    `uvm_component_utils(ula_test)

    ula_env env;
    ula_sequence seq;
    ula_env_config env_cfg;

    int requested_transactions;
    int requested_corners;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Cria e configura o ambiente.
        env_cfg = ula_env_config::type_id::create("env_cfg");

        // Exemplo 1: Agente ATIVO com scoreboard HABILITADO
        env_cfg.agent_cfg.is_active = UVM_ACTIVE;
        env_cfg.has_scoreboard      = 1'b1;

        // Armazena no config_db para que o ambiente possa recuperar
        uvm_config_db#(ula_env_config)::set(this, "env", "cfg", env_cfg);

        env = ula_env::type_id::create("env", this);
        seq = ula_sequence::type_id::create("seq");
        if ($value$plusargs("NUM_TRANSACTIONS=%d", requested_transactions)) begin
            if (requested_transactions < 0)
                `uvm_fatal("TEST_CFG", "NUM_TRANSACTIONS deve ser >= 0")
            seq.num_transactions = requested_transactions;
        end
        if ($value$plusargs("RUN_CORNERS=%d", requested_corners)) begin
            if (!(requested_corners inside {0, 1}))
                `uvm_fatal("TEST_CFG", "RUN_CORNERS deve ser 0 ou 1")
            seq.run_corners = requested_corners;
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #100; // Tempo extra para finalizar o último monitoramento.
        phase.drop_objection(this);
    endtask

endclass

// END SOURCE: ula_test.sv

// BEGIN SOURCE: top_tb.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

module top_tb;

    logic clk;

    ula_if u_if0(clk);

    ula dut (
        u_if0.DUT
    );

    always #5 clk = ~clk;

    initial begin
        clk         = 1'b0;
        u_if0.rst_n = 1'b0;
        repeat (2) @(u_if0.clk);
        u_if0.rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual ula_if)::set(null, "uvm_test_top.env.agent.*", "vif", u_if0);
        run_test("ula_test");
    end

endmodule

// END SOURCE: top_tb.sv
