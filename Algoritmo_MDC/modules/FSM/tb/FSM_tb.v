`timescale 1ns/1ns

module tb_FSM;

    FSM dut (
    );

    initial begin
        $dumpfile("FSM.vcd");
        $dumpvars(0, tb_FSM);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
