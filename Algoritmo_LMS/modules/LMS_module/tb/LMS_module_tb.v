`timescale 1ns/1ps

module tb_LMS_module;

    // ------------------------------------------------------------
    // Parâmetros do testbench
    // ------------------------------------------------------------

    parameter integer WIDTH       = 8;
    parameter integer W_WIDTH     = 16;
    parameter integer ACC_WIDTH   = 32;

    // LR = 1/(2^LR_SHIFT_TB)
    // LR_SHIFT_TB = 4 -> LR = 1/16 = 0,0625
    parameter integer LR_SHIFT_TB = 4;

    parameter integer N_SAMPLES   = 6;
    parameter integer N_EPOCHS    = 10;

    // ------------------------------------------------------------
    // Sinais do DUT
    // ------------------------------------------------------------

    reg clk;
    reg rst;
    reg valid_in;

    reg signed [WIDTH-1:0] x_in;
    reg signed [WIDTH-1:0] d_in;

    wire done;
    wire signed [ACC_WIDTH-1:0] y_out;

    // ------------------------------------------------------------
    // Dataset
    // ------------------------------------------------------------

    reg signed [WIDTH-1:0] x_mem [0:N_SAMPLES-1];
    reg signed [WIDTH-1:0] d_mem [0:N_SAMPLES-1];

    // ------------------------------------------------------------
    // Variáveis auxiliares
    // ------------------------------------------------------------

    integer i;
    integer epoch;
    integer e_tb;

    // ------------------------------------------------------------
    // Instância do módulo LMS
    // ------------------------------------------------------------

    LMS_module #(
        .WIDTH(WIDTH),
        .W_WIDTH(W_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .LR_SHIFT(LR_SHIFT_TB)
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
        forever #5 clk = ~clk;   // período de 10 ns
    end

    // ------------------------------------------------------------
    // Task para enviar uma amostra
    // ------------------------------------------------------------

    task send_sample;
        input signed [WIDTH-1:0] x_sample;
        input signed [WIDTH-1:0] d_sample;
        input integer epoch_idx;
        input integer sample_idx;

        begin
            // Aplica a amostra na entrada
            @(negedge clk);
            x_in     = x_sample;
            d_in     = d_sample;
            valid_in = 1'b1;

            // Mantém valid_in por um ciclo
            @(negedge clk);
            valid_in = 1'b0;

            // Espera o módulo terminar o processamento da amostra
            wait(done == 1'b1);

            // Aguarda pequeno tempo para leitura estável
            #1;

            // Erro calculado no próprio testbench
            e_tb = $signed(d_sample) - $signed(y_out);

            $display("Epoch=%0d | Sample=%0d | x=%0d | d=%0d | y=%0d | e=%0d | w=%0d | b=%0d",
                epoch_idx,
                sample_idx,
                $signed(x_sample),
                $signed(d_sample),
                $signed(y_out),
                e_tb,
                $signed(dut.w),
                $signed(dut.b)
            );
        end
    endtask

    // ------------------------------------------------------------
    // Processo principal
    // ------------------------------------------------------------

    initial begin

        // Inicialização
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
        x_mem[2] =  0;  d_mem[2] =  1;
        x_mem[3] =  2;  d_mem[3] =  5;
        x_mem[4] =  4;  d_mem[4] =  9;
        x_mem[5] = -1;  d_mem[5] =  1;

        // Reset inicial
        repeat(3) @(negedge clk);
        rst = 1'b0;

        $display("==============================================");
        $display("Inicio da simulacao Adaline/LMS");
        $display("N_SAMPLES = %0d", N_SAMPLES);
        $display("N_EPOCHS  = %0d", N_EPOCHS);
        $display("LR_SHIFT  = %0d", LR_SHIFT_TB);
        $display("LR        = 1/(2^%0d)", LR_SHIFT_TB);
        $display("==============================================");

        // --------------------------------------------------------
        // Treinamento
        // --------------------------------------------------------

        for (epoch = 0; epoch < N_EPOCHS; epoch = epoch + 1) begin

            $display("");
            $display("----------- Epoch %0d -----------", epoch);

            for (i = 0; i < N_SAMPLES; i = i + 1) begin
                send_sample(x_mem[i], d_mem[i], epoch, i);
            end

        end

        // --------------------------------------------------------
        // Resultado final
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("Simulacao finalizada");
        $display("Peso final w = %0d", $signed(dut.w));
        $display("Bias final b = %0d", $signed(dut.b));
        $display("==============================================");

        #20;
        $finish;
    end

endmodule