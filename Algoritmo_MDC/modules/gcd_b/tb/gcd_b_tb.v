`timescale 1ns/1ns

module tb_gcd_b;

    gcd_b dut (
    );

    initial begin
        $dumpfile("gcd_b.vcd");
        $dumpvars(0, tb_gcd_b);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
