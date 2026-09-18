`include "uvm_macros.svh"
import uvm_pkg::*;

module top_tb;

    logic clk;

    ula_if u_if0(clk);

    ula dut (
        u_if0.DUT
    );

    always #5 clk = ~clk;

    initial begin
        clk         = 1'b0;
        u_if0.rst_n = 1'b0;
        repeat (2) @(u_if0.clk);
        u_if0.rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual ula_if)::set(null, "uvm_test_top.env.agent.*", "vif", u_if0);
        run_test("ula_test");
    end

endmodule
