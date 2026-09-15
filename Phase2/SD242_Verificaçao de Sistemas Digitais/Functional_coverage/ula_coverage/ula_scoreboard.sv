
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
