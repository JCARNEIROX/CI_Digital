`timescale 1ns/1ns

module tb_Comparator;

    Comparator dut (
    );

    initial begin
        $dumpfile("Comparator.vcd");
        $dumpvars(0, tb_Comparator);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
