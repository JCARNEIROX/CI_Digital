`timescale 1ns/1ns

module tb_Algoritmo_LMS;

    Algoritmo_LMS dut (
    );

    initial begin
        $dumpfile("Algoritmo_LMS.vcd");
        $dumpvars(0, tb_Algoritmo_LMS);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
