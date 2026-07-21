module adder #(
    parameter int WIDTH     = 8
) (
    input  logic signed [WIDTH-1:0] a,
    input  logic signed [WIDTH-1:0] b,

    output logic signed [WIDTH-1:0] sum,
    output logic                    overflow
);

    // Valores brutos máximos e mínimos para WIDTH bits signed.
    localparam logic signed [WIDTH-1:0] max_value = {
        1'b0,
        {(WIDTH-1){1'b1}}
    };

    localparam logic signed [WIDTH-1:0] min_value = {
        1'b1,
        {(WIDTH-1){1'b0}}
    };

    logic signed [WIDTH:0] full_sum; // Soma com bit extra para detectar overflow.

    always_comb begin
        // Extensão de sinal antes da soma.
        full_sum =
            {a[WIDTH-1], a} +
            {b[WIDTH-1], b};

        overflow = 1'b0;

        if (full_sum > $signed({1'b0, max_value})) begin // Trunca no valor máximo (2^(WIDTH-1) - 1).
            sum      = max_value;
            overflow = 1'b1;
        end
        else if (full_sum < $signed({1'b1, min_value})) begin // Trunca no valor mínimo (-2^(WIDTH-1)).
            sum      = min_value;
            overflow = 1'b1;
        end
        else begin
            sum = full_sum[WIDTH-1:0];
        end
    end

endmodule