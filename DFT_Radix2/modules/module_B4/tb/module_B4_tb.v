`timescale 1ns/1ns

module tb_module_B4;

    module_B4 dut (
    );

    initial begin
        $dumpfile("module_B4.vcd");
        $dumpvars(0, tb_module_B4);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
