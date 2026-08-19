module module_B4 #(
    parameter WIDTH = 8,
    parameter N = 4
)(
    input  signed [N*WIDTH-1:0] xr_in,
    input  signed [N*WIDTH-1:0] xi_in,

    output signed [N*WIDTH-1:0] Xr_out,
    output signed [N*WIDTH-1:0] Xi_out,

    input  signed [N*WIDTH-1:0] Wr_in,
    input  signed [N*WIDTH-1:0] Wi_in
);

    wire signed [WIDTH-1:0] xr [0:N-1];
    wire signed [WIDTH-1:0] xi [0:N-1];

    wire signed [WIDTH-1:0] wr [0:N-1];
    wire signed [WIDTH-1:0] wi [0:N-1];

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : input_split
            assign xr[i] = xr_in[(i+1)*WIDTH-1:i*WIDTH];
            assign xi[i] = xi_in[(i+1)*WIDTH-1:i*WIDTH];

            assign wr[i] = Wr_in[(i+1)*WIDTH-1:i*WIDTH];
            assign wi[i] = Wi_in[(i+1)*WIDTH-1:i*WIDTH];
        end
    endgenerate

    // Saídas intermediárias da etapa 1
    wire signed [2*WIDTH-1:0] S0;
    wire signed [2*WIDTH-1:0] S1;
    wire signed [2*WIDTH-1:0] S2;
    wire signed [2*WIDTH-1:0] S3;

    // Saídas finais complexas
    wire signed [2*WIDTH-1:0] X0_c;
    wire signed [2*WIDTH-1:0] X1_c;
    wire signed [2*WIDTH-1:0] X2_c;
    wire signed [2*WIDTH-1:0] X3_c;

    // ------------------------------------------------------------
    // Etapa 1
    // x0 com x2 usando W4^0
    // x1 com x3 usando W4^0
    // ------------------------------------------------------------

    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly1_stage1 (
        .A  ({xi[0], xr[0]}),
        .B  ({xi[2], xr[2]}),
        .W  ({wi[0], wr[0]}),
        .X0 (S0),
        .X1 (S1)
    );

    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly2_stage1 (
        .A  ({xi[1], xr[1]}),
        .B  ({xi[3], xr[3]}),
        .W  ({wi[0], wr[0]}),
        .X0 (S2),
        .X1 (S3)
    );

    // ------------------------------------------------------------
    // Etapa 2
    // S0 com S2 usando W4^0 -> X0 e X2
    // S1 com S3 usando W4^1 -> X1 e X3
    // ------------------------------------------------------------

    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly1_stage2 (
        .A  (S0),
        .B  (S2),
        .W  ({wi[0], wr[0]}),
        .X0 (X0_c),
        .X1 (X2_c)
    );

    radix2_2In #(
        .WIDTH(WIDTH)
    ) butterfly2_stage2 (
        .A  (S1),
        .B  (S3),
        .W  ({wi[1], wr[1]}),
        .X0 (X1_c),
        .X1 (X3_c)
    );

    // ------------------------------------------------------------
    // Separação das saídas finais
    //
    // Como o padrão interno é:
    // [WIDTH-1:0]       = real
    // [2*WIDTH-1:WIDTH] = imaginário
    // ------------------------------------------------------------

    assign Xr_out[(0+1)*WIDTH-1:0*WIDTH] = X0_c[WIDTH-1:0];
    assign Xi_out[(0+1)*WIDTH-1:0*WIDTH] = X0_c[2*WIDTH-1:WIDTH];

    assign Xr_out[(1+1)*WIDTH-1:1*WIDTH] = X1_c[WIDTH-1:0];
    assign Xi_out[(1+1)*WIDTH-1:1*WIDTH] = X1_c[2*WIDTH-1:WIDTH];

    assign Xr_out[(2+1)*WIDTH-1:2*WIDTH] = X2_c[WIDTH-1:0];
    assign Xi_out[(2+1)*WIDTH-1:2*WIDTH] = X2_c[2*WIDTH-1:WIDTH];

    assign Xr_out[(3+1)*WIDTH-1:3*WIDTH] = X3_c[WIDTH-1:0];
    assign Xi_out[(3+1)*WIDTH-1:3*WIDTH] = X3_c[2*WIDTH-1:WIDTH];

endmodule