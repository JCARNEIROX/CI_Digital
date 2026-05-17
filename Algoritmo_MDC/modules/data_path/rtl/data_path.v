module data_path #(
    parameter WIDTH = 8
)(
    input clk, rst, // Controles
    input [WIDTH-1:0] x, y, // Dados de entrada
    input x_sel, y_sel,x_ld, y_ld, x_sub, y_sub, data_en, // Sinais de controle
    output x_gt_y, x_eq_y, x_lt_y, // Sinais de comparação
    output reg [WIDTH-1:0] result // Resultado final
);

    // Fios para conexão interna
    wire [WIDTH-1:0] mux_x,mux_y;
    wire [WIDTH-1:0] x_reg, y_reg;
    wire [WIDTH-1:0] sub_x, sub_y;
    wire [WIDTH-1:0] eq_out;

    // Conexão estrutural dos submodulos
    // Mux de seleção dos operandos para os registradores
    Mux_2x1 #(.N(WIDTH)) mux_x_inst (
        .a(sub_x), .b(x), .sel(x_sel), .out(mux_x)
    );
    Mux_2x1 #(.N(WIDTH)) mux_y_inst (
        .a(y), .b(sub_y), .sel(y_sel), .out(mux_y)
    );
    // Registradores intermediários
    Register #(.N(WIDTH)) x_reg_inst (
        .clk(clk), .rst(rst), .en(x_ld), .din(mux_x), .dout(x_reg)
    );
    Register #(.N(WIDTH)) y_reg_inst (
        .clk(clk), .rst(rst), .en(y_ld), .din(mux_y), .dout(y_reg)
    );
    Comparator #(.N(WIDTH)) comparator_inst (
        .x(x_reg), .y(y_reg), .x_eq_y(x_eq_y), .x_gt_y(x_gt_y), .x_lt_y(x_lt_y), .eq_out(eq_out)
    );
    // Subtratores
    Subtractor #(.WIDTH(WIDTH)) sub_x_inst (
        .x(x_reg), .y(y_reg), .Bin(1'b0), .en(x_sub), .D(sub_x), .Bout()
    );
    Subtractor #(.WIDTH(WIDTH)) sub_y_inst (
        .x(y_reg), .y(x_reg), .Bin(1'b0), .en(y_sub), .D(sub_y), .Bout()
    );
    // Registrador de resultado final
    Register #(.N(WIDTH)) result_reg_inst (
        .clk(data_en), .rst(rst), .en(x_eq_y), .din(eq_out), .dout(result)
    );


endmodule
