module Comparator #(
    parameter N = 8
)(
    input wire [N-1:0] x,
    input wire [N-1:0] y,
    output wire [N-1:0] eq_out,
    output wire x_eq_y,
    output wire x_gt_y,
    output wire x_lt_y
);

    // Sua lógica aqui
    if (x==y) begin
        assign x_eq_y = 1'b1; // ou y, ambos são iguais
        assign eq_out = x; // ou y, ambos são iguais
    end 
    assign x_gt_y = (x > y) ? 1'b1 : 1'b0; // x>y, x_gt_y = 1 e x_lt_y = 0
    assign x_lt_y = (x < y) ? 1'b1 : 1'b0; // x<y, x_gt_y = 0 e x_lt_y = 1

endmodule
