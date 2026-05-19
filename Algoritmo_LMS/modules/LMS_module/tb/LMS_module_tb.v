`timescale 1ns/1ns

module tb_LMS_module;

    LMS_module dut (
    );

    initial begin
        $dumpfile("LMS_module.vcd");
        $dumpvars(0, tb_LMS_module);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
