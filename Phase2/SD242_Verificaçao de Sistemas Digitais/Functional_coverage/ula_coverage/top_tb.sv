`include "uvm_macros.svh"
import uvm_pkg::*;

module top_tb;

    logic clk;
    logic rst_n;

    ula_if u_if0(clk);

    // DUT instance
    ula dut (
        u_if0.DUT
    );

    always #5 clk = ~clk;

    // Reset generation
    initial begin
        clk = 0;
        u_if0.rst_n = 0;
        repeat(2) @u_if0.clk;
        u_if0.rst_n = 1;
        
    end

    // Reset generation
    initial begin
        // Set virtual interface
        uvm_config_db#(virtual ula_if)::set(null, "uvm_test_top.env.agent.*", "vif", u_if0);

        // Run test
        run_test("ula_test");
    end

endmodule


    // Monitor
/*    initial begin
        repeat(5) @u_if0.clk;
        forever begin
            @u_if0.clk;
            if (u_if0.a != 0 || u_if0.b != 0) begin
		if (u_if0.opr == 1) begin
			@u_if0.clk;
                	$display("[MON SOMA] a=%0d, b=%0d -> result=%0d, carry=%0d", 
                         u_if0.a, u_if0.b, u_if0.result, u_if0.carry_o);
		end else begin
                	$display("[MON SUB] a=%0d, b=%0d -> result=%0d, carry=%0d", 
                         u_if0.a, u_if0.b, u_if0.result, u_if0.carry_o);		
		end
            end
        end
    end*/
