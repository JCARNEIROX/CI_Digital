`timescale 1ns/1ns

module tb_control;

    control dut (
    );

    initial begin
        $dumpfile("control.vcd");
        $dumpvars(0, tb_control);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
