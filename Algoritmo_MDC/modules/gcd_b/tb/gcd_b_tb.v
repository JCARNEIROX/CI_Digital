`timescale 1ns/1ns

module tb_gcd_b;

    parameter WIDTH = 8;

    reg clk, rst, go;
    reg [WIDTH-1:0] a, b;
    wire [WIDTH-1:0] result;
    wire done;

    integer timeout_count;

    gcd_b #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .go(go),
        .x(a),
        .y(b),
        .result(result),
        .done(done)
    );

    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // período = 10 ns
    end

    // Teste
    initial begin
        $dumpfile("gcd_b_tb.vcd");
        $dumpvars(0, tb_gcd_b);

        $monitor("Time: %0t | rst: %b | go: %b | a: %d | b: %d | result: %d | done: %b", 
                 $time, rst, go, a, b, result, done);

        // Inicialização
        rst = 1;
        go = 0;
        a = 0;
        b = 0;
        timeout_count = 0;

        // Mantém reset por alguns ciclos
        repeat (2) @(posedge clk);

        // Desativa reset
        @(negedge clk);
        rst = 0;

        // Aplica entradas antes de ativar go
        @(negedge clk);
        a = 8'd48;
        b = 8'd18;

        // Pulso de go por 1 ciclo de clock
        @(negedge clk);
        go = 1;

        @(negedge clk);
        go = 0;

        // Espera done com timeout
        while ((done !== 1'b1) && (timeout_count < 100)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (done === 1'b1) begin
            $display("Resultado: MDC(%d, %d) = %d", a, b, result);
        end else begin
            $display("ERRO: timeout. O sinal done nao foi ativado.");
        end

        $finish;
    end

endmodule