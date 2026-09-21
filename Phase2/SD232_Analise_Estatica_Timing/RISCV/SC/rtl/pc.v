module pc (clk, rst, a, o);
  input clk, rst;
  input [31:0] a;
  output reg [31:0] o;
  
  always @ (posedge clk or posedge rst)
    begin
      if(rst)
        o <= 32'd0;
      else
        o <= a;
      
    end
  
endmodule
