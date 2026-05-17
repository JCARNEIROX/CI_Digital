`timescale 1ns/1ns

module tb_Mux_2x1;

    Mux_2x1 dut (
    );

    initial begin
        $dumpfile("Mux_2x1.vcd");
        $dumpvars(0, tb_Mux_2x1);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
