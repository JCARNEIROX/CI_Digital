
module Subtractor #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] x,
  input  wire [WIDTH-1:0] y,
  input  wire Bin,en,
  output reg [WIDTH-1:0] D,
  output reg Bout
);
  always @(*) begin
    if (en) begin
      {Bout, D} = x - y - Bin;
    end
    else begin
      {Bout, D} = 0;
    end
  end
  
endmodule