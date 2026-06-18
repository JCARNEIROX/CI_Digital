module pipeline (
    input wire clk,
    input wire reset
);

  // ----------------------------------------------------------
  // 1. Declaração de memórias e banco de registradores
  // ----------------------------------------------------------
  reg [31:0] instr_mem [0:127];
  reg [31:0] data_mem  [0:300];
  reg [31:0] reg_bank  [0:31];

  // ----------------------------------------------------------
  // 2. Registradores de pipeline
  // ----------------------------------------------------------
  reg [31:0] if_id_instr;

  //Entre ID e EX
  reg [31:0] id_ex_rs1_val;   // valor lido de rs1 (32 bits)
  reg [31:0] id_ex_rs2_val;   // valor lido de rs2
  reg [31:0] id_ex_imm;       // imediato estendido
  reg [4:0]  id_ex_rd;        // registrador destino
  reg [6:0]  id_ex_op;        // opcode
  reg        id_ex_reg_write;
  reg        id_ex_mem_read;
  reg        id_ex_mem_write;
  reg        id_ex_alu_src;
  reg [2:0]  id_ex_alu_ctrl;

  //Entre EX e MEM
  reg [31:0] ex_mem_alu_res;
  reg [31:0] ex_mem_rs2_val;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_reg_write;
  reg        ex_mem_mem_read;
  reg        ex_mem_mem_write;

  //Entre MEM e WB
  reg [31:0] mem_wb_data;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_reg_write;

  // ----------------------------------------------------------
  // 3. PC
  // ----------------------------------------------------------
  reg [31:0] PC;

  // ----------------------------------------------------------
  // 4. IF (Instruction Fetch)
  // ----------------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      PC <= 32'h0000;          // início do programa
      if_id_instr <= 32'b0;
    end else begin
      if_id_instr <= instr_mem[PC[31:0]];   // índice = palavra
      PC <= PC + 1;
    end
  end

  // ----------------------------------------------------------
  // 5. ID (Instruction Decode + leitura dos registradores)
  // ----------------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      id_ex_rs1_val <= 0;
      id_ex_rs2_val <= 0;
      id_ex_imm <= 0;
      id_ex_rd <= 0;
      id_ex_op <= 0;
      id_ex_reg_write <= 0;
      id_ex_mem_read <= 0;
      id_ex_mem_write <= 0;
      id_ex_alu_src <= 0;
      id_ex_alu_ctrl <= 0;
    end else begin

      // leitura dos valores atuais do banco
      id_ex_rs1_val <= reg_bank[if_id_instr[19:15]];
      id_ex_rs2_val <= reg_bank[if_id_instr[24:20]];
      id_ex_rd <= if_id_instr[11:7];
      id_ex_op <= if_id_instr[6:0];

      // geração do imediato
      case (if_id_instr[6:0])
        7'b0000011: // lw
          id_ex_imm <= {{20{if_id_instr[31]}}, if_id_instr[31:20]};
        7'b0100011: // sw
          id_ex_imm <= {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
        7'b1100011: // beq
          id_ex_imm <= {{20{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8]};
        default: // R-type
          id_ex_imm <= 0;
      endcase

      // sinais de controle
      id_ex_reg_write <= (if_id_instr[6:0] == 7'b0110011) || (if_id_instr[6:0] == 7'b0000011); // R-type ou lw
      id_ex_mem_read  <= (if_id_instr[6:0] == 7'b0000011); // lw
      id_ex_mem_write <= (if_id_instr[6:0] == 7'b0100011); // sw
      id_ex_alu_src   <= (if_id_instr[6:0] == 7'b0000011) || (if_id_instr[6:0] == 7'b0100011); // lw ou sw

      // controle da ALU
      if (if_id_instr[6:0] == 7'b0110011) begin // R-type
        case ({if_id_instr[31:25], if_id_instr[14:12]})// funct7, funct3
          14'b0000000_000: id_ex_alu_ctrl <= 3'b000; // add
          14'b0100000_000: id_ex_alu_ctrl <= 3'b001; // sub
          14'b0000000_111: id_ex_alu_ctrl <= 3'b010; // and
          14'b0000000_110: id_ex_alu_ctrl <= 3'b011; // or
          14'b0000000_010: id_ex_alu_ctrl <= 3'b100; // slt
          default: id_ex_alu_ctrl <= 0;
        endcase
      end else if (if_id_instr[6:0] == 7'b0000011) begin // lw
        id_ex_alu_ctrl <= 3'b000; // add (base + imediato)
      end else begin
        id_ex_alu_ctrl <= 0;
      end
    end
  end

  // ----------------------------------------------------------
  // 6. EX (Execute / ALU)
  // ----------------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      ex_mem_alu_res <= 0;
      ex_mem_rs2_val <= 0;
      ex_mem_rd <= 0;
      ex_mem_reg_write <= 0;
      ex_mem_mem_read <= 0;
      ex_mem_mem_write <= 0;
    end else begin
      reg [31:0] alu_src_b;
      reg [31:0] alu_result;

      alu_src_b = id_ex_alu_src ? id_ex_imm : id_ex_rs2_val; // escolha entre registrador ou imediato

      case (id_ex_alu_ctrl)
        3'b000: alu_result = id_ex_rs1_val + alu_src_b;
        3'b001: alu_result = id_ex_rs1_val - alu_src_b;
        3'b010: alu_result = id_ex_rs1_val & alu_src_b;
        3'b011: alu_result = id_ex_rs1_val | alu_src_b;
        3'b100: alu_result = ($signed(id_ex_rs1_val) < $signed(alu_src_b)) ? 1 : 0;
        default: alu_result = 0;
      endcase

      ex_mem_alu_res <= alu_result;
      ex_mem_rs2_val <= id_ex_rs2_val;
      ex_mem_rd <= id_ex_rd;
      ex_mem_reg_write <= id_ex_reg_write;
      ex_mem_mem_read <= id_ex_mem_read;
      ex_mem_mem_write <= id_ex_mem_write;
    end
  end

  // ----------------------------------------------------------
  // 7. MEM (Memory Access)
  // ----------------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      mem_wb_data <= 0;
      mem_wb_rd <= 0;
      mem_wb_reg_write <= 0;
    end else begin
      if (ex_mem_mem_read) begin
        mem_wb_data <= data_mem[ex_mem_alu_res[31:0]];
      end else begin
        mem_wb_data <= ex_mem_alu_res;
      end

      if (ex_mem_mem_write) begin
        data_mem[ex_mem_alu_res[31:0]] <= ex_mem_rs2_val;
      end

      mem_wb_rd <= ex_mem_rd;
      mem_wb_reg_write <= ex_mem_reg_write;
    end
  end

  // ----------------------------------------------------------
  // 8. WB (Write Back)
  // ----------------------------------------------------------
  always @(posedge clk) begin
    if (!reset && mem_wb_reg_write && (mem_wb_rd != 0)) begin
      reg_bank[mem_wb_rd] <= mem_wb_data;
      $display("[WB] Ciclo: %0t | Escreveu x%0d = %0d", $time, mem_wb_rd, mem_wb_data);
    end
  end

endmodule