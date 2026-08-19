`timescale 1ns/1ns

module tb_gcd_system;

    parameter WIDTH = 8;
    parameter MAX_CYCLES = 200;

    reg clk, rst, go;
    reg [WIDTH-1:0] x, y;

    wire x_sel, y_sel;
    wire x_ld, y_ld;
    wire x_sub, y_sub;
    wire data_en;

    wire x_gt_y, x_eq_y, x_lt_y;
    wire [WIDTH-1:0] result;

    integer cycles;
    integer errors;

    // FSM
    FSM fsm_inst (
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

    // Datapath
    data_path #(
        .WIDTH(WIDTH)
    ) dp_inst (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .x_sel(x_sel),
        .y_sel(y_sel),
        .x_ld(x_ld),
        .y_ld(y_ld),
        .x_sub(x_sub),
        .y_sub(y_sub),
        .data_en(data_en),
        .x_gt_y(x_gt_y),
        .x_eq_y(x_eq_y),
        .x_lt_y(x_lt_y),
        .result(result)
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
            x = 0;
            y = 0;

            repeat (3) @(posedge clk);

            @(negedge clk);
            rst = 0;
        end
    endtask

    task run_gcd_test;
        input [WIDTH-1:0] x_value;
        input [WIDTH-1:0] y_value;
        input [WIDTH-1:0] expected;
        begin
            $display("");
            $display("Iniciando teste: MDC(%0d, %0d), esperado = %0d",
                     x_value, y_value, expected);

            reset_dut();

            @(negedge clk);
            x = x_value;
            y = y_value;

            // Pulso de go por 1 ciclo
            @(negedge clk);
            go = 1;

            @(negedge clk);
            go = 0;

            cycles = 0;

            // Espera data_en indicar resultado pronto
            while ((data_en !== 1'b1) && (cycles < MAX_CYCLES)) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            // Espera mais uma borda para garantir atualização do registrador de resultado
            @(posedge clk);
            #1;

            if (data_en === 1'b1) begin
                if (result === expected) begin
                    $display("OK: MDC(%0d, %0d) = %0d em %0d ciclos",
                             x_value, y_value, result, cycles);
                end else begin
                    $display("ERRO: MDC(%0d, %0d) esperado = %0d, obtido = %0d",
                             x_value, y_value, expected, result);
                    errors = errors + 1;
                end
            end else begin
                $display("ERRO: timeout. data_en nao foi ativado para MDC(%0d, %0d)",
                         x_value, y_value);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("gcd_system_tb.vcd");
        $dumpvars(0, tb_gcd_system);

        $monitor("T=%0t | state=%d | x=%0d | y=%0d | x_reg=%0d | y_reg=%0d | gt=%b eq=%b lt=%b | x_sel=%b y_sel=%b x_ld=%b y_ld=%b x_sub=%b y_sub=%b data_en=%b | result=%0d",
                 $time,
                 fsm_inst.state,
                 x,
                 y,
                 dp_inst.x_reg,
                 dp_inst.y_reg,
                 x_gt_y,
                 x_eq_y,
                 x_lt_y,
                 x_sel,
                 y_sel,
                 x_ld,
                 y_ld,
                 x_sub,
                 y_sub,
                 data_en,
                 result);

        errors = 0;

        rst = 0;
        go = 0;
        x = 0;
        y = 0;

        run_gcd_test(8'd6,  8'd3,  8'd3);
        run_gcd_test(8'd27,  8'd15,  8'd3);
        run_gcd_test(8'd21,  8'd7,   8'd7);
        run_gcd_test(8'd13,  8'd13,  8'd13);
        run_gcd_test(8'd100, 8'd25,  8'd25);

        if (errors == 0) begin
            $display("");
            $display("TODOS OS TESTES PASSARAM.");
        end else begin
            $display("");
            $display("TESTE FINALIZADO COM %0d ERRO(S).", errors);
        end

        $finish;
    end

endmodule