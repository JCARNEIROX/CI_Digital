module FSM (
    input clk, rst,
    input go, x_gt_y, x_eq_y, x_lt_y,
    output reg x_sel,y_sel, x_ld, y_ld, data_en,
    output reg x_sub, y_sub
);

    // Estados da FSM
    parameter[2:0]
        s0 = 3'b000,
        s1 = 3'b001,
        s2 = 3'b010,
        s3 = 3'b011,
        s4 = 3'b100,
        s5 = 3'b101,
        s6 = 3'b110,
        s7 = 3'b111;

    reg [2:0] state, next_state;
    
    // Reset síncrono
    always @(posedge clk) begin
        if (rst) state <= s0;
        else state <= next_state;
    end

    // Lógica de transição de estados
    always @(*) begin
        next_state = state; // Default: permanecer no estado atual
        case (state)
            s0: if (go) next_state = s1;
            s1: next_state = s2;
            s2: 
                if (x_gt_y) next_state = s3; // x>y
                else if (x_eq_y) next_state = s5; // x=y
                else if (x_lt_y) next_state = s6; // x<y
                else next_state = s2; // x<y
            s3: next_state = s4;
            s4: next_state = s1;
            s5: next_state = s5;
            s6: next_state = s7; // Estado de resultado pronto
            s7: next_state = s1;            
            default: next_state = s0;
        endcase
        
    end

    // Lógica dos sinais de saída
    always @(*) begin
        
        // Valores padrão para evitar latch
        x_sel   = 1'b0;
        y_sel   = 1'b0;
        x_ld    = 1'b0;
        y_ld    = 1'b0;
        x_sub   = 1'b0;
        y_sub   = 1'b0;
        data_en = 1'b0;

        if (!rst) begin
            case(state)
            s0: begin
                x_sel = 1'b1; 
                y_sel = 1'b0;
            end
            s1: begin
                x_ld = 1'b1; 
                y_ld = 1'b1;
            end
            s2: ; // Nenhuma ação específica para o estado de comparação
            s3: x_sub = 1'b1;
            s4: x_sel = 1'b0;
            s5: data_en = 1'b1;
            s6: y_sub = 1'b1;
            s7: y_sel = 1'b1;
        endcase
            
        end
        
    end



endmodule
