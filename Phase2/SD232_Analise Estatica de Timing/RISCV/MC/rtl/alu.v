module ALU(a, b, ALUControl, result);
  
  input wire[31:0] a, b;
  input wire[3:0] ALUControl;
  output reg[31:0] result;
  
  wire signed [31:0] signed_a;
  wire signed [31:0] signed_b;
  
  assign signed_a = a;
  assign signed_b = b;
  
  
  
localparam ADD = 4'b0000; // a + b
localparam SUB = 4'b0001; // a -b
localparam AND = 4'b0010; // a & b
localparam OR = 4'b0011; // a | b
localparam XOR = 4'b0100; // a ^ b
localparam SLL = 4'b0101; // a << b logic shift left
localparam SRL = 4'b0110; // a >> b logic shift right
localparam SRA = 4'b0111; // a >>> b arithmeti cshift right
localparam EQ = 4'b1000; // equal
localparam ULT = 4'b1001; // unsigned less than
localparam UGTE =4'b1010; // Unsigned great than or equal
localparam SLT = 4'b1011; // Signed less than
localparam SGTE =4'b1100; // Signed great than or equal
localparam NE   =4'b1101; // Not equal
  
  always @(*) begin
    case (ALUControl)
      ADD:
        result = a + b;
      SUB:
        result = a - b;
      AND:
        result = a & b;
      OR:
      	result = a | b;
      XOR:
        result = a ^ b;
      SLL:
      	result = a << b;
      SRL:
      	result = a >> b;
      SRA:
      	result = a >>> b;
      EQ:
        result = (a == b) ? 32'd1 : 32'd0;
      ULT:
        result = (a < b) ? 32'd1 : 32'd0;
      UGTE:
        result = (a >= b) ? 32'd1 : 32'd0;
      SLT:
        result = (signed_a < signed_b) ? 32'd1 : 32'd0;
      SGTE:
        result = (signed_a >= signed_b) ? 32'd1 : 32'd0;
      NE:
        result = (a != b) ? 32'd1 : 32'd0;
      default:
        result = a + b;  
    endcase
  end
  
endmodule

