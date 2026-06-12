`timescale 1ns / 1ps

module tb_pipeline;
  reg clk, reset;

  pipeline UUT (
    .clk  (clk),
    .reset(reset)
  );

  always #5 clk = ~clk;

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

    repeat (2) @(posedge clk);
    reset = 0;

    // 1) Inicializa registradores x5 e x9 
     UUT.reg_bank[5] = 32'd6;
     UUT.reg_bank[9] = 32'h0004;
    
    // Carrega as instruções nos endereços certos (palavras)
     UUT.instr_mem[32'h0000] = 32'hFFC4A303;  // lw
     UUT.instr_mem[32'h0001] = 32'h0064A423;  // sw
     UUT.instr_mem[32'h0002] = 32'h0062E233;  // or
     UUT.instr_mem[32'h0003] = 32'hFE420AE3;  // beq

    // Dados iniciais
     UUT.data_mem[32'h0010] = 32'd10;
    
    // Após um ciclo, solta o force para não atrapalhar escritas futuras
    @(posedge clk);
    release UUT.reg_bank[5];
    release UUT.reg_bank[9];

    // Executa por tempo suficiente para executar o codigo
    repeat (30) @(posedge clk);

    // Exibe resultados finais
    $display("\n========== RESULTADO FINAL ==========");
    $display("x4 = %0d", UUT.reg_bank[4]);
    $display("x5 = %0d", UUT.reg_bank[5]);
    $display("x6 = %0d", UUT.reg_bank[6]);
    $display("x9 = %h", UUT.reg_bank[9]);
    $display("Mem[h0100] = %0d", UUT.data_mem[32'h0100]);
    $display("Mem[h010C] = %0d", UUT.data_mem[32'h010C]);
    $finish;
  end
endmodule