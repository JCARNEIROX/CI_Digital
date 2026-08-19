`timescale 1ns/1ps

module tb_LMS_module;

    // Parâmetros do tamanho dos registradores internos do módulo
    parameter integer WIDTH       = 8;
    parameter integer W_WIDTH     = 16;
    parameter integer ACC_WIDTH   = 32;

    // Parâmetros específicos do teste
    parameter integer LR_SHIFT_TB = 3;
    parameter integer FRAC_TB     = 8;
    parameter integer N_ITER      = 20;
    parameter integer N_SAMPLES   = 5;

    integer iter;
    integer sample_idx;
    
    localparam integer SCALE_TB = (1 << FRAC_TB);

    // Entradas e saídas do DUT
    reg clk;
    reg rst;
    reg valid_in;

    reg signed [WIDTH-1:0] x_in;
    reg signed [WIDTH-1:0] d_in;

    wire done;
    wire signed [ACC_WIDTH-1:0] y_out;

    // Memória para amostras de teste
    reg signed [WIDTH-1:0] x_mem [0:N_SAMPLES-1];
    reg signed [WIDTH-1:0] d_mem [0:N_SAMPLES-1];   
    reg signed [W_WIDTH-1:0] w_before;
    reg signed [W_WIDTH-1:0] b_before;
    reg signed [W_WIDTH-1:0] w_after;
    reg signed [W_WIDTH-1:0] b_after;

    reg signed [ACC_WIDTH-1:0] d_fix_tb;
    reg signed [ACC_WIDTH-1:0] e_fix_tb;

    // ------------------------------------------------------------
    // Instância do DUT
    // ------------------------------------------------------------

    LMS_module #(
        .WIDTH(WIDTH),
        .W_WIDTH(W_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .LR_SHIFT(LR_SHIFT_TB),
        .FRAC(FRAC_TB)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .x_in(x_in),
        .d_in(d_in),
        .done(done),
        .y_out(y_out)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Task para enviar uma amostra
    // ------------------------------------------------------------

    task send_sample;
        input signed [WIDTH-1:0] x_sample;
        input signed [WIDTH-1:0] d_sample;
        input integer iter_idx;
        input integer sample_idx_in;

        begin
            // Valores antes da atualização
            w_before = dut.w;
            b_before = dut.b;

            // Aplica entrada
            @(negedge clk);
            x_in     = x_sample;
            d_in     = d_sample;
            valid_in = 1'b1;

            // Mantém valid_in por um ciclo
            @(negedge clk);
            valid_in = 1'b0;

            // Espera o módulo terminar a amostra
            wait(done == 1'b1);
            #1;

            // Valores depois da atualização
            w_after = dut.w;
            b_after = dut.b;

            // Converte d para ponto fixo:
            // d_fix = d << FRAC
            d_fix_tb = {{(ACC_WIDTH-WIDTH){d_sample[WIDTH-1]}}, d_sample} <<< FRAC_TB;

            // Erro em ponto fixo:
            // e_fix = d_fix - y_fix
            e_fix_tb = d_fix_tb - y_out;

            $display("Iter=%0d | Sample=%0d | x=%0d | d=%0d",
                iter_idx,
                sample_idx_in,
                $signed(x_sample),
                $signed(d_sample)
            );

            $display("   FIXED: w_i=%0d | b_i=%0d | y=%0d | e=%0d | w_next=%0d | b_next=%0d",
                $signed(w_before),
                $signed(b_before),
                $signed(y_out),
                $signed(e_fix_tb),
                $signed(w_after),
                $signed(b_after)
            );

            $display("   REAL : w_i=%f | b_i=%f | y=%f | e=%f | w_next=%f | b_next=%f",
                $itor($signed(w_before)) / SCALE_TB,
                $itor($signed(b_before)) / SCALE_TB,
                $itor($signed(y_out)) / SCALE_TB,
                $itor($signed(e_fix_tb)) / SCALE_TB,
                $itor($signed(w_after)) / SCALE_TB,
                $itor($signed(b_after)) / SCALE_TB
            );

            $display("");
        end
    endtask

    // ------------------------------------------------------------
    // Processo principal
    // ------------------------------------------------------------

    initial begin
        rst      = 1'b1;
        valid_in = 1'b0;
        x_in     = 0;
        d_in     = 0;

        // --------------------------------------------------------
        // Dataset exemplo: d = 2x + 1
        // Pares: [[x,d]]
        // --------------------------------------------------------

        x_mem[0] = -3;  d_mem[0] = -5;
        x_mem[1] = -2;  d_mem[1] = -3;
        // x_mem[2] =  0;  d_mem[2] =  1;
        x_mem[2] =  2;  d_mem[2] =  5;
        x_mem[3] =  4;  d_mem[3] =  9;
        x_mem[4] = -1;  d_mem[4] =  -1;

        // Reset inicial
        repeat(3) @(negedge clk);
        rst = 1'b0;

        $display("==============================================");
        $display("Inicio da simulacao Adaline/LMS");
        $display("N_SAMPLES = %0d", N_SAMPLES);
        $display("N_ITER    = %0d", N_ITER);
        $display("LR_SHIFT  = %0d", LR_SHIFT_TB);
        $display("LR        = 1/(2^%0d)", LR_SHIFT_TB);
        $display("FRAC      = %0d", FRAC_TB);
        $display("SCALE     = %0d", SCALE_TB);
        $display("==============================================");
        $display("");

        // --------------------------------------------------------
        // Treinamento por número total de iterações
        // --------------------------------------------------------

        for (iter = 0; iter < N_ITER; iter = iter + 1) begin
            sample_idx = iter % N_SAMPLES;

            send_sample(
                x_mem[sample_idx],
                d_mem[sample_idx],
                iter,
                sample_idx
            );
        end

        // --------------------------------------------------------
        // Resultado final
        // --------------------------------------------------------

        $display("==============================================");
        $display("Simulacao finalizada");

        $display("w final fixed = %0d", $signed(dut.w));
        $display("b final fixed = %0d", $signed(dut.b));

        $display("w final real  = %f", $itor($signed(dut.w)) / SCALE_TB);
        $display("b final real  = %f", $itor($signed(dut.b)) / SCALE_TB);

        $display("==============================================");

        #20;
        $finish;
    end

endmodule