`timescale 1ns/1ps

module tb_Register;

    parameter N = 8;

    reg [N-1:0] din;
    reg clk, rst, en;
    wire [N-1:0] dout;

    Register #(.N(N)) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .din(din),
        .dout(dout)
    );

    // Clock de 10 ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("Register.vcd");
        $dumpvars(0, tb_Register);

        $monitor("Time: %0t | clk: %b | rst: %b | en: %b | din: %d | dout: %d", 
                 $time, clk, rst, en, din, dout);

        // Inicialização
        clk = 0;
        rst = 1;   // ativa reset
        en  = 0;
        din = 0;

        #10;
        rst = 0;   // desativa reset
        en  = 1;
        din = 5;

        #10;
        din = 10;

        #10;
        en = 0;
        din = 20;  // dout NÃO deve mudar, pois en = 0

        #10;
        en = 1;    // dout deve atualizar para 20 no próximo clock

        #10
        rst = 1;   // ativa reset novamente, dout deve voltar para 0

        #30;
        $finish;
    end

endmodule