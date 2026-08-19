`timescale 1ns/1ns

module tb_gcd_b;

    parameter WIDTH = 8;
    parameter MAX_CYCLES = 100;

    reg clk, rst, go;
    reg [WIDTH-1:0] a, b;

    wire [WIDTH-1:0] result;
    wire done;

    integer timeout_count;
    integer errors;

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

    // Clock de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task reset_dut;
        begin
            @(negedge clk);
            rst = 1;
            go = 0;
            a = 0;
            b = 0;

            repeat (2) @(posedge clk);

            @(negedge clk);
            rst = 0;
        end
    endtask

    task run_test;
        input [WIDTH-1:0] val_a;
        input [WIDTH-1:0] val_b;
        input [WIDTH-1:0] expected;

        begin
            $display("");
            $display("====================================");
            $display("Testando MDC(%0d, %0d)", val_a, val_b);

            reset_dut();

            timeout_count = 0;

            // Aplica entradas
            @(negedge clk);
            a = val_a;
            b = val_b;

            // Pulso de go
            @(negedge clk);
            go = 1;

            @(negedge clk);
            go = 0;

            // Espera done
            while ((done !== 1'b1) && (timeout_count < MAX_CYCLES)) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end

            // Espera um pequeno tempo para estabilizar leitura
            #1;

            if (done === 1'b1) begin
                if (result === expected) begin
                    $display("OK: MDC(%0d, %0d) = %0d", val_a, val_b, result);
                end else begin
                    $display("ERRO: MDC(%0d, %0d) esperado = %0d, obtido = %0d",
                             val_a, val_b, expected, result);
                    errors = errors + 1;
                end
            end else begin
                $display("ERRO: timeout. done nao foi ativado para MDC(%0d, %0d)",
                         val_a, val_b);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("gcd_b_tb.vcd");
        $dumpvars(0, tb_gcd_b);

        $monitor("Time: %0t | state: %d | rst: %b | go: %b | a: %d | b: %d | x_reg: %d | y_reg: %d | result: %d | done: %b",
                 $time,
                 dut.fsm_inst.state,
                 rst,
                 go,
                 a,
                 b,
                 dut.data_path_inst.x_reg,
                 dut.data_path_inst.y_reg,
                 result,
                 done);

        errors = 0;

        rst = 0;
        go = 0;
        a = 0;
        b = 0;

        run_test(8'd6,   8'd3,   8'd3);
        run_test(8'd48,  8'd18,  8'd6);
        run_test(8'd21,  8'd7,   8'd7);
        run_test(8'd15,  8'd10,  8'd5);
        run_test(8'd100, 8'd25,  8'd25);
        run_test(8'd27,  8'd9,   8'd9);
        run_test(8'd13,  8'd13,  8'd13);

        $display("");
        $display("====================================");

        if (errors == 0) begin
            $display("TODOS OS TESTES PASSARAM.");
        end else begin
            $display("TESTE FINALIZADO COM %0d ERRO(S).", errors);
        end

        $finish;
    end

endmodule