module led_controller #(
    parameter int CLK_FREQ_HZ = 100_000_000
) (
    input  logic        clk,
    input  logic        resetn,

    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    
    output logic [3:0]  leds
);

    // Registradores visíveis pela interface AXI-Lite simplificada.
    localparam logic [31:0] ADDR_LED_CONTROL = 32'h0000_0001;
    localparam logic [31:0] ADDR_BLINK_CFG   = 32'h0000_0002;
    localparam logic [1:0]  AXI_RESP_OKAY    = 2'b00;
    localparam int          BLINK_TICKS      = (CLK_FREQ_HZ > 0) ? CLK_FREQ_HZ : 1;
    localparam int          BLINK_CNT_W      = (BLINK_TICKS > 1) ? $clog2(BLINK_TICKS) : 1;

    logic [3:0] led_control_reg;
    logic       blink_enable_reg;
    logic [3:0] blink_state;
    logic [BLINK_CNT_W-1:0] blink_counter;
    logic       write_fire;

    // A escrita acontece quando endereço e dado chegam juntos
    // e não existe resposta pendente da transação anterior.
    assign write_fire = s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axi_awready    <= 1'b0;
            s_axi_wready     <= 1'b0;
            s_axi_bresp      <= AXI_RESP_OKAY;
            s_axi_bvalid     <= 1'b0;
            led_control_reg  <= 4'b0000;
            blink_enable_reg <= 1'b0;
            blink_state      <= 4'b0001;
            blink_counter    <= '0;
            leds             <= 4'b0000;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            if (write_fire) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= AXI_RESP_OKAY;

                unique case (s_axi_awaddr)
                    ADDR_LED_CONTROL: led_control_reg <= s_axi_wdata[3:0];
                    ADDR_BLINK_CFG: begin
                        blink_enable_reg <= s_axi_wdata[0];
                        if (!s_axi_wdata[0]) begin
                            blink_state   <= 4'b0001;
                            blink_counter <= '0;
                        end
                    end
                    default: begin
                    end
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // Em modo blink, avança um LED por vez a cada BLINK_TICKS ciclos.
            if (blink_enable_reg) begin
                if (blink_counter == BLINK_TICKS - 1) begin
                    blink_counter <= '0;
                    blink_state   <= {blink_state[2:0], blink_state[3]};
                end else begin
                    blink_counter <= blink_counter + 1'b1;
                end
                leds <= blink_state;
            end else begin
                // Fora do modo blink, a saída reflete o valor escrito em 0x01.
                blink_counter <= '0;
                leds <= led_control_reg;
            end
        end
    end

endmodule
