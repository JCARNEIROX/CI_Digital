module x3_curto(
    output reg [7:0] XPower,
    input [7:0] X,
    input clk
);
    reg [7:0] XPower1, XPower2;
    reg [7:0] X1, X2;

    always @(posedge clk) begin
        // Estágio 1
        X1 <= X;
        XPower1 <= X;

        // Estágio 2
        X2 <= X1;
        XPower2 <= XPower1 * X1;

        // Estágio 3
        XPower <= XPower2 * X2;
    end
endmodule