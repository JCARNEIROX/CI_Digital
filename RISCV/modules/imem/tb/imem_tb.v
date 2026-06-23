`timescale 1ns/1ns

module tb_imem;

    imem dut (
    );

    initial begin
        $dumpfile("imem.vcd");
        $dumpvars(0, tb_imem);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
