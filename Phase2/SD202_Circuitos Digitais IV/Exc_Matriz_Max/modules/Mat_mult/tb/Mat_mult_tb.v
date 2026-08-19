`timescale 1ns/1ns

module tb_Mat_mult;
    reg [71:0] A;
    reg [71:0] B;
    wire [71:0] Result;

    // Instancia o design
    Mat_mult dut ( .A(A), .B(B), .Result(Result) );

    initial begin
      $dumpfile("dump.vcd"); $dumpvars;
        A = {72'd0};
        B = {72'd0};
      
      	#10;
      	A = 72'd200;
      	B = 72'd255;
      	#10;
      

        
        $finish;
    end
endmodule
