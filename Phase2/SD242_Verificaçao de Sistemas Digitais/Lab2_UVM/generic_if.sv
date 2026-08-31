`timescale 1ns/1ps
module generic #(
    parameter int DATA_WIDTH = 16,
    parameter int ADDR_WIDTH = 8,
    parameter int READ_LATENCY = 2)(dut_if.DUT g_if);

    localparam int DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [DATA_WIDTH-1:0] pending_data;
    int latency_counter;

    always_ff @(posedge g_if.clk) begin
        if (!g_if.rst_n) begin
            g_if.data_out <= 0;
            pending_data <= 0;
            latency_counter <= 0;
        end
    else begin
        g_if.data_out <= 0;

        //------------------------------------------------------------
        // WRITE
        //------------------------------------------------------------
            if (g_if.w_en) begin
                mem[g_if.addr] <= g_if.data_in;
            end
        //------------------------------------------------------------
        // READ REQUEST
        //------------------------------------------------------------
            if (g_if.r_en && (latency_counter == 0)) begin
                pending_data <= mem[g_if.addr];
                latency_counter <= READ_LATENCY;
            end
        //------------------------------------------------------------
        // READ RESPONSE
        //------------------------------------------------------------
            if (latency_counter > 0) begin
                latency_counter <= latency_counter - 1;
                if (latency_counter == 1) begin
                    g_if.data_out <= pending_data;
                end
            end
        end
    end
endmodule