`timescale 1ns/10ps
import uvm_pkg ::*;
import add_pkg::*;

module register_tb;
    bit clk;
    
    // Clock generation with 20ns period (50MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    register_if reg_if(clk);

    // Instantiate DUT
    simple_register dut_instance (reg_if);

    initial begin
    // Main test sequence
        reg_if.cb.rst_n <= 0;
	@(reg_if.cb);
        @(reg_if.cb);
        reg_if.cb.rst_n <= 1;
        @(reg_if.cb);
        test_transaction(8'h01);
        test_transaction(8'hAA);
        test_transaction(8'h55);
        test_transaction(8'hFF);

    end

    initial begin
        #1000;
        $display("=== SIMULATION FINISHED ===");
        $finish;
    end

    task test_transaction (logic [7:0] data);
        // Apply test data
        reg_if.cb.data_in <= data;
        reg_if.cb.enable <= 1'b1;
        @(reg_if.cb);

        reg_if.cb.data_in <= 0;
        reg_if.cb.enable <= 1'b0;
        @(reg_if.cb);
        // Check result
        if(reg_if.cb.data_out == data)
            $display("TIME=%0tns-  PASS: data_out = %h", $time, reg_if.cb.data_out);
        else
            $display("TIME=%0tns-  FAIL: data_out = %h (expected %h)", $time, reg_if.cb.data_out, data);

    endtask
endmodule
