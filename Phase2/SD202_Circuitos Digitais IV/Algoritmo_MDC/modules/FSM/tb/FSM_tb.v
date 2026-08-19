`timescale 1ns/1ns

module tb_FSM;

    reg clk, rst;
    reg go;
    reg x_gt_y, x_eq_y, x_lt_y;

    wire x_sel, y_sel;
    wire x_ld, y_ld;
    wire data_en;
    wire x_sub, y_sub;

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
    initial clk = 0;
    always #5 clk = ~clk;

    task clear_cmp;
        begin
            x_gt_y = 0;
            x_eq_y = 0;
            x_lt_y = 0;
        end
    endtask

    task pulse_go;
        begin
            @(negedge clk);
            go = 1;

            @(negedge clk);
            go = 0;
        end
    endtask

    task wait_compare_state;
        begin
            wait (dut.state == dut.s2);
            @(negedge clk);
        end
    endtask

    task test_gt_case;
        begin
            $display("\n--- Testando caso x > y ---");

            wait_compare_state();

            x_gt_y = 1;
            x_eq_y = 0;
            x_lt_y = 0;

            @(posedge clk);
            #1;
            $display("Depois de x_gt_y=1 | state=%d | x_sub=%b | y_sub=%b | data_en=%b",
                     dut.state, x_sub, y_sub, data_en);

            @(negedge clk);
            clear_cmp();
        end
    endtask

    task test_lt_case;
        begin
            $display("\n--- Testando caso x < y ---");

            wait_compare_state();

            x_gt_y = 0;
            x_eq_y = 0;
            x_lt_y = 1;

            @(posedge clk);
            #1;
            $display("Depois de x_lt_y=1 | state=%d | x_sub=%b | y_sub=%b | data_en=%b",
                     dut.state, x_sub, y_sub, data_en);

            @(negedge clk);
            clear_cmp();
        end
    endtask

    task test_eq_case;
        begin
            $display("\n--- Testando caso x == y ---");

            wait_compare_state();

            x_gt_y = 0;
            x_eq_y = 1;
            x_lt_y = 0;

            @(posedge clk);
            #1;
            $display("Depois de x_eq_y=1 | state=%d | x_sub=%b | y_sub=%b | data_en=%b",
                     dut.state, x_sub, y_sub, data_en);

            @(negedge clk);
            clear_cmp();
        end
    endtask

    initial begin
        $dumpfile("FSM_tb.vcd");
        $dumpvars(0, tb_FSM);

        $monitor("Time: %0t | state: %d | rst: %b | go: %b | gt: %b | eq: %b | lt: %b | x_sel: %b | y_sel: %b | x_ld: %b | y_ld: %b | x_sub: %b | y_sub: %b | data_en: %b",
                 $time, dut.state, rst, go, x_gt_y, x_eq_y, x_lt_y,
                 x_sel, y_sel, x_ld, y_ld, x_sub, y_sub, data_en);

        // Inicialização
        rst = 1;
        go = 0;
        clear_cmp();

        // Reset síncrono: precisa passar por borda de clock
        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 0;

        // Inicia a FSM
        pulse_go();

        // Testa os três caminhos
        test_gt_case();

        // Espera a FSM voltar para o estado de comparação
        test_lt_case();

        // Espera a FSM voltar para o estado de comparação
        test_eq_case();

        #50;
        $finish;
    end

endmodule