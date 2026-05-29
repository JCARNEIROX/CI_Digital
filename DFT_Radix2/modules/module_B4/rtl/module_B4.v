module module_B4 #(
    parameter WIDTH = 8,
    parameter N = 4
)(
    input signed [N*WIDTH-1:0] xr_in, // X_in com valores de x0,x1,x2x..xN-1, onde cada valor tem Width bits
    input signed [N*WIDTH-1:0] xi_in, // X_in com valores de x0,x1,x2x..xN-1, onde cada valor tem Width bits
    output signed [N*WIDTH-1:0] Xr_out,  // X_out com valores de X0,X1,X2x..XN-1, onde cada valor tem Width bits
    output signed [N*WIDTH-1:0] Xi_out,  // X_out com valores de X0,X1,X2x..XN-1, onde cada valor tem Width bits
    input signed [N*WIDTH-1:0] Wr_in, // W com valores de W0,W1,W2x..WN-1, onde cada valor tem Width bits
    input signed [N*WIDTH-1:0] Wi_in, // W com valores de W0,W1,W2x..WN-1, onde cada valor tem Width bits
);

    // Separação dos valores x1, x2, ..., xN-1 de x_in
    wire signed [WIDTH-1:0] xr [0:N-1]; 
    wire signed [WIDTH-1:0] xi [0:N-1];
    wire signed [WIDTH-1:0] wr [0:N-1];
    wire signed [WIDTH-1:0] wi [0:N-1];
    wire signed [WIDTH-1:0] Areal [0:2*N-1];
    wire signed [WIDTH-1:0] Aimag [0:2*N-1];


    // Distribuição dos valores em variáveis individuais para facilitar o acesso
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : input_split
            assign xr[i] = xr_in[(i+1)*WIDTH-1:i*WIDTH]; // Extrai o valor de x_i de x_in
            assign xi[i] = xi_in[(i+1)*WIDTH-1:i*WIDTH]; // Extrai o valor de x_i de x_in
            assign wr[i] = Wr_in[(i+1)*WIDTH-1:i*WIDTH];
            assign wi[i] = Wi_in[(i+1)*WIDTH-1:i*WIDTH];
        end
    endgenerate

    // Borboletas da primeira etapa
    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly1_stage1 (
        .A({xr[0], xi[0]}), // A é o par (xr[0], xi[0])
        .B({xr[2], xi[2]}), // B é o par (xr[2], xi[2])
        .W({wr[0], wi[0]}), // W é o par (wr[0], wi[0])
        .X0({Areal[0], Aimag[0]}), // X0 é o par (Xr_out[0], Xi_out[0])
        .X1({Areal[1], Aimag[1]}), // X1 é o par (Xr_out[2], Xi_out[2])
    );
    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly2_stage1 (
        .A({xr[1], xi[1]}), // A é o par (xr[1], xi[1])
        .B({xr[3], xi[3]}), // B é o par (xr[3], xi[3])
        .W({wr[0], wi[0]}), // W é o par (wr[0], wi[0])
        .X0({Areal[2], Aimag[2]}), // X0 é o par (Xr_out[1], Xi_out[1])
        .X1({Areal[3], Aimag[3]}), // X1 é o par (Xr_out[3], Xi_out[3])
    );

    // Borboletas da segunda etapa
    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly1_stage2 (
        .A({Areal[0], Aimag[0]}), // A é o par (Areal[0], Aimag[0])
        .B({Areal[2], Aimag[2]}), // B é o par (Areal[2], Aimag[2])
        .W({wr[1], wi[1]}), // W é o par (wr[1], wi[1])
        .X0({Xr_out[0], Xi_out[0]}), // X0 é o par (Xr_out[0], Xi_out[0])
        .X1({Xr_out[2], Xi_out[2]}), // X1 é o par (Xr_out[2], Xi_out[2])
    );
    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly2_stage2 (
        .A({Areal[1], Aimag[1]}), // A é o par (Areal[1], Aimag[1])
        .B({Areal[3], Aimag[3]}), // B é o par (Areal[3], Aimag[3])
        .W({wr[1], wi[1]}), // W é o par (wr[1], wi[1])
        .X0({Xr_out[1], Xi_out[1]}), // X0 é o par (Xr_out[1], Xi_out[1])
        .X1({Xr_out[3], Xi_out[3]}), // X1 é o par (Xr_out[3], Xi_out[3])
    );





    // Sua lógica aqui

endmodule
