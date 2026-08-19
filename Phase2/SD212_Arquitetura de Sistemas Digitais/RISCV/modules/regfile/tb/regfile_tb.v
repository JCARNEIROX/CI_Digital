`timescale 1ns/1ns

module tb_regfile;

    regfile dut (
    );

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, tb_regfile);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
