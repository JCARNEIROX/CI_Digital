module imem (a, rd);
  input [31:0] a;
  output [31:0] rd;
  
  reg [31:0] mem [255:0];
  
  
  initial
    $readmemh("imem.hex", mem);
  
  
  assign rd = mem[a[31:2]];
  
endmodule