`timescale 1ns/1ns

module tb_module_B2;

    module_B2 dut (
    );

    initial begin
        $dumpfile("module_B2.vcd");
        $dumpvars(0, tb_module_B2);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
