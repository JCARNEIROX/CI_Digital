module gcd_b #(
    parameter WIDTH = 8
)(
    input clk, rst, go,
    input [WIDTH-1:0] x, y,
    output [WIDTH-1:0] result,
    output done
);

    wire x_sel, y_sel;
    wire x_ld, y_ld;
    wire x_sub, y_sub;
    wire data_en;

    wire x_gt_y, x_eq_y, x_lt_y;

    // Control Path
    FSM fsm_inst (
        .clk(clk),
        .rst(rst),
        .go(go),

        .x_gt_y(x_gt_y),
        .x_eq_y(x_eq_y),
        .x_lt_y(x_lt_y),

        .x_sel(x_sel),
        .y_sel(y_sel),
        .x_ld(x_ld),
        .y_ld(y_ld),
        .data_en(data_en),

        .x_sub(x_sub),
        .y_sub(y_sub)
    );

    // Data Path
    data_path #(
        .WIDTH(WIDTH)
    ) data_path_inst (
        .clk(clk),
        .rst(rst),

        .x(x),
        .y(y),

        .x_sel(x_sel),
        .y_sel(y_sel),
        .x_ld(x_ld),
        .y_ld(y_ld),
        .x_sub(x_sub),
        .y_sub(y_sub),
        .data_en(data_en),

        .x_gt_y(x_gt_y),
        .x_eq_y(x_eq_y),
        .x_lt_y(x_lt_y),

        .result(result)
    );

    assign done = data_en;

endmodule