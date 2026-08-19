module FSM (
    input clk, rst,
    input go, x_gt_y, x_eq_y, x_lt_y,
    output reg x_sel, y_sel,
    output reg x_ld, y_ld, data_en,
    output reg x_sub, y_sub
);

    parameter [2:0]
        s0 = 3'b000, // IDLE
        s1 = 3'b001, // LOAD
        s2 = 3'b010, // COMPARE
        s3 = 3'b011, // SUB_X
        s4 = 3'b100, // SUB_Y
        s5 = 3'b101; // DONE

    reg [2:0] state, next_state;
    
    // Registrador de estado
    always @(posedge clk) begin
        if (rst)
            state <= s0;
        else
            state <= next_state;
    end

    // Lógica de transição de estados
    always @(*) begin
        next_state = state;

        case (state)
            s0: begin
                if (go)
                    next_state = s1;
            end

            s1: begin
                next_state = s2;
            end

            s2: begin
                if (x_eq_y)
                    next_state = s5;
                else if (x_gt_y)
                    next_state = s3;
                else if (x_lt_y)
                    next_state = s4;
                else
                    next_state = s2;
            end

            s3: begin
                next_state = s2;
            end

            s4: begin
                next_state = s2;
            end

            s5: begin
                next_state = s5;
            end

            default: begin
                next_state = s0;
            end
        endcase
    end

    // Lógica dos sinais de saída
    always @(*) begin
        
        // Valores padrão
        x_sel   = 1'b0;
        y_sel   = 1'b0;
        x_ld    = 1'b0;
        y_ld    = 1'b0;
        x_sub   = 1'b0;
        y_sub   = 1'b0;
        data_en = 1'b0;

        if (!rst) begin
            case (state)
                s0: begin
                    // IDLE: tudo desligado
                end

                s1: begin
                    // Carrega entradas externas x e y nos registradores
                    x_sel = 1'b1; // mux_x seleciona x externo
                    y_sel = 1'b0; // mux_y seleciona y externo
                    x_ld  = 1'b1;
                    y_ld  = 1'b1;
                end

                s2: begin
                    // Apenas compara x_reg e y_reg
                end

                s3: begin
                    // x_reg recebe x_reg - y_reg
                    x_sel = 1'b0; // mux_x seleciona sub_x
                    x_sub = 1'b1;
                    x_ld  = 1'b1;
                end

                s4: begin
                    // y_reg recebe y_reg - x_reg
                    y_sel = 1'b1; // mux_y seleciona sub_y
                    y_sub = 1'b1;
                    y_ld  = 1'b1;
                end

                s5: begin
                    // Resultado pronto
                    data_en = 1'b1;
                end

                default: begin
                    // mantém valores padrão
                end
            endcase
        end
    end

endmodule