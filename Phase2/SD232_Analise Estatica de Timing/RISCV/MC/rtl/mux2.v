module mux2 (a, b, sel, o);
  
  input [31:0] a, b;
  input sel;
  output [31:0] o;
  
  assign o = (sel) ? b : a;
  
endmodule
