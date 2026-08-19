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
  localparam NE   =4'b1101;

  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;

  assign opcode = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];
  
  

 // memWE = 1'b0;
 // memMode;
  
  
  
  always @(*) 
    begin
      case (opcode)
        7'b0110011: // R-Type
          begin
            regWE 	= 1'b1;
            rs1Sel 	= 1'b0;
            rs2Sel 	= 1'b0;
            RegSel 	= 2'd1;
            PCSel 	= 2'd0;
            
            case (funct3)
              3'b000: // add or sub
                begin
                  if(funct7[5] == 1'b0) //ADD
                    AluOp = ADD;
                  else //SUB
                    AluOp = SUB;             		
                end
               3'b001: // SLL
                 begin
                 AluOp = SLL;
                 end
              3'b010: // SLT
                 begin
                 AluOp = SLT;
                 end
              3'b011: // SLTU
                 begin
                 AluOp = ULT;
                 end
              3'b100: // XOR
                 begin
                 AluOp = XOR;
                 end
              3'b101: // SRL or SRA
                 begin
                   if(funct7 == 7'b0000000) //SRL
                    AluOp = SRL;
                   else if(funct7 == 7'b0100000) //SRA
                    AluOp = SRA;
                   else
                     AluOp = ADD;
                 end
              3'b110: // OR
                 begin
                 AluOp = OR;
                 end
              3'b111: // AND
                 begin
                 AluOp = AND;
                 end
              default:
                begin
                 AluOp = ADD;
                end
            endcase
          end
        7'b0010011: // I-Type
          begin
            regWE 	= 1'b1;
            rs1Sel 	= 1'b0;
            rs2Sel 	= 1'b1;
            RegSel 	= 2'd1;
            PCSel 	= 2'd0;
            
            // Falta definir AluOp
            
          end
        
        7'b1100011: // B-Type
          begin
            regWE 	= 1'b0;
            rs1Sel 	= 1'b0;
            rs2Sel 	= 1'b0;
            RegSel 	= 2'd1;
            PCSel 	= (jump) ? 2'd2 : 2'd0;
            
             case (funct3)
              3'b000: //BEQ
                begin
                  AluOp = EQ;
                end
               3'b001: //BNE
                begin
                  AluOp = NE;
                end
               3'b100: //BLT
                begin
                  AluOp = SLT;
                end
                3'b101: //BGE
                begin
                  AluOp = SGTE;
                end
               3'b110: //BLTU
                begin
                  AluOp = ULT;
                end
                3'b111: //BGEU
                begin
                  AluOp = UGTE;
                end
               defaut:
                 begin
                  AluOp = ADD;
                end
             endcase     
          end
        7'b1100111: // JALR
          begin
            regWE 	= 1'b1;
            rs1Sel 	= 1'b0;
            rs2Sel 	= 1'b1;
            RegSel 	= 2'd3;
            PCSel 	= 2'd1;
            AluOp 	= ADD;
          end
        7'b1101111: // JAL
          begin
            regWE 	= 1'b1;
            rs1Sel 	= 1'b1;
            rs2Sel 	= 1'b1;
            RegSel 	= 2'd3;
            PCSel 	= 2'd2;
            AluOp 	= ADD;
          end
        7'b0010111: // AUIPC
          begin
            regWE 	= 1'b1;
            rs1Sel 	= 1'b1;
            rs2Sel 	= 1'b1;
            RegSel 	= 2'd1;
            PCSel 	= 2'd0;
            AluOp 	= ADD;
          end
        7'b0110111: // LUI
          begin
            regWE 	= 1'b1;
            rs1Sel 	= 1'b0;
            rs2Sel 	= 1'b1;
            RegSel 	= 2'd2;
            PCSel 	= 2'd0;
            AluOp 	= ADD;
          end
        
        
        
      endcase
    end	           
endmodule