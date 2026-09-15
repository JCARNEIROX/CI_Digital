
interface ula_if (input logic clk);
    logic        rst_n;
    logic [31:0] a;
    logic [31:0] b;
    logic        opr;
    logic [63:0] result;
    logic        carry_o;
    logic        zero;

    // Clocking Block para o Testbench (TB)
    clocking tb_cb @(posedge clk);
        default input #1step output #2ns; // Configuração de timing padrão
        
        // Sinais que o TB lê (saídas do DUT)
        input  result, carry_o, zero;
        
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
