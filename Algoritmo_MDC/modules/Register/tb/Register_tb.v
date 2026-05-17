`timescale 1ns/1ns

module tb_Register;

    Register dut (
    );

    initial begin
        $dumpfile("Register.vcd");
        $dumpvars(0, tb_Register);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
