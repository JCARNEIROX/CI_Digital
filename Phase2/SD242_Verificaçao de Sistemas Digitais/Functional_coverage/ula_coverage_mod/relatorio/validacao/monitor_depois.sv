`timescale 1ns/1ps
module timing_tb;
    logic clk = 0;
    logic rst_n = 0;
    logic [31:0] a, b;
    logic [2:0] opr;
    logic [63:0] result;
    logic carry_o, zero;
    typedef struct packed {
        logic [31:0] a, b;
        logic [2:0] opr;
        logic [63:0] result;
        logic carry_o, zero;
    } ula_item;
    integer errors = 0;
    integer samples = 0;
    logic [9:0] seen = 0;
    always #5 clk = ~clk;
    initial begin
        #7;
        if (a !== 32'bx || b !== 32'bx || opr !== 3'bx) $fatal(1, "Driver wrote during reset");
        #15 rst_n = 1;
    end
        // Operation codes (opr width must be 3 bits)
        localparam OP_ADD = 3'b000,
                OP_SUB = 3'b001,
                OP_MUL = 3'b010,
                OP_DIV = 3'b011,
                OP_AND = 3'b100,
                OP_OR  = 3'b101,
                OP_NOT = 3'b110;

        // Internal signals
        logic [63:0] temp_result;   // 64?bit intermediate for all operations
        logic        overflow;      // carry/borrow/overflow/error flag

        // Combinational logic ? compute result and overflow
        always_comb begin
            temp_result = 64'b0;
            overflow    = 1'b0;

            case (opr)
                OP_ADD: begin
                    // 64?bit zero?extended addition; carry out is at bit 32
                    temp_result = {32'b0, a} + {32'b0, b};
                    overflow    = temp_result[32];          // carry out
                end

                OP_SUB: begin
                    // 64?bit zero?extended subtraction; borrow out is at bit 32
                    temp_result = {32'b0, a} - {32'b0, b};
                    overflow    = temp_result[32];          // borrow out
                end

                OP_MUL: begin
                    // 32?bit × 32?bit unsigned multiplication ? 64?bit product
                    temp_result = {32'b0, a} * {32'b0, b};
                    overflow    = |temp_result[63:32];      // set if product > 32 bits
                end

                OP_DIV: begin
                    if (b == 32'b0) begin
                        temp_result = 64'b0;
                        overflow    = 1'b1;                 // division by zero
                    end else begin
                        temp_result = {32'b0, a / b}; // unsigned quotient
                        overflow    = 1'b0;
                    end
                end

                OP_AND: begin
                    temp_result = {32'b0, a & b};
                    overflow    = 1'b0;
                end

                OP_OR: begin
                    temp_result = {32'b0, a | b};
                    overflow    = 1'b0;
                end

                OP_NOT: begin
                    temp_result = {32'b0, ~a};         // bitwise NOT of a
                    overflow    = 1'b0;
                end

                default: begin
                    temp_result = 64'b0;
                    overflow    = 1'b0;
                end
            endcase
        end

        // Sequential logic ? register results on clock edge
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                result  <= 32'b0;
                carry_o <= 1'b0;
                zero    <= 1'b0;
            end else begin
                result  <= temp_result;
                carry_o <= overflow;            // overloaded as overflow/error
                zero    <= (temp_result == 64'b0);
            end
        end

        task automatic drive_transaction(ula_item i_trans);
            // So aplica entradas em uma borda com reset desativado e conhecido.
            do begin
                @(posedge clk);
            end while (rst_n !== 1'b1);
            a <= i_trans.a;
            b <= i_trans.b;
            opr <= i_trans.opr;

            // Aguarda um ciclo para o DUT processar
            @(posedge clk);
        endtask
    task check_sample(input ula_item t);
        samples++;
        case ({t.opr,t.a,t.b})
            67'h00000000100000002: begin seen[0] = 1'b1; if (t.result !== 64'h0000000000000003 || t.carry_o !== 1'b0 || t.zero !== 1'b0) errors++; end
            67'h0ffffffff00000001: begin seen[1] = 1'b1; if (t.result !== 64'h0000000100000000 || t.carry_o !== 1'b1 || t.zero !== 1'b0) errors++; end
            67'h10000000000000001: begin seen[2] = 1'b1; if (t.result !== 64'hffffffffffffffff || t.carry_o !== 1'b1 || t.zero !== 1'b0) errors++; end
            67'h10000000100000001: begin seen[3] = 1'b1; if (t.result !== 64'h0000000000000000 || t.carry_o !== 1'b0 || t.zero !== 1'b1) errors++; end
            67'h20001000000010000: begin seen[4] = 1'b1; if (t.result !== 64'h0000000100000000 || t.carry_o !== 1'b1 || t.zero !== 1'b0) errors++; end
            67'h30000000100000000: begin seen[5] = 1'b1; if (t.result !== 64'h0000000000000000 || t.carry_o !== 1'b1 || t.zero !== 1'b1) errors++; end
            67'h30000000a00000002: begin seen[6] = 1'b1; if (t.result !== 64'h0000000000000005 || t.carry_o !== 1'b0 || t.zero !== 1'b0) errors++; end
            67'h4aaaaaaaa55555555: begin seen[7] = 1'b1; if (t.result !== 64'h0000000000000000 || t.carry_o !== 1'b0 || t.zero !== 1'b1) errors++; end
            67'h5aaaaaaaa55555555: begin seen[8] = 1'b1; if (t.result !== 64'h00000000ffffffff || t.carry_o !== 1'b0 || t.zero !== 1'b0) errors++; end
            67'h6ffffffff00000000: begin seen[9] = 1'b1; if (t.result !== 64'h0000000000000000 || t.carry_o !== 1'b0 || t.zero !== 1'b1) errors++; end
            default: errors++;
        endcase
    endtask

        task monitor_task;
            ula_item trans;
            forever begin : sample
                @(posedge clk or negedge rst_n);
                if (rst_n !== 1'b1) disable sample;

                // Antes do primeiro estimulo, as entradas ainda podem estar em X.
                if ($isunknown(opr) || $isunknown(a) || $isunknown(b)) disable sample;

                // Captura as mesmas entradas que o DUT usa nesta borda,
                // antes das atribuicoes nao bloqueantes do driver.
                trans = 'x;
                trans.opr     = opr;
                trans.a       = a;
                trans.b       = b;

                // As saidas registradas ja estao estaveis na borda de descida.
                // Se houver reset durante a espera, descarta esta amostra.
                @(negedge clk or negedge rst_n);
                if (rst_n !== 1'b1) disable sample;
                trans.result  = result;
                trans.carry_o = carry_o;
                trans.zero    = zero;
                check_sample(trans);
            end
        endtask

    initial monitor_task();

    initial begin
        ula_item req;
        req.opr = 3'd0; req.a = 32'h00000001; req.b = 32'h00000002; drive_transaction(req);
        req.opr = 3'd0; req.a = 32'hffffffff; req.b = 32'h00000001; drive_transaction(req);
        req.opr = 3'd1; req.a = 32'h00000000; req.b = 32'h00000001; drive_transaction(req);
        req.opr = 3'd1; req.a = 32'h00000001; req.b = 32'h00000001; drive_transaction(req);
        req.opr = 3'd2; req.a = 32'h00010000; req.b = 32'h00010000; drive_transaction(req);
        req.opr = 3'd3; req.a = 32'h00000001; req.b = 32'h00000000; drive_transaction(req);
        req.opr = 3'd3; req.a = 32'h0000000a; req.b = 32'h00000002; drive_transaction(req);
        req.opr = 3'd4; req.a = 32'haaaaaaaa; req.b = 32'h55555555; drive_transaction(req);
        req.opr = 3'd5; req.a = 32'haaaaaaaa; req.b = 32'h55555555; drive_transaction(req);
        req.opr = 3'd6; req.a = 32'hffffffff; req.b = 32'h00000000; drive_transaction(req);
        // Reset between the capture of inputs and the output sample.
        #1 rst_n = 0;
        #1 rst_n = 1;
        #20;
        $display("samples=%0d errors=%0d seen=%b", samples, errors, seen);
        if (errors != 0 || seen !== 10'b1111111111) $fatal(1, "Timing regression failed");
        $finish;
    end
    initial begin #1000; $fatal(1, "Timeout"); end
endmodule
