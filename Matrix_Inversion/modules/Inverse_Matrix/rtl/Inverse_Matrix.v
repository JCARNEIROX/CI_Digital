module Inverse_Matrix #(
    parameter N = 4,
    parameter N_BITS = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [N*N*N_BITS-1:0] A,
    output reg signed [N*N*N_BITS-1:0] A_inv,
    output reg done
);

    localparam MAT_BITS = N*N*N_BITS;
    localparam VEC_BITS = N*N_BITS;

    wire signed [MAT_BITS-1:0] L_out;
    wire signed [MAT_BITS-1:0] U_out;

    reg signed [VEC_BITS-1:0] b;
    wire signed [VEC_BITS-1:0] y_out;
    reg signed [VEC_BITS-1:0] y_reg;
    wire signed [VEC_BITS-1:0] x_out;

    reg start_lu;
    reg start_forward;
    reg start_backward;

    wire done_lu;
    wire done_forward;
    wire done_backward;

    reg [$clog2(N)-1:0] col;

    integer i;

    localparam IDLE           = 4'd0,
               START_LU       = 4'd1,
               WAIT_LU        = 4'd2,
               PREPARE_B      = 4'd3,
               START_FORWARD  = 4'd4,
               WAIT_FORWARD   = 4'd5,
               START_BACKWARD = 4'd6,
               WAIT_BACKWARD  = 4'd7,
               STORE_COLUMN   = 4'd8,
               DONE_STATE     = 4'd9;

    reg [3:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 1'b0;
            A_inv <= {MAT_BITS{1'b0}};
            b <= {VEC_BITS{1'b0}};
            y_reg <= {VEC_BITS{1'b0}};
            col <= 0;

            start_lu <= 1'b0;
            start_forward <= 1'b0;
            start_backward <= 1'b0;
        end else begin

            // Por padrão, os starts ficam em zero.
            // Eles viram pulso de 1 ciclo nos estados START_...
            start_lu <= 1'b0;
            start_forward <= 1'b0;
            start_backward <= 1'b0;

            case (state)

                IDLE: begin
                    done <= 1'b0;

                    if (start) begin
                        A_inv <= {MAT_BITS{1'b0}};
                        col <= 0;
                        state <= START_LU;
                    end
                end

                START_LU: begin
                    start_lu <= 1'b1;
                    state <= WAIT_LU;
                end

                WAIT_LU: begin
                    if (done_lu) begin
                        state <= PREPARE_B;
                    end
                end

                PREPARE_B: begin
                    for (i = 0; i < N; i = i + 1) begin
                        b[i*N_BITS +: N_BITS] <= (i == col) ? 32'sd1 : 32'sd0;
                    end

                    state <= START_FORWARD;
                end

                START_FORWARD: begin
                    start_forward <= 1'b1;
                    state <= WAIT_FORWARD;
                end

                WAIT_FORWARD: begin
                    if (done_forward) begin
                        y_reg <= y_out;
                        state <= START_BACKWARD;
                    end
                end

                START_BACKWARD: begin
                    start_backward <= 1'b1;
                    state <= WAIT_BACKWARD;
                end

                WAIT_BACKWARD: begin
                    if (done_backward) begin
                        state <= STORE_COLUMN;
                    end
                end

                STORE_COLUMN: begin
                    for (i = 0; i < N; i = i + 1) begin
                        A_inv[(i*N + col)*N_BITS +: N_BITS] <= x_out[i*N_BITS +: N_BITS];
                    end

                    if (col == N-1) begin
                        state <= DONE_STATE;
                    end else begin
                        col <= col + 1'b1;
                        state <= PREPARE_B;
                    end
                end

                DONE_STATE: begin
                    done <= 1'b1;

                    if (!start) begin
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

    LU_decomposition_4x4 lu_decomp (
        .clk(clk),
        .rst(rst),
        .start(start_lu),
        .A_in(A),
        .done(done_lu),
        .L_out(L_out),
        .U_out(U_out)
    );

    ForwardSub4x4 forward_sub (
        .clk(clk),
        .rst(rst),
        .start(start_forward),
        .L_in(L_out),
        .b_in(b),
        .done(done_forward),
        .y_out(y_out)
    );

    BackwardSub4x4 backward_sub (
        .clk(clk),
        .rst(rst),
        .start(start_backward),
        .U_in(U_out),
        .y_in(y_reg),
        .done(done_backward),
        .x_out(x_out)
    );

endmodule