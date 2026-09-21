
module datapath_sc (clk, rst, i_addr, i_data, d_datar, d_dataw, d_addr, d_we, d_mode );

input clk, rst;
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

  mux2 Rs1MUX (.sel(rs1sel_w), .a(rs1out_w), .b(pc_w), .o(alu1_w));

  mux2 Rs2MUX (.sel(rs2sel_w), .a(rs2out_w), .b(extimm_w), .o(alu2_w));

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
