/// TOP_TB
`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_params_pkg::*;
module top_tb;
    logic clk;
    logic rst_n;
    dut_if #( tb_params_pkg::DATA_WIDTH,
    tb_params_pkg::ADDR_WIDTH ) g_if0 ( clk );
    // DUT instance
    generic #( tb_params_pkg::DATA_WIDTH,
    tb_params_pkg::ADDR_WIDTH, 2) dut ( g_if0.DUT );
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        clk = 0;
        g_if0.rst_n = 0;
        repeat(4) @g_if0.tb_cb;
        // Desativa o reset
        g_if0.rst_n = 1;
            repeat(10) @g_if0.tb_cb;

        g_if0.tb_cb.w_en <= 0;
        g_if0.tb_cb.data_in <= 0;
        g_if0.tb_cb.addr <= 0;
        g_if0.tb_cb.r_en <= 0;

        @g_if0.tb_cb;

            g_if0.tb_cb.w_en <= 1;

            for (int i = 0; i< 50; i++) begin
                g_if0.tb_cb.data_in <= i;
                g_if0.tb_cb.addr <= i;
                @g_if0.tb_cb;
            end

            g_if0.tb_cb.w_en <= 0;
            for (int j = 0; j < 50; j++) begin
                g_if0.tb_cb.r_en <= 1;
                g_if0.tb_cb.addr <= j;
                @g_if0.tb_cb;
            end

            g_if0.tb_cb.r_en <= 0;
            repeat(15) @g_if0.tb_cb;
            $finish;
    end

    initial begin
        // Set virtual interface
        uvm_config_db#(dut_vif_t)::set(null, "uvm_test_top.env.agent.*", "vif", g_if0);
        // Run test
        //run_test("test");
    end
endmodule