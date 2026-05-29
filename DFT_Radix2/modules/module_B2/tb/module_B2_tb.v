`timescale 1ns/1ns

module gcd_a_tb();

    parameter WIDTH = 8;

    reg signed [WIDTH-1:0] a_r, a_i;
    reg signed [WIDTH-1:0] b_r, b_i;
    reg signed [WIDTH-1:0] w_r, w_i;

    wire signed [WIDTH-1:0] x1_r, x1_i;
    wire signed [WIDTH-1:0] x2_r, x2_i;
    wire signed [WIDTH-1:0] bw_r, bw_i;

    wire signed [2*WIDTH-1:0] A;
    wire signed [2*WIDTH-1:0] B;
    wire signed [2*WIDTH-1:0] W;

    wire signed [2*WIDTH-1:0] X0;
    wire signed [2*WIDTH-1:0] X1;

    // Montagem dos valores complexos
    assign A = {a_i, a_r};
    assign B = {b_i, b_r};
    assign W = {w_i, w_r};

    // Separação dos resultados
    assign x1_r = X0[WIDTH-1:0];
    assign x1_i = X0[2*WIDTH-1:WIDTH];

    assign x2_r = X1[WIDTH-1:0];
    assign x2_i = X1[2*WIDTH-1:WIDTH];

    radix2_2In #(
        .WIDTH(WIDTH)
    ) dut (
        .A(A),
        .B(B),
        .W(W),
        .X0(X0),
        .X1(X1)
    );

    initial begin

        // passo 1
        a_r = 0;
        a_i = 0;
        b_r = 2;
        b_i = 0;
        w_r = 1;
        w_i = 0;

        #1;
        $display("a = (%d + j%d), b = (%d + j%d), w = (%d + j%d) --> x1 = (%d + j%d), x2 = (%d + j%d)",
                 a_r, a_i, b_r, b_i, w_r, w_i, x1_r, x1_i, x2_r, x2_i);

        #2;

        a_r = 1;
        a_i = 0;
        b_r = 3;
        b_i = 0;
        w_r = 1;
        w_i = 0;

        #1;
        $display("a = (%d + j%d), b = (%d + j%d), w = (%d + j%d) --> x1 = (%d + j%d), x2 = (%d + j%d)",
                 a_r, a_i, b_r, b_i, w_r, w_i, x1_r, x1_i, x2_r, x2_i);

        #2;

        // passo 2
        a_r = 2;
        a_i = 0;
        b_r = 4;
        b_i = 0;
        w_r = 1;
        w_i = 0;

        #1;
        $display("a = (%d + j%d), b = (%d + j%d), w = (%d + j%d) --> x1 = (%d + j%d), x2 = (%d + j%d)",
                 a_r, a_i, b_r, b_i, w_r, w_i, x1_r, x1_i, x2_r, x2_i);

        #2;

        a_r = -2;
        a_i = 0;
        b_r = -2;
        b_i = 0;
        w_r = 0;
        w_i = -1;

        #1;
        $display("a = (%d + j%d), b = (%d + j%d), w = (%d + j%d) --> x1 = (%d + j%d), x2 = (%d + j%d)",
                 a_r, a_i, b_r, b_i, w_r, w_i, x1_r, x1_i, x2_r, x2_i);

        #2;

        // Exemplo com entradas do Exc 1
        // Passo 1 xo e x2
        $display("Exemplo com entradas do Exc 1 x(0)= 1 e x(2)=6");
        a_r = 1;
        a_i = 0;
        b_r = 6;
        b_i = 0;
        w_r = 1;
        w_i = 0;

        #1;
        $display("a = (%d + j%d), b = (%d + j%d), w = (%d + j%d) --> x1 = (%d + j%d), x2 = (%d + j%d)",
                 a_r, a_i, b_r, b_i, w_r, w_i, x1_r, x1_i, x2_r, x2_i);
        
        // Passo 1 x1 e x3
        $display("Exemplo com entradas do Exc 1 x(1)= 3 e x(2)=4");
        a_r = 3;
        a_i = 0;
        b_r = 4;
        b_i = 0;
        w_r = 1;
        w_i = 0;

        #1;
        $display("a = (%d + j%d), b = (%d + j%d), w = (%d + j%d) --> x1 = (%d + j%d), x2 = (%d + j%d)",
                 a_r, a_i, b_r, b_i, w_r, w_i, x1_r, x1_i, x2_r, x2_i);

        #5;
        $finish;

    end

endmodule