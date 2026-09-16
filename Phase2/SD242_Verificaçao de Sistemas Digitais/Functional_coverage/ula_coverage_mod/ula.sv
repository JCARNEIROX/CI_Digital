
module ula (
    ula_if.DUT u_if
);

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

        case (u_if.opr)
            OP_ADD: begin
                // 64?bit zero?extended addition; carry out is at bit 32
                temp_result = {32'b0, u_if.a} + {32'b0, u_if.b};
                overflow    = temp_result[32];          // carry out
            end

            OP_SUB: begin
                // 64?bit zero?extended subtraction; borrow out is at bit 32
                temp_result = {32'b0, u_if.a} - {32'b0, u_if.b};
                overflow    = temp_result[32];          // borrow out
            end

            OP_MUL: begin
                // 32?bit × 32?bit unsigned multiplication ? 64?bit product
                temp_result = {32'b0, u_if.a} * {32'b0, u_if.b};
                overflow    = |temp_result[63:32];      // set if product > 32 bits
            end

            OP_DIV: begin
                if (u_if.b == 32'b0) begin
                    temp_result = 64'b0;
                    overflow    = 1'b1;                 // division by zero
                end else begin
                    temp_result = {32'b0, u_if.a / u_if.b}; // unsigned quotient
                    overflow    = 1'b0;
                end
            end

            OP_AND: begin
                temp_result = {32'b0, u_if.a & u_if.b};
                overflow    = 1'b0;
            end

            OP_OR: begin
                temp_result = {32'b0, u_if.a | u_if.b};
                overflow    = 1'b0;
            end

            OP_NOT: begin
                temp_result = {32'b0, ~u_if.a};         // bitwise NOT of a
                overflow    = 1'b0;
            end

            default: begin
                temp_result = 64'b0;
                overflow    = 1'b0;
            end
        endcase
    end

    // Sequential logic ? register results on clock edge
    always_ff @(posedge u_if.clk or negedge u_if.rst_n) begin
        if (!u_if.rst_n) begin
            u_if.result  <= 32'b0;
            u_if.carry_o <= 1'b0;
            u_if.zero    <= 1'b0;
        end else begin
            u_if.result  <= temp_result;
            u_if.carry_o <= overflow;            // overloaded as overflow/error
            u_if.zero    <= (temp_result[31:0] == 32'b0);
        end
    end

endmodule
