
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
