module extendImm (Instr, ExtImm);
  input  [31:0]	Instr;
  output reg [31:0]	ExtImm;

  wire [6:0] opcode;

  assign opcode = Instr[6:0];
  always @ (*)
    begin
      case (opcode)
        7'b0000011, 7'b0010011, 7'b1100111: // I-Type
          ExtImm = {{20{Instr[31]}}, {Instr[31:20]}};
        7'b010_0011:	//S - type
          ExtImm = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
        7'b110_0011:	//B - type
          ExtImm = {{19{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
        7'b001_0111, 7'b011_0111 :	//U - type
          ExtImm = {Instr[31:12], 12'b0000_0000_0000};
        7'b110_1111:	//J - type
          ExtImm = {{11{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0};
        default:
          ExtImm = 32'd0;
      endcase
    end
endmodule
  
