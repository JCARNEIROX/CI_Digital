module pipeline ( 
    input wire clk, 
    input wire reset 
);
  
  //registradores de Pipeline (Buffers entre estágios)
  reg [31:0] if_id_instr; 
  
  reg [6:0]  id_ex_op;      // Corrigido para 7 bits (Opcode do RISC-V)
  reg [4:0]  id_ex_rd;      // Passando o registrador de destino adiante
  reg [4:0]  id_ex_rs1_val; // Valores lidos do banco
  reg [4:0]  id_ex_rs2_val;
  
  reg [31:0] ex_mem_res;
  reg [4:0]  ex_mem_rd;     // Passando o destino para o estágio MEM
  reg [6:0]  ex_mem_op;
  
  reg [31:0] mem_wb_data;
  reg [4:0]  mem_wb_rd;     // Passando o destino para o estágio WB
  
  // PC e Memórias 
  reg [3:0]  PC;
  
  reg [31:0] instr_mem [10];
  reg [31:0] data_mem  [10];
  reg [31:0] register_bank [10]; // Padrão RISC-V são 32 registradores
  
  // ---------- IF: Instruction Fetch (Busca)
  always @(posedge clk or posedge reset) begin 
    if (reset) begin
        if_id_instr <= 32'b0;
        PC          <= 4'd0; // Inicializa no endereço 0
    end else begin
        PC          <= PC + 1'b1; // Incrementa de 1 em 1 porque a memória foi declarada por palavra
        if_id_instr <= instr_mem[PC];
    end
  end

  // ---------- ID: Instruction Decode (Decodificação e Leitura de Regs)
  integer i;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
        id_ex_op      <= 7'b0;
        id_ex_rd      <= 5'b0;
        id_ex_rs1_val <= 32'b0;
        id_ex_rs2_val <= 32'b0;

      for (i = 0; i < 10; i = i + 1) begin
            register_bank[i] <= {32'b0};
        end

    end else begin
        id_ex_op      <= if_id_instr[6:0];   // Captura os 7 bits corretos do opcode
        id_ex_rd      <= if_id_instr[11:7];  // Campo rd
        
        // Simulação da leitura do banco de registradores usando os campos rs1 [19:15] e rs2 [24:20]
        id_ex_rs1_val <= if_id_instr[19:15];
        id_ex_rs2_val <= if_id_instr[24:20];
    end
  end

  // ---------- EX: Execute (ALU)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
        ex_mem_res <= 32'b0;
        ex_mem_rd  <= 5'b0;
    end else begin
      
        ex_mem_rd <= id_ex_rd; // Propaga o registrador de destino para o próximo estágio
      if (id_ex_op == 7'b000_0011) begin // Opcode do LW - valor de rs1 index de MEM 
           ex_mem_res <= id_ex_rs1_val; 
      end else if (id_ex_op == 7'b011_0011) begin // Tipo-R / ADD
           ex_mem_res <= register_bank[id_ex_rs1_val] + register_bank[id_ex_rs2_val]; // Soma real dos valores lidos
      end else if (id_ex_op == 7'b001_0011) begin // Tipo-R (ex: SUB)
           ex_mem_res <= register_bank[id_ex_rs1_val] - register_bank[id_ex_rs2_val];
      end else begin
            ex_mem_res <= 32'd0;
      end
      
        ex_mem_op <= id_ex_op ;//var para levar dado para mem
    end
  end

  // ---------- MEM: Memory Access
  always @(posedge clk or posedge reset) begin
    if (reset) begin
        mem_wb_data <= 32'b0;
        mem_wb_rd   <= 5'b0;
    end else begin
      if (id_ex_op == 7'b0000011) begin // Se for LW
        // O dado REAL é pego da memória de dados usando o endereço que a ULA calculou
        mem_wb_data <= data_mem[ex_mem_res]; 
      end else begin
          // Se for ADD/SUB, o dado é apenas o próprio resultado da ULA
            mem_wb_data <= ex_mem_res;
          end
          mem_wb_rd   <= ex_mem_rd;  // Propaga o destino
  	end
  end

  
  // ---------- WB: Writeback (Escrita de volta no Banco)
  always @(posedge clk) begin 
    if (!reset) begin // RISC-V não escreve no registrador x0
        register_bank[mem_wb_rd] <= mem_wb_data;
        $display("[WB] Ciclo: %0t | Escreveu no reg x%0d o valor = %0d", $time, mem_wb_rd, mem_wb_data);
    end
  end

endmodule