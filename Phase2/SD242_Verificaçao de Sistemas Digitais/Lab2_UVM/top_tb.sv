/// TOP_TB
`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_params_pkg::*;
import tb_pkg::*;

module top_tb #(
    parameter int READ_LATENCY = 2
);
    logic clk;
    logic rst_n;
    dut_if #( 
        tb_params_pkg::DATA_WIDTH,
        tb_params_pkg::ADDR_WIDTH 
    ) g_if0 ( clk );

    // DUT instance
    generic #(
        .DATA_WIDTH(tb_params_pkg::DATA_WIDTH),
        .ADDR_WIDTH(tb_params_pkg::ADDR_WIDTH),
        .READ_LATENCY(READ_LATENCY)
    ) dut (g_if0.DUT);
    
    // Clock generation
    always #5 clk = ~clk;

    // Reset is owned by the HDL wrapper; all bus traffic is driven by UVM.
    initial begin
        clk = 0;
        g_if0.rst_n = 0;
        g_if0.w_en = 0;
        g_if0.r_en = 0;
        g_if0.addr = 0;
        g_if0.data_in = 0;
        repeat (4) @g_if0.tb_cb;
        g_if0.rst_n = 1;
    end

    initial begin
        uvm_config_db#(dut_vif_t)::set(null, "uvm_test_top.env.agent.*", "vif", g_if0);
        run_test();
    end
endmodule
