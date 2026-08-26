 
module regfile (clk, rst, we, rs1, rs2, rd, wr_rd, rs1_o, rs2_o);
  input clk, rst, we;
  input [4:0] rs1, rs2, rd;
  input [31:0] wr_rd;
  output [31:0] rs1_o, rs2_o;
  
  reg [31:0] mem [31:0];
  
  integer i = 0;
  
  assign rs1_o = (rs1 == 5'd0) ? 32'd0 : mem[rs1];
  assign rs2_o = (rs2 == 5'd0) ? 32'd0 : mem[rs2];
  
  always @(posedge clk, posedge rst) begin
    if (rst) begin	// Reset
          for(i=0; i<32; i=i+1)
              begin
                mem [i] <= 32'd0;
              end
        end
    else if (we && rd!=0)
      begin
        mem[rd] <= wr_rd;
      end
    else
      begin
      mem[rd] <=  mem[rd];
      end
  end
endmodule
    
 

module ALU(a, b, ALUControl, result);
	input wire [31:0]	a, b;
	input wire [3:0]	ALUControl;
	output reg [31:0]	result;
  
  wire signed [31:0] signed_a, signed_b;
  
  assign signed_a = a;
  assign signed_b = b;  

  localparam ADD = 4'b0000; // a + b
  localparam SUB = 4'b0001; // a - b 
  localparam AND = 4'b0010; // a & b 
  localparam OR  = 4'b0011; // a | b
  localparam XOR = 4'b0100; // a ^ b
  localparam SLL = 4'b0101; // a << b logic shift left
  localparam SRL = 4'b0110; // a >> b logic shift right
  localparam SRA = 4'b0111; // a >>> b arithmetic shift right
  localparam EQ =  4'b1000; // equal
  localparam ULT = 4'b1001; // unsigned less than
  localparam UGTE =4'b1010; // Unsigned great than or equal
  localparam SLT = 4'b1011; // Signed less than
  localparam SGTE =4'b1100; // Signed great than or equal
  

  	always @(*) begin
		case (ALUControl)
          4'd0:
            result = a + b;
          4'd1:
            result = a - b;
          4'b0010:
            result = a & b;
          OR:
            result = a | b;
          XOR: 
            begin
            result = a ^ b;
            end
          SLL:
            result = a << b[4:0];
          SRL:
          	result = a >> b[4:0];
          SRA:
            result = a >>> b[4:0];
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
          default:
            result = 32'd0;
        endcase
    end
  
  
endmodule

module extendImm (Instr, ExtImm);
  input  [31:0]	Instr;
  output reg [31:0]	ExtImm;

  wire [6:0] opcode;

  assign opcode = Instr[6:0];
  always @ (*)
    begin
      case (opcode)
        7'b000_0011, 7'b001_0011, 7'b110_0111 :		// I-type
          ExtImm = {{20{Instr[31]}}, {Instr[31:20]}};
        7'b010_0011:	//S - type
          ExtImm = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
        7'b110_0011:	//B - type
          ExtImm = {{19{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
        7'b001_0111,  7'b011_0111:	//U - type
          ExtImm = {Instr[31:12], 12'b0000_0000_0000};
        7'b110_1111:	//J - type
          ExtImm = {{11{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0};
        default:
          ExtImm = 32'd0;
      endcase
    end 

endmodule


module control (instr, jump, PCSel, RegSel, AluOp, regWE, memWE, rs1Sel, rs2Sel, memMode);

  input [31:0] instr;
  input jump;
  output reg [1:0] PCSel, RegSel;
  output reg [3:0] AluOp;
  output reg regWE, memWE, rs1Sel, rs2Sel;
  output reg [2:0] memMode;

  localparam ADD = 4'b0000;
  localparam SUB = 4'b0001;  
  localparam AND = 4'b0010;  
  localparam OR  = 4'b0011; 
  localparam XOR = 4'b0100; 
  localparam SLL = 4'b0101; 
  localparam SRL = 4'b0110;
  localparam SRA = 4'b0111;
  localparam EQ =  4'b1000; 
  localparam ULT = 4'b1001; 
  localparam UGTE =4'b1010;
  localparam SLT = 4'b1011;
  localparam SGTE =4'b1100;

  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;

  assign opcode = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];

  //define


  always @(*) 
    begin
      case (opcode)
        7'b0110011: // R-Type
          begin
            case (funct3)
              3'b000: //add or sub
                begin
                  case (funct7)
                    7'b0000000: //add 
                      begin
                        PCSel		=2'b00; // pc = pc+4
                        RegSel	=2'b01; // ALU output
                        AluOp		=ADD; 	
                        regWE		=1'b1; // Write RegFile
                        memWE		=1'b0;  
                        rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                        rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                        memMode	=3'b000; //load word
                      end
                    7'b0100000: //sub 
                      begin
                        PCSel		=2'b00; // pc = pc+4
                        RegSel	=2'b01; // ALU output
                        AluOp		=SUB; 	
                        regWE		=1'b1; // Write RegFile
                        memWE		=1'b0;  
                        rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                        rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                        memMode	=3'b000; //load word
                      end
                  endcase
                end
              3'b001: //sll
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=SLL; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b010: //slt
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=SLT; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b011: //sltu
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=ULT; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b100: //xor
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=XOR; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b101: //xor
                begin
                  case (funct7)
                    7'b0000000: //srl 
                      begin
                        PCSel		=2'b00; // pc = pc+4
                        RegSel	=2'b01; // ALU output
                        AluOp		=SRL; 	
                        regWE		=1'b1; // Write RegFile
                        memWE		=1'b0;  
                        rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                        rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                        memMode	=3'b000; //load word
                      end
                    7'b0100000: //sra 
                      begin
                        PCSel		=2'b00; // pc = pc+4
                        RegSel	=2'b01; // ALU output
                        AluOp		=SRA; 	
                        regWE		=1'b1; // Write RegFile
                        memWE		=1'b0;  
                        rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                        rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                        memMode	=3'b000; //load word
                      end
                  endcase
                end
              3'b110: //or
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=OR; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b111: //and
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=AND; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
            endcase
          end
        7'b0010011: // I-Type
          begin
            case (funct3)
              3'b000: //addi
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=ADD; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b001: //slli
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=SLL; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b010: //slti
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=SLT; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b011: //sltiu
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=ULT; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b100: //xori
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=XOR; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b101: //srli or srai (ver funct7)
                begin
                  case (funct7)
                    7'b0000000: //srli 
                      begin
                        PCSel		=2'b00; // pc = pc+4
                        RegSel		=2'b01; // ALU output
                        AluOp		=SRL; 	
                        regWE		=1'b1; // Write RegFile
                        memWE		=1'b0;  
                        rs1Sel		=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                        rs2Sel		=1'b1; // 0 -> Rs2; 1 -> Immediate;
                        memMode		=3'b000; //load word
                      end
                    7'b0100000: //srai 
                      begin
                        PCSel		=2'b00; // pc = pc+4
                        RegSel		=2'b01; // ALU output
                        AluOp		=SRA; 	
                        regWE		=1'b1; // Write RegFile
                        memWE		=1'b0;  
                        rs1Sel		=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                        rs2Sel		=1'b1; // 0 -> Rs2; 1 -> Immediate;
                        memMode		=3'b000; //load word
                      end
                  endcase
                end
              3'b110: //ori
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=OR; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b111: //andi
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=AND; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0;  
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
            endcase
          end
        7'b0000011: // load type
          begin
            case (funct3)
              3'b000: //lb
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b100; //load byte signed
                end
              3'b001: //lh
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b010; //load half signed
                end
              3'b010: //lw
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b100: //lbu
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b011; //load byte unsigned
                end
              3'b101: //lhu
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b1; // Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b001; //load half unsigned
                end
            endcase
          end
        7'b0100011: // store Type
          begin
            case (funct3)
              3'b000: //sb
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b0; // Write RegFile
                  memWE		=1'b1; // Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b100; // byte signed
                end
              3'b001: //sh
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b0; // Write RegFile
                  memWE		=1'b1; // Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b010; // half signed
                end
              3'b010: //sw
                begin
                  PCSel		=2'b00; // pc = pc+4
                  RegSel	=2'b00; // Memory output
                  AluOp		=ADD; 	
                  regWE		=1'b0; // Write RegFile
                  memWE		=1'b1; // Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; // byte signed
                end
            endcase
          end
        7'b1100011: // B-Type
          begin
            case (funct3)
              3'b000: //beq
                begin
                  PCSel		= (jump) ? 2'b10 : 2'b00; // jump=1 -> salta, jump==0 -> pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=EQ; 	
                  regWE		=1'b0; // Do NOT Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b001: //bne
                begin
                  PCSel		= (!jump) ? 2'b10 : 2'b00; // jump=1 -> salta, jump==0 -> pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=EQ; 	
                  regWE		=1'b0; // Do NOT Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word
                end
              3'b100: //blt
                 begin
                  PCSel		= (jump) ? 2'b10 : 2'b00; // jump=1 -> salta, jump==0 -> pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=SLT; 	
                  regWE		=1'b0; // Do NOT Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word  
                end
              3'b101: //bge
                begin
                  PCSel		= (jump) ? 2'b10 : 2'b00; // jump=1 -> salta, jump==0 -> pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=SGTE; 	
                  regWE		=1'b0; // Do NOT Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word  
                end
              3'b110: //bltu
                begin
                  PCSel		= (jump) ? 2'b10 : 2'b00; // jump=1 -> salta, jump==0 -> pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=ULT; 	
                  regWE		=1'b0; // Do NOT Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word 
                end
              3'b111: //bgeu
                begin
                  PCSel		= (jump) ? 2'b10 : 2'b00; // jump=1 -> salta, jump==0 -> pc = pc+4
                  RegSel	=2'b01; // ALU output
                  AluOp		=UGTE; 	
                  regWE		=1'b0; // Do NOT Write RegFile
                  memWE		=1'b0; // Do NOT Write Memory 
                  rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
                  rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
                  memMode	=3'b000; //load word 
                end
            endcase
          end
        7'b0110111: // lui
          begin
            PCSel		=2'b00; // pc = pc+4
            RegSel		= 2'b10; // immediate output
            AluOp		=ADD; 	
            regWE		=1'b1; // Write RegFile
            memWE		=1'b0; // do not Write Memory 
            rs1Sel		=1'b0; // 0 -> Rs1; 1 -> PC;
            rs2Sel		=1'b0; // 0 -> Rs2; 1 -> Immediate;
            memMode		=3'b000; // word
          end
        7'b0010111: // auipc
          begin
            PCSel	= 2'b00; // pc = pc+4
            RegSel	= 2'b01; // ula
            AluOp	=ADD; 	
            regWE	=1'b1; // Write RegFile
            memWE	=1'b0; // Write Memory 
            rs1Sel	=1'b1; // 0 -> Rs1; 1 -> PC;
            rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
            memMode	=3'b000; // word
            
          end
        7'b1101111: // jal
          begin
            PCSel	=2'b10; // pc = pc+immediate
            RegSel	= 2'b11; // pc+4
            AluOp		=ADD; 	
            regWE		=1'b1; // Write RegFile
            memWE		=1'b0; // Write Memory 
            rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
            rs2Sel	=1'b0; // 0 -> Rs2; 1 -> Immediate;
            memMode	=3'b000; // byte signed
          end
        7'b1100111: // jalr
          begin
            PCSel	=2'b01; // pc = rs1+immediate
            RegSel	= 2'b11; // pc+4
            AluOp	=ADD; 	
            regWE	=1'b1; // Write RegFile
            memWE	=1'b0; // Write Memory 
            rs1Sel	=1'b0; // 0 -> Rs1; 1 -> PC + 4;
            rs2Sel	=1'b1; // 0 -> Rs2; 1 -> Immediate;
            memMode	=3'b000; // byte signed
          end
      endcase
    end
endmodule

   
module mux2(
  input s,
  input [31:0] a,
  input [31:0] b,
  output [31:0] o);
  
  assign o = (s) ? a : b;
  
endmodule

module mux4(
  input [1:0] s,
  input [31:0] a,
  input [31:0] b,
  input [31:0] c,
  input [31:0] d,
  output reg [31:0] o);
  
  always @ (*)
    begin
      if(s == 2'b00)
        o = a;
      else if (s == 2'b01)
        o = b;
      else if (s == 2'b10)
        o = c;
      else //s == 2'b11
        o = d;
    end
  
endmodule


module adder(a, b, o);
  
  input [31:0] a, b;
  output [31:0] o;
  
  assign o = a + b;
  
endmodule

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

module riscv_datapath (clk, rst, gpio_o, i_addr, i_data, d_datar, d_dataw, d_addr, d_we, d_mode );

input clk, rst;
output [31:0] gpio_o;

output [31:0] i_addr;
input [31:0] i_data;

input [31:0] d_datar;
output [31:0] d_dataw;
output [31:0] d_addr; 
output d_we;
output [2:0] d_mode;




  wire [31:0] pc_w;
  wire [31:0] instr_w;
  wire [31:0] extimm_w; 
  wire [31:0] rs1out_w, rs2out_w; 
  wire rs1sel_w, rs2sel_w;
  wire [31:0] alu1_w, alu2_w;
  wire [3:0] ALUControl_w;
  wire regWE_w;
  wire [31:0] alu_out_w;
  wire memWE_w;
  wire [2:0] memMode_w;
  wire [1:0] RegSel_w;
  wire [31:0] datamemout_w, rd_data_w;
  wire [31:0] pc_plus_4_w, pc_plus_imm_w;
  wire [1:0] PCSel_w;
  wire [31:0] nextPC_w;

assign gpio_o = rd_data_w;

//Instruction Mem Interface
assign i_addr = pc_w;
assign instr_w = i_data;

//Data mem Interface
assign datamemout_w = d_datar;
assign d_dataw = rs2out_w;
assign d_addr = alu_out_w;
assign d_we = memWE_w;
assign d_mode = memMode_w;

  //extendImm (Instr, ExtImm);

  extendImm Extnd (.Instr(instr_w), .ExtImm(extimm_w) ); 

  //regfile (clk, rst, we, rs1, rs2, rd, wr_rd, rs1_o, rs2_o);

  regfile RegFile (.clk(clk), .rst(rst), .we(regWE_w), .rs1(instr_w[19:15]), .rs2(instr_w[24:20]), .rd(instr_w[11:7]), .wr_rd(rd_data_w), .rs1_o(rs1out_w), .rs2_o(rs2out_w));

  //control (instr, jump, PCSel, RegSel, AluOp, regWE, memWE, rs1Sel, rs2Sel, memMode) 

  control CONTROL (.instr(instr_w) , .jump(alu_out_w[0]), .PCSel(PCSel_w), .RegSel(RegSel_w), .AluOp(ALUControl_w), .regWE(regWE_w), .memWE(memWE_w), .rs1Sel(rs1sel_w), .rs2Sel(rs2sel_w), .memMode(memMode_w)) ;


  // mux2(s, a, b, o)

  mux2 Rs1MUX (.s(rs1sel_w), .a(rs1out_w), .b(pc_w), .o(alu1_w));

  mux2 Rs2MUX (.s(rs2sel_w), .a(rs2out_w), .b(extimm_w), .o(alu2_w));

  // ALU(a, b, ALUControl, result);

  ALU ALU (.a(alu1_w), .b(alu2_w), .ALUControl(ALUControl_w), .result(alu_out_w));

  // dmem (clk, reset, a, rd, wd, we, mode);

  //dmem DataMem (.clk(clk), .reset(rst), .a(alu_out_w), .rd(datamemout_w), .wd(rs2out_w), .we(memWE_w), .mode(memMode_w)); 

  //  mux4( s, a, b, c, d, o) 

  mux4 RegMux ( .s(RegSel_w), .a(datamemout_w), .b(alu_out_w), .c(extimm_w), .d(), .o(rd_data_w));

  // adder(a, b, o);

  adder ADD4(.a(pc_w), .b(32'd4), .o(pc_plus_4_w));

  adder ADD_IMM (.a(pc_w), .b(extimm_w), .o(pc_plus_imm_w));

  mux4 PCMux ( .s(PCSel_w), .a(pc_plus_4_w), .b(alu_out_w), .c(pc_plus_imm_w), .d(32'd0), .o(nextPC_w));

  //pc (clk, rst, a, o);
  pc PC (.clk(clk), .rst(rst), .a(nextPC_w), .o(pc_w));

endmodule
