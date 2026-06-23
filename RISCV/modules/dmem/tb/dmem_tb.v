`timescale 1ns/1ns

module tb_dmem;

    dmem dut (
    );

    initial begin
        $dumpfile("dmem.vcd");
        $dumpvars(0, tb_dmem);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
