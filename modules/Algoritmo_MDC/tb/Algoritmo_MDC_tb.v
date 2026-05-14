`timescale 1ns/1ns

module tb_Algoritmo_MDC;

    Algoritmo_MDC dut (
    );

    initial begin
        $dumpfile("Algoritmo_MDC.vcd");
        $dumpvars(0, tb_Algoritmo_MDC);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
