`include "uvm_macros.svh"
import uvm_pkg::*;

interface soma_if (input logic clk); // A interface é sincronizada por um clk

    // Sinais do módulo 'sum'
    logic        rst_n;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] result;
    logic        carry_o;

    // Clocking Block para o Testbench (TB)
    clocking tb_cb @(posedge clk);
        default input #1step output #2ns; // Configuração de timing padrão

        // Sinais que o TB lê (saídas do DUT)
        input  result, carry_o;

        // Sinais que o TB escreve (entradas do DUT)
        output a, b;
    endclocking

    // Modport para o Testbench
    // O TB usará o clocking block para interagir
    modport TB (clocking tb_cb, input clk);

    // Modport para o DUT (Design Under Test)
    // Mapeia os sinais da interface para as portas do módulo 'sum'
    modport DUT (
        input  clk,
        input  rst_n,
        input  a,
        input  b,
        output result,
        output carry_o
    );

endinterface

module soma (
   soma_if.DUT s_if
);

    always_ff @(posedge s_if.clk or negedge s_if.rst_n) begin
        if (!s_if.rst_n) begin
            s_if.result <= 32'b0;
            s_if.carry_o <= 1'b0;
        end else begin
            {s_if.carry_o, s_if.result} <= s_if.a + s_if.b;
        end
    end

endmodule

/////// TB

module top_tb;

    logic clk;
    logic rst_n;

    soma_if s_if0(clk);

    // DUT instance
    soma dut (
        s_if0.DUT
    );

    always #5 clk = ~clk;

    // Reset generation
    initial begin
        clk = 0;
        s_if0.rst_n = 0;
        repeat(4) @s_if0.clk;
        s_if0.rst_n = 1;
	repeat(1) @s_if0.clk;

    end

    initial begin
        // Set virtual interface
        uvm_config_db#(virtual soma_if)::set(null, "uvm_test_top.env.agent.*", "vif", s_if0);

        // Run test
        run_test("add_test");
    end

endmodule


