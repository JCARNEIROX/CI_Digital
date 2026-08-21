`timescale 1ns/1ps

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