`include "uvm_macros.svh"
import uvm_pkg ::*;
import add_pkg::*;

interface register_if (input bit clk);
    logic rst_n;
    logic enable;
    logic [7:0] data_in;
    logic [7:0] data_out;

    clocking cb @(posedge clk);
        //default input #1step output #3; 
        output #2 data_in, enable;
        input #1 data_out;
	output #0 rst_n;
    endclocking

    // 3. Modport para o Testbench (TB)
    modport TB (
        clocking cb
    );
    
    // 4. Modport para o DUT (simplesmente conecta os sinais)
    modport DUT (
        input clk, rst_n, enable, data_in,
        output data_out
    );

endinterface

module simple_register (
 register_if.DUT if_reg
);
    always_ff @(posedge if_reg.clk or negedge if_reg.rst_n) begin
        if (!if_reg.rst_n) begin
            if_reg.data_out <= 8'h00;
        end else if (if_reg.enable) begin
            if_reg.data_out <= if_reg.data_in;
        end
    end
endmodule

/////// TB

module top_tb;

    logic clk;
    logic rst_n;

    register_if reg_if0(clk);

    // DUT instance
    simple_register dut (
        reg_if0.DUT
    );

    always #5 clk = ~clk;

    // Reset generation
    initial begin
        clk = 0;
        reg_if0.rst_n = 0;
        repeat(4) @reg_if0.clk;
        reg_if0.rst_n = 1;
	repeat(1) @reg_if0.clk;

    end

    initial begin
        // Set virtual interface
        uvm_config_db#(virtual register_if)::set(null, "uvm_test_top.env.agent.*", "vif", s_if0);

        // Run test
        run_test("add_test");
    end

endmodule