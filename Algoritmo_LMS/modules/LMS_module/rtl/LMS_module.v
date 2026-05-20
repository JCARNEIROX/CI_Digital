module LMS_module #(
    parameter integer WIDTH     = 8,
    parameter integer W_WIDTH   = 16,
    parameter integer ACC_WIDTH = 32,
    parameter integer LR_SHIFT  = 4
)(
    input wire clk,
    input wire rst,

    input wire valid_in,

    input wire signed [WIDTH-1:0] x_in,
    input wire signed [WIDTH-1:0] d_in,

    output reg done,
    output reg signed [ACC_WIDTH-1:0] y_out
);

    localparam S_IDLE      = 3'd0;
    localparam S_MULT      = 3'd1;
    localparam S_Y         = 3'd2;
    localparam S_E         = 3'd3;
    localparam S_DELTA     = 3'd4;
    localparam S_UPDATE    = 3'd5;

    reg [2:0] state;

    reg signed [W_WIDTH-1:0] w;
    reg signed [W_WIDTH-1:0] b;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] d_reg;

    reg signed [W_WIDTH+WIDTH-1:0] mult_wx_reg;
    reg signed [ACC_WIDTH-1:0] y_reg;
    reg signed [ACC_WIDTH-1:0] e_reg;

    reg signed [ACC_WIDTH+WIDTH-1:0] grad_w_reg;
    reg signed [ACC_WIDTH+WIDTH-1:0] delta_w_reg;
    reg signed [ACC_WIDTH-1:0] delta_b_reg;

    wire signed [ACC_WIDTH-1:0] mult_wx_ext;
    wire signed [ACC_WIDTH-1:0] b_ext;
    wire signed [ACC_WIDTH-1:0] d_ext;
    wire signed [ACC_WIDTH-1:0] w_ext;
    wire signed [ACC_WIDTH-1:0] b_ext_update;

    assign mult_wx_ext = {{(ACC_WIDTH-(W_WIDTH+WIDTH)){mult_wx_reg[W_WIDTH+WIDTH-1]}}, mult_wx_reg};
    assign b_ext       = {{(ACC_WIDTH-W_WIDTH){b[W_WIDTH-1]}}, b};

    assign d_ext = {{(ACC_WIDTH-WIDTH){d_reg[WIDTH-1]}}, d_reg};

    assign w_ext        = {{(ACC_WIDTH-W_WIDTH){w[W_WIDTH-1]}}, w};
    assign b_ext_update = {{(ACC_WIDTH-W_WIDTH){b[W_WIDTH-1]}}, b};

    wire signed [ACC_WIDTH-1:0] delta_w_acc;
    wire signed [ACC_WIDTH-1:0] w_next_full;
    wire signed [ACC_WIDTH-1:0] b_next_full;

    assign delta_w_acc = delta_w_reg[ACC_WIDTH-1:0];

    assign w_next_full = w_ext + delta_w_acc;
    assign b_next_full = b_ext_update + delta_b_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;

            w <= 0;
            b <= 0;

            x_reg <= 0;
            d_reg <= 0;

            mult_wx_reg <= 0;
            y_reg <= 0;
            e_reg <= 0;

            grad_w_reg <= 0;
            delta_w_reg <= 0;
            delta_b_reg <= 0;

            y_out <= 0;
            done <= 0;
        end else begin
            done <= 1'b0;

            case (state)

                S_IDLE: begin
                    if (valid_in) begin
                        x_reg <= x_in;
                        d_reg <= d_in;

                        state <= S_MULT;
                    end
                end

                S_MULT: begin
                    mult_wx_reg <= w * x_reg;

                    state <= S_Y;
                end

                S_Y: begin
                    y_reg <= mult_wx_ext + b_ext;

                    state <= S_E;
                end

                S_E: begin
                    e_reg <= d_ext - y_reg;

                    state <= S_DELTA;
                end

                S_DELTA: begin
                    grad_w_reg  <= e_reg * x_reg;
                    delta_w_reg <= (e_reg * x_reg) >>> LR_SHIFT;
                    delta_b_reg <= e_reg >>> LR_SHIFT;

                    state <= S_UPDATE;
                end

                S_UPDATE: begin
                    w <= w_next_full[W_WIDTH-1:0];
                    b <= b_next_full[W_WIDTH-1:0];

                    y_out <= y_reg;
                    done <= 1'b1;

                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule