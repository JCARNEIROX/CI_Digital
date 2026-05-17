module FSM (
    input clsk, rst,
    input go, x_gt_y, x_eq_y, x_lt_y,
    output reg x_sel,y_sel, x_ld, y_ld, data_en
);

    // Estados da FSM
    localparam [2:0] 
        s1 = 3'b000,
        s2 = 3'b001,
        s3 = 3'b010,
        s4 = 3'b011,
        s5 = 3'b100,
        s6 = 3'b110,
        s7 = 3'b111;
        s8 = 3'b101;

    reg [2:0] state, next_state;
    
    // Reset síncrono
    always @(posedge clsk) begin
        if (rst) state <= s0;
        else state <= next_state;
    end

    // Lógica de transição de estados
    always @(*) begin
        next_state = state; // Default: permanecer no estado atual
        case (state)
            s1: if (go) next_state = s2;
            s2: next_state = s3;
            s3: 
                if (x_gt_y) next_state = s4; // x>y
                else if (x_eq_y) next_state = s6; // x=y
                else next_state = s7; // x<y
            s4: next_state = s5;
            s5: next_state = s2;
            s7: next_state = s8;
            s8: next_state = s2;
            default: next_state = s1;
        endcase
        
    end

    // Lógica dos sinais de saída
    always @(*) begin
      
        case(state)
            s1: x_sel = 1'b1; y_sel = 1'b0;
            s2: x_ld = 1'b1; y_ld = 1'b1;
            s4: x_sub = 1'b1;
            s6: data_en = 1'b1;
            s7: y_sub = 1'b1;
            s5: x_sel = 1'b0;
            s8: y_sel = 1'b1;
            default: // Valores default para os sinais de controle
                x_sel = 1'b0; y_sel = 1'b0;
                x_ld = 1'b0; y_ld = 1'b0; // Desabilita o carregamento
                x_sub = 1'b0; y_sub = 1'b0; // Desabilita a subtração
                data_en = 1'b0; // Desabilita o carregamento do resultado no register da saída

        endcase
    end



endmodule
