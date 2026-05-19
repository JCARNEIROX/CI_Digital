module LMS_module #(parameter lr = 0.5, 
parameter N = 16, parameter WIDTH = 8, parameter REG = 16
)(
    input wire clk,
    input wire rst,
    input wire signed [15:0] x, // Entrada
    input wire signed [15:0] d, // Saída desejada
    output reg signed [15:0] y, // Saída do modelo
    output reg signed [15:0] e  // Erro;
);

    // Sua lógica aqui

endmodule
