// Gerado por preparar.py. Edite os fontes na pasta superior e gere novamente.
`timescale 1ns/1ps

// BEGIN SOURCE: ula_if.sv
interface ula_if (input logic clk);
    logic        rst_n;
    logic [31:0] a;
    logic [31:0] b;
    logic [2:0]  opr;
    logic [63:0] result;
    logic        carry_o;
    logic        zero;

    // Clocking Block para o Testbench (TB)
    clocking tb_cb @(posedge clk);
        default input #1step output #2ns;

        // Sinais que o TB lê (saídas do DUT)
        input result, carry_o, zero;

        // Sinais que o TB escreve (entradas do DUT)
        output a, b, opr, rst_n;
    endclocking

    modport TB (clocking tb_cb, input clk);

    modport DUT (
        input  clk,
        input  rst_n,
        input  a,
        input  b,
        input  opr,
        output result,
        output carry_o,
        output zero
    );
endinterface

// END SOURCE: ula_if.sv

// BEGIN SOURCE: ula.sv

module ula (
    ula_if.DUT u_if
);

    // Operation codes (opr width must be 3 bits)
    localparam logic [2:0] OP_ADD = 3'b000,
                           OP_SUB = 3'b001,
                           OP_MUL = 3'b010,
                           OP_DIV = 3'b011,
                           OP_AND = 3'b100,
                           OP_OR  = 3'b101,
                           OP_NOT = 3'b110;

    // Internal signals
    logic [63:0] temp_result; // Resultado intermediário de todas as operações
    logic        overflow;    // Carry, borrow, overflow ou erro de divisão

    // Calcula combinacionalmente o resultado e a flag associada.
    always_comb begin
        temp_result = 64'b0;
        overflow    = 1'b0;

        case (u_if.opr)
            OP_ADD: begin
                // Soma sem sinal com extensão para 64 bits; carry em bit 32.
                temp_result = {32'b0, u_if.a} + {32'b0, u_if.b};
                overflow    = temp_result[32];
            end

            OP_SUB: begin
                // Subtração sem sinal com extensão para 64 bits; borrow em bit 32.
                temp_result = {32'b0, u_if.a} - {32'b0, u_if.b};
                overflow    = temp_result[32];
            end

            OP_MUL: begin
                // Multiplicação sem sinal de 32 por 32 bits.
                temp_result = {32'b0, u_if.a} * {32'b0, u_if.b};
                overflow    = |temp_result[63:32];
            end

            OP_DIV: begin
                if (u_if.b == 32'b0) begin
                    temp_result = 64'b0;
                    overflow    = 1'b1;
                end else begin
                    temp_result = {32'b0, u_if.a / u_if.b};
                    overflow    = 1'b0;
                end
            end

            OP_AND: begin
                temp_result = {32'b0, u_if.a & u_if.b};
                overflow    = 1'b0;
            end

            OP_OR: begin
                temp_result = {32'b0, u_if.a | u_if.b};
                overflow    = 1'b0;
            end

            OP_NOT: begin
                temp_result = {32'b0, ~u_if.a};
                overflow    = 1'b0;
            end

            default: begin
                temp_result = 64'b0;
                overflow    = 1'b0;
            end
        endcase
    end

    // Registra as saídas na borda de subida do clock.
    always_ff @(posedge u_if.clk or negedge u_if.rst_n) begin
        if (!u_if.rst_n) begin
            u_if.result  <= 64'b0;
            u_if.carry_o <= 1'b0;
            u_if.zero    <= 1'b0;
        end else begin
            u_if.result  <= temp_result;
            u_if.carry_o <= overflow;
            u_if.zero    <= (temp_result == 64'b0);
        end
    end

endmodule

// END SOURCE: ula.sv
