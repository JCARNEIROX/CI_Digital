`timescale 1ns / 1ps

module tb_pipeline;
  reg clk, reset;

  pipeline UUT (
    .clk  (clk),
    .reset(reset)
  );

  always #5 clk = ~clk;
  integer i;

  initial begin
    $dumpfile("pipeline.vcd"); 
    $dumpvars(0, tb_pipeline);
    // Do livro Digital Design RISC-V Harrys
    // { 7'b_imm_func7, 5'br_source2, 5'b_rsource1, 3'b_func3, 5'b_rdest_imm, 7'b_opcode }

    /*Address (label) Instruction 	Type 	Fields 								Machine Language
		0x1000   L7: lw x6, -4(x9) 		I 	111111111100 01001 010 00110 0000011  FFC4A303
		0x1004 		 sw x6, 8(x9) 		S 	0000000 00110 01001 010 01000 0100011 0064A423
		0x1008 		 or x4, x5, x6 		R 	0000000 00110 00101 110 00100 0110011 0062E233
		0x100C 		 beq x4, x4, L7		B 	1111111 00100 00100 000 10101 1100011 FE420AE3
    */
    clk = 0;
    reset = 1;

    // ------------------------------------------------------
    // Inicialização básica
    // ------------------------------------------------------
    for (i = 0; i < 128; i = i + 1)
      UUT.instr_mem[i] = 32'b0;

    for (i = 0; i < 301; i = i + 1)
      UUT.data_mem[i] = 32'b0;

    for (i = 0; i < 32; i = i + 1)
      UUT.reg_bank[i] = 32'b0;


// ------------------------------------------------------
    // Inicializa registradores
    // ------------------------------------------------------
    UUT.reg_bank[5] = 32'd6;       // x5 = 6
    UUT.reg_bank[9] = 32'h0004;    // x9 = 4

    // ------------------------------------------------------
    // Programa
    //
    // 0: lw  x6, -4(x9)
    // 1: sw  x6, 8(x9)
    // 2: or  x4, x5, x6
    // 3: beq x4, x4, L7
    // ------------------------------------------------------
    UUT.instr_mem[32'h0000] = 32'hFFC4A303;  // lw x6, -4(x9)
    UUT.instr_mem[32'h0001] = 32'h0064A423;  // sw x6, 8(x9)
    UUT.instr_mem[32'h0002] = 32'h0062E233;  // or x4, x5, x6
    UUT.instr_mem[32'h0003] = 32'hFE420AE3;  // beq x4, x4, L7

    // ------------------------------------------------------
    // Dados iniciais
    //
    // lw x6, -4(x9)
    // x9 = 4
    // endereço = 4 - 4 = 0
    // ------------------------------------------------------
    UUT.data_mem[32'h0000] = 32'd10;

    // Mantém reset por alguns ciclos
    repeat (2) @(posedge clk);
    reset = 0;

    // Executa por tempo suficiente
    repeat (30) @(posedge clk);

    // ------------------------------------------------------
    // Resultados esperados:
    //
    // x6 = 10
    // x4 = x5 OR x6 = 6 OR 10 = 14
    // sw x6, 8(x9) => endereço = 4 + 8 = 12
    // data_mem[12] = 10
    // ------------------------------------------------------
    $display("\n========== RESULTADO FINAL ==========");
    $display("x4 = %0d", UUT.reg_bank[4]);
    $display("x5 = %0d", UUT.reg_bank[5]);
    $display("x6 = %0d", UUT.reg_bank[6]);
    $display("x9 = %h", UUT.reg_bank[9]);
    $display("Mem[0]  = %0d", UUT.data_mem[32'h0000]);
    $display("Mem[12] = %0d", UUT.data_mem[32'h000C]);

    $finish;
  end
endmodule