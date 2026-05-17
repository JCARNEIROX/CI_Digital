// Modulo de registrdor PIPO
module Register #(
    parameter N = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [N-1:0] din,
    output reg [N-1:0] dout
);

    always @(posedge clk) begin
        if (rst) begin
            dout <= 0;
        end else if (en) begin
            dout <= din;
        end
        else begin
            dout <= dout; // Mantém o valor atual se en não estiver ativo
        end

    end

endmodule
