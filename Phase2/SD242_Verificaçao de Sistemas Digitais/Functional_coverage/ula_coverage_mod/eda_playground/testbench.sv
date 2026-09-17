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
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_NOT = 3'b110;

    constraint opr_val {
	opr inside {[3'b000:3'b110]};
    }

    constraint reasonable_values {
        a inside {[32'd1000:32'd2000]};
	    b inside {[32'd1000:32'd2000]};
    }

    constraint operacao_subtrair {
        (opr == OP_SUB) -> (a > b);
    }

    constraint operacao_dividir {
        (opr == OP_DIV) -> (b != 32'b0);
    }

    function new(string name = "ula_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf( "%s: a=0x%8h, b=0x%8h -> result=0x%8h, carry_o=%0d", get_type_name(), 
                         a, b, result, carry_o);
    endfunction
    
endclass

class facil_transaction extends ula_item;
    `uvm_object_utils(facil_transaction)

    constraint reasonable_values {
        a inside {[0:32'd100]};
	b inside {[0:32'd100]};
    }

    function new(string name = "facil_transaction");
        super.new(name);
    endfunction

endclass

class limite_transaction extends ula_item;
    `uvm_object_utils(limite_transaction)

    constraint reasonable_values {
        a > {32'hFFFFFF00};
	b > {32'hFFFFFF00};
    }

    function new(string name = "limite_transaction");
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
        // So aplica entradas em uma borda com reset desativado e conhecido.
        do begin
            @(posedge vif.clk);
        end while (vif.rst_n !== 1'b1);
        vif.a <= i_trans.a;
        vif.b <= i_trans.b;
        vif.opr <= i_trans.opr;
        `uvm_info("DRV", $sformatf("Driving: %s", i_trans.convert2string()), UVM_LOW)
        
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
            if (vif.rst_n !== 1'b1) continue;

            // Antes do primeiro estimulo, as entradas ainda podem estar em X.
            if ($isunknown(vif.opr) || $isunknown(vif.a) ||
                $isunknown(vif.b)) continue;

            // Captura as mesmas entradas que o DUT usa nesta borda,
            // antes das atribuicoes nao bloqueantes do driver.
            trans = ula_item::type_id::create("trans");
            trans.opr     = vif.opr;
            trans.a       = vif.a;
            trans.b       = vif.b;

            // As saidas registradas ja estao estaveis na borda de descida.
            // Se houver reset durante a espera, descarta esta amostra.
            @(negedge vif.clk or negedge vif.rst_n);
            if (vif.rst_n !== 1'b1) continue;
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
    
    rand int num_transactions = 10;
    rand bit rand_item;
    constraint rand_i { rand_item inside {0 , 1}; }

    function new(string name = "ula_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ula_item trans_item;

        for (int i = 0; i < num_transactions; i++) begin


	    if (!std::randomize(rand_item)) begin
                `uvm_error("SEQ", "Randomization failed: std::randomize(rand_item)")
            end

	    `uvm_info("[SEQ1] ", $sformatf("Class sel: %d", rand_item), UVM_LOW)

            if (rand_item == 1'b0) trans_item = facil_transaction::type_id::create("facil_transaction");
	    else trans_item = limite_transaction::type_id::create("limite_transaction");

            start_item(trans_item);

            if (!trans_item.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end

            finish_item(trans_item);

           `uvm_info("[SEQ] ", $sformatf(" Generated: %s", trans_item.convert2string()), UVM_LOW)
        end
    endtask
    
endclass

// END SOURCE: ula_sequence.sv

// BEGIN SOURCE: ula_agent_config.sv

`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_agent_config extends uvm_object;
    `uvm_object_utils(ula_agent_config)

    bit is_active = UVM_ACTIVE;               // Habilita scoreboard por padrão

    function new(string name = "ula_env_config");
        super.new(name);
        //agent_cfg = ula_agent_config::type_id::create("agent_cfg");
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
        if (!uvm_config_db #(ula_agent_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("AGENT_NO_CFG", "ula_agent_config not found for agent")

	if (cfg.is_active == UVM_ACTIVE) begin
           driver = ula_driver::type_id::create("driver", this);
           sequencer = ula_sequencer::type_id::create("sequencer", this);
	end

        monitor = ula_monitor::type_id::create("monitor",this);
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

    // Analysis port to receive observed transactions from monitor
    uvm_analysis_imp #(ula_item, ula_scoreboard) analysis_imp;

    // Statistics
    int num_matches;
    int num_mismatches;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_imp = new("analysis_imp", this);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        num_matches    = 0;
        num_mismatches = 0;
    endfunction

    // Write method ? called whenever monitor sends a transaction
    function void write(ula_item trans);
        ula_item expected;
        expected = new("expected");

        // Compute expected outputs using reference model
        compute_expected(trans, expected);

        // Compare with actual observed values
        if (expected.result  !== trans.result ||
            expected.carry_o !== trans.carry_o ||
            expected.zero    !== trans.zero) begin

/*            `uvm_error("SCOREBOARD_MISMATCH",
                $sformatf("Mismatch detected!\nInputs: opr=%0d, a=%0d, b=%0d\n" \
                          "Expected: result=%0d, carry_o=%0b, zero=%0b\n" \
                          "Observed: result=%0d, carry_o=%0b, zero=%0b",
                          trans.opr, trans.a, trans.b,
                          expected.result, expected.carry_o, expected.zero,
                          trans.result, trans.carry_o, trans.zero) 
            )*/
            num_mismatches++;
        end else begin
            `uvm_info("SCOREBOARD_MATCH",
                $sformatf("Match: result=%0d, carry_o=%0b, zero=%0b",
                          trans.result, trans.carry_o, trans.zero),
                UVM_LOW)
            num_matches++;
        end
    endfunction

    // -----------------------------------------------
    // Reference model ? exact replica of ALU behaviour
    // -----------------------------------------------
    function void compute_expected(ula_item in, ula_item out);
        logic [63:0] temp_result;
        logic        overflow;

        temp_result = 64'b0;
        overflow    = 1'b0;

        case (in.opr)
            3'b000: begin  // ADD
                temp_result = {32'b0, in.a} + {32'b0, in.b};
                overflow    = temp_result[32];
            end

            3'b001: begin  // SUB
                temp_result = {32'b0, in.a} - {32'b0, in.b};
                overflow    = temp_result[32];
            end

            3'b010: begin  // MUL
                temp_result = {32'b0, in.a} * {32'b0, in.b};
                overflow    = |temp_result[63:32];
            end

            3'b011: begin  // DIV
                if (in.b == 32'b0) begin
                    temp_result = 64'b0;
                    overflow    = 1'b1;
                end else begin
                    temp_result = {32'b0, in.a / in.b};
                    overflow    = 1'b0;
                end
            end

            3'b100: begin  // AND
                temp_result = {32'b0, in.a & in.b};
                overflow    = 1'b0;
            end

            3'b101: begin  // OR
                temp_result = {32'b0, in.a | in.b};
                overflow    = 1'b0;
            end

            3'b110: begin  // NOT
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
        out.zero    = (out.result == 32'b0);
    endfunction

    // Report phase ? print final statistics
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("Scoreboard summary: Matches=%0d, Mismatches=%0d",
                      num_matches, num_mismatches),
            UVM_LOW)
    endfunction

endclass

// END SOURCE: ula_scoreboard.sv

// BEGIN SOURCE: ula_coverage.sv
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


// END SOURCE: ula_coverage.sv

// BEGIN SOURCE: ula_env_config.sv

`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_env_config extends uvm_object;
    `uvm_object_utils(ula_env_config)

    bit has_scoreboard = 1'b1;               // Habilita scoreboard por padrão

    ula_agent_config agent_cfg;              // Configuração do agente

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
        if (!uvm_config_db #(ula_env_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("ENV_NO_CFG", "ula_env_config not found for env")

        // Passa a configuração do agente para o agente via config_db
        uvm_config_db #(ula_agent_config)::set(this, "agent", "cfg", cfg.agent_cfg);

        agent = ula_agent::type_id::create("agent", this);

        // Cria o scoreboard somente se habilitado
        if (cfg.has_scoreboard) begin
            sb = ula_scoreboard::type_id::create("sb", this);
        end

       coverage   = ula_coverage::type_id::create("coverage", this);
 
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect monitor's analysis port to scoreboard's import

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

    int clock_delay;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Cria e configura a configuração do ambiente
        env_cfg = ula_env_config::type_id::create("env_cfg");
        
        // Exemplo 1: Agente ATIVO com scoreboard HABILITADO
        env_cfg.agent_cfg.is_active = UVM_ACTIVE;
        env_cfg.has_scoreboard      = 1'b1;

	if ($value$plusargs("CLOCK_DELAY=%d", clock_delay))
            `uvm_info(get_name(), $sformatf("Usando %0d CLOCK_DELAY", clock_delay), UVM_LOW)
        // Exemplo 2: Agente PASSIVO com scoreboard DESABILITADO
        // env_cfg.agent_cfg.is_active = UVM_PASSIVE;
        // env_cfg.has_scoreboard      = 1'b0;

        // Armazena no config_db para que o ambiente possa recuperar
        uvm_config_db #(ula_env_config)::set(this, "env", "cfg", env_cfg);

        env = ula_env::type_id::create("env", this);
        seq = ula_sequence::type_id::create("seq");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #100; // Tempo extra para finalizar
        phase.drop_objection(this);
    endtask
    
endclass

// END SOURCE: ula_test.sv

// BEGIN SOURCE: top_tb.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

module top_tb;

    logic clk;
    logic rst_n;

    ula_if u_if0(clk);

    // DUT instance
    ula dut (
        u_if0.DUT
    );

    always #5 clk = ~clk;

    // Reset generation
    initial begin
        clk = 0;
        u_if0.rst_n = 0;
        repeat(2) @u_if0.clk;
        u_if0.rst_n = 1;
        
    end

    // Reset generation
    initial begin
        // Set virtual interface
        uvm_config_db#(virtual ula_if)::set(null, "uvm_test_top.env.agent.*", "vif", u_if0);

        // Run test
        run_test("ula_test");
    end

endmodule


    // Monitor
/*    initial begin
        repeat(5) @u_if0.clk;
        forever begin
            @u_if0.clk;
            if (u_if0.a != 0 || u_if0.b != 0) begin
		if (u_if0.opr == 1) begin
			@u_if0.clk;
                	$display("[MON SOMA] a=%0d, b=%0d -> result=%0d, carry=%0d", 
                         u_if0.a, u_if0.b, u_if0.result, u_if0.carry_o);
		end else begin
                	$display("[MON SUB] a=%0d, b=%0d -> result=%0d, carry=%0d", 
                         u_if0.a, u_if0.b, u_if0.result, u_if0.carry_o);		
		end
            end
        end
    end*/

// END SOURCE: top_tb.sv
