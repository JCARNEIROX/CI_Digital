`timescale 1ns/1ns

module tb_Inverse_Matrix;

    // Parameters
    parameter N = 4; // Dimensão da Matriz
    parameter N_BITS = 32; // Bits por elemento

    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    reg signed [N*N*N_BITS-1:0] A_in; // Matriz de entrada
    wire signed [N*N*N_BITS-1:0] A_inv; // Matriz inversa de saída
    wire done;


    Inverse_Matrix #(
        .N(N),
        .N_BITS(N_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A_in),
        .A_inv(A_inv),
        .done(done)
    );

    // Clock generation: 10 ns period (5 ns high, 5 ns low)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("Inverse_Matrix.vcd");
        $dumpvars(0, tb_Inverse_Matrix);

        clk = 0;
        rst = 1;
        start = 0;
        A_in = 0;

        // Hold reset for a few clock cycles.
        #20;
        rst = 0;

        // Apply the test matrix.
            // We want:
        //   Row0: 4,  0,  0,  0
        //   Row1: 3,  2,  0,  0
        //   Row2: 0,  0,  3,  0
        //   Row3: 0,  0,  0,  5
        A_in = {
        32'sd7,  32'sd7,  32'sd2,  32'sd0,  // Row3: Col3, Col2, Col1, Col0
        32'sd7,  32'sd11, 32'sd5,  32'sd1,  // Row2: Col3, Col2, Col1, Col0
        32'sd1,  32'sd5,  32'sd5,  32'sd2,  // Row1: Col3, Col2, Col1, Col0
        32'sd0,  32'sd1,  32'sd2,  32'sd1   // Row0: Col3, Col2, Col1, Col0
        };

        // Give a cycle and then assert 'start'
        #10;
        start = 1;
        #10;
        start = 0;

        #10;
        $display("Matriz de entrada A:");
        display_matrix(A_in);

        //Aguardar o done_lu
        wait(dut.done_lu == 1);
        $display("L matrix:");
        display_matrix(dut.L_out);
        $display("U matrix:");
        display_matrix(dut.U_out);
        #10;
        //Aguardar o done
        wait (done == 1);
        #10;
        $display("A_inv matrix:");
        display_matrix(A_inv);

        #100 $finish;
    end

    // Task to display a 4x4 matrix from the packed 512-bit bus.
  // The matrix is stored in row-major order: each element is 32 bits.
    task display_matrix;
        input [511:0] matrix;
        integer r, c;
        reg signed [31:0] element;
        begin
            for (r = 0; r < 4; r = r + 1) begin
                $write("[ ");
                for (c = 0; c < 4; c = c + 1) begin
                    // Each element is located at:
                    // matrix[(r*4+c)*32 +: 32]
                    element = matrix[(r*4+c)*32 +: 32];
                    $write("%0d ", element);
                end
                $write("]\n");
            end
        end
    endtask

    endmodule
