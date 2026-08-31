`timescale 1ns/1ps
/// INTERFACE
interface dut_if #(
    parameter int DATA_WIDTH = 16,
    parameter int ADDR_WIDTH = 8
                ) ( input logic clk ); // A interface é sincronizada por um clk
    // Sinais do módulo
    logic rst_n;
    logic w_en;
    logic r_en;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic [ADDR_WIDTH-1:0] addr;
    // Clocking Block para o Testbench (TB)
    clocking tb_cb @(posedge clk);
    default input #1step output #2ns; // Configuração de timing padrão
    // Sinais que o TB lê (saídas do DUT)
    input data_out;
    // Sinais que o TB escreve (entradas do DUT)
    output w_en, r_en, data_in, addr;
    endclocking
    // Modport para o Testbench
    // O TB usará o clocking block para interagir
    modport TB (clocking tb_cb, input clk);

    // Modport para o DUT (Design Under Test)
    modport DUT (
        input clk,
        input rst_n,
        input w_en,
        input r_en,
        input data_in,
        input addr,
        output data_out
    );
    endinterface