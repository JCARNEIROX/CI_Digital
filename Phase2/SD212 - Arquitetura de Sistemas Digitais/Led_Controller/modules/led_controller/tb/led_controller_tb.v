`timescale 1ns/1ps

module tb_led_controller;

    // Valor reduzido para a simulação: o DUT troca o LED a cada 4 ciclos.
    localparam int CLK_FREQ_HZ = 4;

    logic        clk;
    logic        resetn;
    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic        s_axi_wvalid;
    logic        s_axi_wready;
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;
    logic [3:0]  leds;

    led_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .leds(leds)
    );

    // Clock de simulação com período de 10 ns.
    always #5 clk = ~clk;

    // Gera uma transação de escrita AXI-Lite simplificada.
    task automatic axi_write(input logic [31:0] addr, input logic [31:0] data);
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;

            @(posedge clk);
            while (!s_axi_bvalid) begin
                @(posedge clk);
            end

            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;
            s_axi_bready  <= 1'b0;
        end
    endtask

    initial begin
        clk           = 1'b0;
        resetn        = 1'b0;
        s_axi_awaddr  = '0;
        s_axi_awvalid = 1'b0;
        s_axi_wdata   = '0;
        s_axi_wvalid  = 1'b0;
        s_axi_bready  = 1'b0;

        $dumpfile("led_controller.vcd");
        $dumpvars(0, tb_led_controller);

        repeat (2) @(posedge clk); // Mantém o reset ativo por 2 ciclos.
        resetn = 1'b1;

        // Modo estático: LEDs recebem diretamente o valor escrito em 0x01.
        axi_write(32'h0000_0001, 32'h0000_000A); // Supondo que há quatro "pinos" de LED, o valor 0xA (1010) acenderá os LEDs 1 e 3.
        @(posedge clk);
        if (leds !== 4'b1010) begin
            $error("Falha no modo estatico. Esperado 1010, recebido %b", leds);
        end

        // Habilita o blink sequencial pelo registrador 0x02.
        axi_write(32'h0000_0002, 32'h0000_0001); // Modo blink começa com o LED 0 aceso.
        @(posedge clk);
        if (leds !== 4'b0001) begin
            $error("Blink inicial incorreto. Esperado 0001, recebido %b", leds);
        end

        repeat (CLK_FREQ_HZ) @(posedge clk);
        if (leds !== 4'b0010) begin
            $error("Blink passo 1 incorreto. Esperado 0010, recebido %b", leds);
        end

        repeat (CLK_FREQ_HZ) @(posedge clk);
        if (leds !== 4'b0100) begin
            $error("Blink passo 2 incorreto. Esperado 0100, recebido %b", leds);
        end

        repeat (CLK_FREQ_HZ) @(posedge clk);
        if (leds !== 4'b1000) begin
            $error("Blink passo 3 incorreto. Esperado 1000, recebido %b", leds);
        end

        // Desabilita o blink e volta ao padrão fixo salvo em 0x01.
        axi_write(32'h0000_0002, 32'h0000_0000); // Modo estático LEDS = 0xA (1010).
        @(posedge clk);
        if (leds !== 4'b1010) begin
            $error("Falha ao retornar ao modo estatico. Esperado 1010, recebido %b", leds);
        end

        #20 $finish;
    end

endmodule
