// Code your design here
module radix2_2In #(
    parameter integer WIDTH = 8
)(
    input signed [2*WIDTH-1:0] A, // A value com A[0] real e A[1] imaginário com Width bits
    input signed [2*WIDTH-1:0] B,  // B value com B[0] real e B[1] imaginário com Width bits
    input signed [2*WIDTH-1:0] W, // W value com W[0] real e W[1] imaginário com Width bits
    
    output signed [2*WIDTH-1:0] X0, // X1 value com X1[0] real e X1[1] imaginário com Width bits
    output signed [2*WIDTH-1:0] X1 // X2 value com X2[0] real e X2[1] imaginário com Width bits
);
    //Sepração dos componentes real e imaginário de A, B e W
    wire signed [WIDTH-1:0] A_real = A[WIDTH-1:0];
    wire signed [WIDTH-1:0] A_imag = A[2*WIDTH-1:WIDTH];

    wire signed [WIDTH-1:0] B_real = B[WIDTH-1:0];
    wire signed [WIDTH-1:0] B_imag = B[2*WIDTH-1:WIDTH];

    wire signed [WIDTH-1:0] W_real = W[WIDTH-1:0];
    wire signed [WIDTH-1:0] W_imag = W[2*WIDTH-1:WIDTH];

    // Variáveis para armazenar os resultados intermediários de B*W
    wire signed [2*WIDTH-1:0] bw; // bw[0] real e bw[1] imaginário com Width bits cada

    // Cálculo de B*W
    assign bw[WIDTH-1:0] = (B_real * W_real) - (B_imag * W_imag); // Parte real de B*W
    assign bw[2*WIDTH-1:WIDTH] = (B_real * W_imag) + (B_imag * W_real); // Parte imaginária de B*W

    // Cálculo de X1 e X2
    assign X0[WIDTH-1:0] = A_real + bw[WIDTH-1:0]; // Parte real de X0
    assign X0[2*WIDTH-1:WIDTH] = A_imag + bw[2*WIDTH-1:WIDTH]; // Parte imaginária de X0
    assign X1[WIDTH-1:0] = A_real - bw[WIDTH-1:0]; // Parte real de X1
    assign X1[2*WIDTH-1:WIDTH] = A_imag - bw[2*WIDTH-1:WIDTH]; // Parte imaginária de X1

endmodule