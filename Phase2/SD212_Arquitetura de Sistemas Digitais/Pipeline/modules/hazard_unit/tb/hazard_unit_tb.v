`timescale 1ns/1ns

module tb_hazard_unit;

    hazard_unit dut (
    );

    initial begin
        $dumpfile("hazard_unit.vcd");
        $dumpvars(0, tb_hazard_unit);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
