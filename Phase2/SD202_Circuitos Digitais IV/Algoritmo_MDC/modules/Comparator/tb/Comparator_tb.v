`timescale 1ns/1ns

module tb_Comparator;

    parameter N = 8;
    reg [N-1:0] x, y;
    wire x_eq_y, x_gt_y, x_lt_y;
    wire [N-1:0] eq_out;

    Comparator #(
        .N(N)
    )dut(
        .x(x),
        .y(y),
        .eq_out(eq_out),
        .x_eq_y(x_eq_y),
        .x_gt_y(x_gt_y),
        .x_lt_y(x_lt_y)
    );

    initial begin
        $dumpfile("Comparator.vcd");
        $dumpvars(0, tb_Comparator);
        $monitor("Time: %0t | x: %d | y: %d | eq_out: %d | x_eq_y: %b | x_gt_y: %b | x_lt_y: %b", 
                $time, x, y, eq_out, x_eq_y, x_gt_y, x_lt_y);

        // Inicialização
        x = 4;
        y = 4; // x == y

        #10; // Aguarda 10 ns
        x = 15;
        y = 15; // x == y
        
        #10; // Aguarda 10 ns
        x = 5;
        y = 3; // x > y

        #10; // Aguarda 10 ns
        x = 2;
        y = 4; // x < y

        // Estímulos do teste aqui

        #50 $finish;
    end

endmodule
