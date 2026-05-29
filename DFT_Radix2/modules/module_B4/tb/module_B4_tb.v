`timescale 1ns/1ns

module tb_module_B4;

    parameter WIDTH = 8;
    parameter N = 4;

    reg  signed [N*WIDTH-1:0] x_r;
    reg  signed [N*WIDTH-1:0] x_i;

    reg  signed [N*WIDTH-1:0] w_r;
    reg  signed [N*WIDTH-1:0] w_i;

    wire signed [N*WIDTH-1:0] xo_r;
    wire signed [N*WIDTH-1:0] xo_i;

    wire signed [WIDTH-1:0] X0_r, X0_i;
    wire signed [WIDTH-1:0] X1_r, X1_i;
    wire signed [WIDTH-1:0] X2_r, X2_i;
    wire signed [WIDTH-1:0] X3_r, X3_i;

    assign X0_r = xo_r[0*WIDTH +: WIDTH];
    assign X1_r = xo_r[1*WIDTH +: WIDTH];
    assign X2_r = xo_r[2*WIDTH +: WIDTH];
    assign X3_r = xo_r[3*WIDTH +: WIDTH];

    assign X0_i = xo_i[0*WIDTH +: WIDTH];
    assign X1_i = xo_i[1*WIDTH +: WIDTH];
    assign X2_i = xo_i[2*WIDTH +: WIDTH];
    assign X3_i = xo_i[3*WIDTH +: WIDTH];

    module_B4 #(
        .WIDTH(WIDTH),
        .N(N)
    ) dut (
        .xr_in(x_r),
        .xi_in(x_i),
        .Xr_out(xo_r),
        .Xi_out(xo_i),
        .Wr_in(w_r),
        .Wi_in(w_i)
    );

    initial begin

        // Entrada:
        // x[0] = 1
        // x[1] = 3
        // x[2] = 6
        // x[3] = 4
        //
        // Como x[0] fica nos bits menos significativos:
        x_r = {8'sd4, 8'sd6, 8'sd3, 8'sd1};
        x_i = {8'sd0, 8'sd0, 8'sd0, 8'sd0};

        // Twiddles:
        // W4^0 = 1 + j0
        // W4^1 = 0 - j1
        //
        // w[0] fica nos bits menos significativos.
        w_r = {8'sd0, 8'sd0, 8'sd0, 8'sd1};
        w_i = {8'sd0, 8'sd0, -8'sd1, 8'sd0};

        #1;

        $display("X0 = %d + j%d", X0_r, X0_i);
        $display("X1 = %d + j%d", X1_r, X1_i);
        $display("X2 = %d + j%d", X2_r, X2_i);
        $display("X3 = %d + j%d", X3_r, X3_i);

        if (
            X0_r == 8'sd14  && X0_i == 8'sd0  &&
            X1_r == -8'sd5  && X1_i == 8'sd1  &&
            X2_r == 8'sd0   && X2_i == 8'sd0  &&
            X3_r == -8'sd5  && X3_i == -8'sd1
        ) begin
            $display("TESTE OK");
        end else begin
            $display("TESTE FALHOU");
        end

        #5;
        $finish;

    end

endmodule