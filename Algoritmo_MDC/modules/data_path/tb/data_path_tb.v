`timescale 1ns/1ns

module tb_data_path;

    data_path dut (
    );

    initial begin
        $dumpfile("data_path.vcd");
        $dumpvars(0, tb_data_path);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
