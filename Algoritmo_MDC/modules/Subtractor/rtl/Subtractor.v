
module Subtractor #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] x,
  input  wire [WIDTH-1:0] y,
  input  wire Bin,
  output reg [WIDTH-1:0] D,
  output reg Bout
);
  always @(*) begin
    {Bout, D} = x - y - Bin;
  end
  
endmodule