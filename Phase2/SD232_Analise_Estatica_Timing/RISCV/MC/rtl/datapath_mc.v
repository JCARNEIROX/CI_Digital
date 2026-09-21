module datapath_mc (clk, rst, i_addr, i_data, d_datar, d_dataw, d_addr, d_we, d_mode );

input clk, rst;


input [31:0] d_datar;
input [31:0] i_data;
output [31:0] i_addr;
output [31:0] d_dataw;
output [31:0] d_addr; 
output d_we;
output [2:0] d_mode;  

  
  
  reg [31:0] IF_IR; 
  reg [31:0] ID_IR, ID_alu_a, ID_alu_b, ID_memData, ID_ExtImm;
  reg [1:0] ID_PCSel, ID_RegSel;
  reg [3:0] ID_AluOp;
  reg ID_regWE, ID_memWE;
  reg [2:0] ID_memMode;
  
  
  reg [31:0] EX_IR, EX_memData, EX_alu_res, EX_ExtImm;
  
  reg [1:0] EX_PCSel, EX_RegSel;
  reg EX_regWE, EX_memWE;
  reg [2:0] EX_memMode;
  
  
  
  reg [31:0] MEM_IR, MEM_wreg, MEM_data, MEM_ExtImm, MEM_alu_res;
    reg [1:0] MEM_PCSel, MEM_RegSel;
  reg MEM_regWE;

 
  
  
  wire [31:0] pc_w, imen_addr_w, inst_w;
  wire [31:0] rs1_w, rs2_w, wreg_w, ExtImm_w;
  wire regWE_w, rs1Sel_w, rs2Sel_w;
  wire [31:0] alu_a_w, alu_b_w, alu_res_w;
  wire [3:0] ALUControl_w;
  wire memWE_w;
  wire [2:0] memMode_w;
  wire [31:0] data_w;
  wire [1:0] RegSel_w;
  wire [31:0] pcadder4_w, pcadderimm_w;
  wire [1:0] PCSel_w;
  
  pc PC (.clk(clk), .rst(rst), .a(pc_w), .o(imen_addr_w));
  
  //Conect IMEM
  assign inst_w = i_data;
  assign i_addr = imen_addr_w;
  
 
  // IF/ID
  always @(posedge rst or posedge clk)
    begin
      if(rst)
        begin
        IF_IR <= 32'd0;
        end
      else
        begin
        IF_IR <= inst_w;
        end
    end
  
  regfile REGFILE (.clk(clk), .rst(rst), .we(EX_regWE), .rs1(IF_IR[19:15]), .rs2(IF_IR[24:20]), .rd(IF_IR[11:7]), .wr_rd(wreg_w), .rs1_o(rs1_w), .rs2_o(rs2_w));
  
  extendImm EXTENDIMM (.Instr(IF_IR), .ExtImm(ExtImm_w));
  
  control CONTROL (.instr(IF_IR), .jump(alu_res_w[0]), .PCSel(PCSel_w), .RegSel(RegSel_w), .AluOp(ALUControl_w), .regWE(regWE_w), .memWE(memWE_w), .rs1Sel(rs1Sel_w), .rs2Sel(rs2Sel_w), .memMode(memMode_w));
  
  mux2 MUX_REG1 (.a(rs1_w), .b(imen_addr_w), .sel(rs1Sel_w), .o(alu_a_w));
  mux2 MUX_REG2 (.a(rs2_w), .b(ExtImm_w), .sel(rs2Sel_w), .o(alu_b_w));
  //ID/EX
    always @(posedge rst or posedge clk)
    begin
      if(rst)
        begin
        ID_IR <= 32'd0;
        ID_alu_a <= 32'd0;
        ID_alu_b <= 32'd0;
        ID_memData <= 32'd0;
        ID_ExtImm <= 32'd0;
        ID_PCSel <= 2'd0;
        ID_RegSel <= 2'd0;
        ID_AluOp<= 4'd0;
        ID_regWE <= 1'd0;
        ID_memWE <= 1'd0;
        ID_memMode <= 3'd0;
        end
      else
        begin
        ID_IR <= IF_IR;
        ID_alu_a <= alu_a_w;
        ID_alu_b <= alu_b_w;
        ID_memData <= rs2_w;
        ID_ExtImm <= ExtImm_w;
        ID_PCSel <= PCSel_w;
        ID_RegSel <= RegSel_w;
        ID_AluOp<= ALUControl_w;
        ID_regWE <= regWE_w;
        ID_memWE <= memWE_w;
        ID_memMode <= memMode_w;
        end
    end
   
  
  ALU ALU (.a(ID_alu_a), .b(ID_alu_b), .ALUControl(ID_AluOp), .result(alu_res_w));
  
   //EX/MEM
    always @(posedge rst or posedge clk)
    begin
      if(rst)
        begin
        EX_IR <= 32'd0;
        EX_memData <= 32'd0;
        EX_alu_res <= 32'd0;
        EX_ExtImm <= 32'd0;
        EX_PCSel <= 2'd0;
        EX_RegSel <= 2'd0;
        EX_regWE <= 1'd0;
        EX_memWE <= 1'd0;
        EX_memMode <= 3'd0;
        end
      else
        begin
        EX_IR <= ID_IR;
        EX_memData <= ID_memData;
        EX_alu_res <= alu_res_w;
        EX_ExtImm <= ID_ExtImm;
        EX_PCSel <= ID_PCSel;
        EX_RegSel <= ID_RegSel;
        EX_regWE <= ID_regWE;
        EX_memWE <= ID_memWE;
        EX_memMode <= ID_memMode;
        end
    end
  
  //conect data memory
  
  assign d_addr = EX_alu_res;
  assign d_dataw = EX_memData;
  assign data_w = d_datar;
  assign d_we = EX_memWE;
  assign d_mode = EX_memMode;
  
  
  // MEM/WB
  always @(posedge rst or posedge clk)
    begin
      if(rst)
        begin
        MEM_IR <= 32'd0;
        MEM_wreg <= 32'd0;
        MEM_regWE <= 1'd0;
        end
      else
        begin
        MEM_IR <= EX_IR;
        MEM_wreg <= wreg_w;
        MEM_regWE <= EX_regWE; 
        MEM_data <= data_w;
        MEM_alu_res <= EX_alu_res;
        MEM_RegSel <= EX_RegSel ;
        MEM_ExtImm <=  EX_ExtImm ;
          
        end
    end
  
  mux4 RegMux ( .s(MEM_RegSel), .a(MEM_data), .b(MEM_alu_res), .c(MEM_ExtImm), .d(pcadder4_w), .o(wreg_w));
  
  adder ADD4 (.a(32'd4), .b(imen_addr_w), .o(pcadder4_w)); //PC + 4
  
  adder ADD_IMM (.a(ExtImm_w), .b(imen_addr_w), .o(pcadderimm_w)); //PC + IMM
  
  mux4 PCMux ( .s(ID_PCSel), .a(pcadder4_w), .b(EX_alu_res), .c(pcadderimm_w), .d(32'd0), .o(pc_w));
  
  
endmodule
