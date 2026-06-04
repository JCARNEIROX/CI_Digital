// Code your testbench here
// or browse Examples

module pipeline_tb;
	reg clk;
	reg reset;
    // Instancia a DUT
	pipeline UUT (
		.clk(clk),
		.reset(reset)
	);
    // Clock de 10ns
  initial begin
      clk = 0;
      forever #5 clk = ~clk;
  end

  // Reset
  initial begin
      reset = 1;
      #13;
      reset = 0;
    
    // O programa é carregados nas memorias de instrucao e dados
    // Problema: Array de 10 posicoes preenchido com -> 
    // index atual soma com valor anterior. A[0] = 0, A[i] = i + A[i-1], p/ i>0
    //
    // { 7'b_imm_func7, 5'br_source2, 5'b_rsource1, 3'b_func3, 5'b_rdest_imm, 7'b_opcode }
    //
    // opcode (7 bits): Partially specifies one of the 6 types of instruction formats.
    // funct7 (7 bits) and funct3 (3 bits): These two fields extend the opcode field to specify the operation to be performed.
    // rs1 (5 bits) and rs2 (5 bits): Specify, by index, the first and second operand registers respectively (i.e., source registers).
    // rd (5 bits): Specifies, by index, the destination register to which the computation result will be directed
  
    UUT.instr_mem [0] = { 7'b000000, 5'b0_0000, 5'b0000_1, 3'b000, 5'b0001_1, 7'b000_0011};
    UUT.instr_mem [1] = { 7'b000000, 5'b0_0000, 5'b0001_0, 3'b000, 5'b0010_0, 7'b000_0011};
    UUT.instr_mem [2] = { 7'b000000, 5'b0_0011, 5'b0010_0, 3'b000, 5'b0011_1, 7'b011_0011};
    UUT.instr_mem [3] = { 7'b000000, 5'b00000, 5'b00000, 3'b000, 5'b00000, 7'b0000000};
    UUT.instr_mem [4] = { 7'b000000, 5'b00000, 5'b00000, 3'b000, 5'b00000, 7'b0000000};
    UUT.instr_mem [5] = { 7'b000000, 5'b00000, 5'b00000, 3'b000, 5'b00000, 7'b0000000};
    UUT.instr_mem [6] = { 7'b000000, 5'b00000, 5'b00000, 3'b000, 5'b00000, 7'b0000000};
    UUT.instr_mem [7] = { 7'b000000, 5'b00000, 5'b00000, 3'b000, 5'b00000, 7'b0000000};
    UUT.instr_mem [8] = { 7'b000000, 5'b00000, 5'b00000, 3'b000, 5'b00000, 7'b0000000};
    
    // preenchendo memoria de dados
    for (int i = 0; i < 10; i = i + 1) UUT.data_mem[i] = i;
    
  end

  // Tempo total de simulação
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    #200;
    $finish;
  end

endmodule