module dmem (clk, reset, a, rd, wd, we, mode);
  
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter MEM_ADDR_SIZE = 10;
  
  input clk, reset, we;
  input [2:0] mode;	
  input [DATA_WIDTH-1:0] wd;
  output reg [DATA_WIDTH-1:0] rd;
  input [ADDR_WIDTH-1:0] a;
  
  
  integer i=0;
  
  always @(posedge clk or posedge reset) 
    begin
		if (reset) 
          begin
            for(i=0; i<(2**MEM_ADDR_SIZE); i=i+1)
              begin
                mem [i] <= 8'h00;
              end
          end
    end
endmodule