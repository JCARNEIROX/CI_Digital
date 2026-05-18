`timescale 1ns/1ns

module tb_FSM;

    reg clk, rst;
    reg go;
    reg x_gt_y, x_eq_y, x_lt_y;

    wire x_sel, y_sel;
    wire x_ld, y_ld;
    wire data_en;
    wire x_sub, y_sub;

    integer errors;

    // Estados esperados
    localparam [2:0]
        s1 = 3'b000,
        s2 = 3'b001,
        s3 = 3'b010,
        s4 = 3'b011,
        s5 = 3'b100,
        s6 = 3'b110,
        s7 = 3'b111,
        s8 = 3'b101;

    FSM dut (
        .clk(clk),
        .rst(rst),
        .go(go),
        .x_gt_y(x_gt_y),
        .x_eq_y(x_eq_y),
        .x_lt_y(x_lt_y),
        .x_sel(x_sel),
        .y_sel(y_sel),
        .x_ld(x_ld),
        .y_ld(y_ld),
        .data_en(data_en),
        .x_sub(x_sub),
        .y_sub(y_sub)
    );

    // Clock de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task check_outputs;
        input [2:0] expected_state;
        input expected_x_sel;
        input expected_y_sel;
        input expected_x_ld;
        input expected_y_ld;
        input expected_x_sub;
        input expected_y_sub;
        input expected_data_en;
        begin
            #1;

            if (dut.state !== expected_state) begin
                $display("ERRO em %0t: state esperado = %d, obtido = %d",
                         $time, expected_state, dut.state);
                errors = errors + 1;
            end

            if (x_sel !== expected_x_sel) begin
                $display("ERRO em %0t: x_sel esperado = %d, obtido = %d",
                         $time, expected_x_sel, x_sel);
                errors = errors + 1;
            end

            if (y_sel !== expected_y_sel) begin
                $display("ERRO em %0t: y_sel esperado = %d, obtido = %d",
                         $time, expected_y_sel, y_sel);
                errors = errors + 1;
            end

            if (x_ld !== expected_x_ld) begin
                $display("ERRO em %0t: x_ld esperado = %d, obtido = %d",
                         $time, expected_x_ld, x_ld);
                errors = errors + 1;
            end

            if (y_ld !== expected_y_ld) begin
                $display("ERRO em %0t: y_ld esperado = %d, obtido = %d",
                         $time, expected_y_ld, y_ld);
                errors = errors + 1;
            end

            if (x_sub !== expected_x_sub) begin
                $display("ERRO em %0t: x_sub esperado = %d, obtido = %d",
                         $time, expected_x_sub, x_sub);
                errors = errors + 1;
            end

            if (y_sub !== expected_y_sub) begin
                $display("ERRO em %0t: y_sub esperado = %d, obtido = %d",
                         $time, expected_y_sub, y_sub);
                errors = errors + 1;
            end

            if (data_en !== expected_data_en) begin
                $display("ERRO em %0t: data_en esperado = %d, obtido = %d",
                         $time, expected_data_en, data_en);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("FSM_tb.vcd");
        $dumpvars(0, tb_FSM);

        $monitor("Time: %0t | state: %d | go: %b | gt: %b | eq: %b | lt: %b | x_sel: %b | y_sel: %b | x_ld: %b | y_ld: %b | x_sub: %b | y_sub: %b | data_en: %b",
                 $time, dut.state, go, x_gt_y, x_eq_y, x_lt_y,
                 x_sel, y_sel, x_ld, y_ld, x_sub, y_sub, data_en);

        errors = 0;

        // Inicialização
        rst = 1;
        go = 0;
        x_gt_y = 0;
        x_eq_y = 0;
        x_lt_y = 0;

        // Como o reset é síncrono, precisa esperar borda de clock
        @(posedge clk);
        check_outputs(s1, 1, 0, 0, 0, 0, 0, 0);

        @(posedge clk);
        check_outputs(s1, 1, 0, 0, 0, 0, 0, 0);

        // Desativa reset
        rst = 0;

        // Teste: sem go, deve continuar em s1
        @(posedge clk);
        check_outputs(s1, 1, 0, 0, 0, 0, 0, 0);

        // Pulso de go: s1 -> s2
        go = 1;
        @(posedge clk);
        check_outputs(s2, 0, 0, 1, 1, 0, 0, 0);

        go = 0;

        // s2 -> s3
        @(posedge clk);
        check_outputs(s3, 0, 0, 0, 0, 0, 0, 0);

        // Caminho x > y: s3 -> s4
        x_gt_y = 1;
        x_eq_y = 0;
        x_lt_y = 0;

        @(posedge clk);
        check_outputs(s4, 0, 0, 0, 0, 1, 0, 0);

        x_gt_y = 0;

        // s4 -> s5
        @(posedge clk);
        check_outputs(s5, 0, 0, 0, 0, 0, 0, 0);

        // s5 -> s2
        @(posedge clk);
        check_outputs(s2, 0, 0, 1, 1, 0, 0, 0);

        // s2 -> s3
        @(posedge clk);
        check_outputs(s3, 0, 0, 0, 0, 0, 0, 0);

        // Caminho x < y: s3 -> s7
        x_gt_y = 0;
        x_eq_y = 0;
        x_lt_y = 1;

        @(posedge clk);
        check_outputs(s7, 0, 0, 0, 0, 0, 1, 0);

        x_lt_y = 0;

        // s7 -> s8
        @(posedge clk);
        check_outputs(s8, 0, 1, 0, 0, 0, 0, 0);

        // s8 -> s2
        @(posedge clk);
        check_outputs(s2, 0, 0, 1, 1, 0, 0, 0);

        // s2 -> s3
        @(posedge clk);
        check_outputs(s3, 0, 0, 0, 0, 0, 0, 0);

        // Caminho x == y: s3 -> s6
        x_gt_y = 0;
        x_eq_y = 1;
        x_lt_y = 0;

        @(posedge clk);
        check_outputs(s6, 0, 0, 0, 0, 0, 0, 1);

        x_eq_y = 0;

        // Pela sua FSM atual, s6 não está no case de transição.
        // Então ele cai no default e volta para s1.
        @(posedge clk);
        check_outputs(s1, 1, 0, 0, 0, 0, 0, 0);

        if (errors == 0) begin
            $display("TESTE FINALIZADO SEM ERROS.");
        end else begin
            $display("TESTE FINALIZADO COM %0d ERRO(S).", errors);
        end

        $finish;
    end

endmodule