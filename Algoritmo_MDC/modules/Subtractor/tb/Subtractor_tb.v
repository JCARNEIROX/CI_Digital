`timescale 1ns/1ns

module tb_Subtractor;

    Subtractor dut (
    );

    initial begin
        $dumpfile("Subtractor.vcd");
        $dumpvars(0, tb_Subtractor);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
