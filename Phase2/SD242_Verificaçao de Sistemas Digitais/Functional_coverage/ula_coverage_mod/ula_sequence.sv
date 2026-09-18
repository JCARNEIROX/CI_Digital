class ula_sequence extends uvm_sequence #(ula_item);
    `uvm_object_utils(ula_sequence)

    // Configuração, não variáveis rand: o teste define estes valores.
    int unsigned num_transactions = 1000; // Quantidade da fase aleatória.
    bit run_corners = 1;
    int unsigned directed_count = 0;
    int unsigned type_count[5] = '{default: 0};

    typedef enum int unsigned {
        ITEM_MID, ITEM_LOW, ITEM_HIGH, ITEM_CORNER, ITEM_FULL
    } item_kind_t;

    function new(string name = "ula_sequence");
        super.new(name);
    endfunction

    // Atribuição dirigida não usa randomize() nem as restrições de sorteio.
    task send_directed(logic [2:0] operation,
                       logic [31:0] operand_a, logic [31:0] operand_b);
        ula_item trans;
        trans = ula_item::type_id::create("directed_item");
        start_item(trans);
        trans.opr = operation;
        trans.a   = operand_a;
        trans.b   = operand_b;
        finish_item(trans);
        directed_count++;
    endtask

    task send_corner_cases();
        // Um representante de cada bin de A/B, incluindo other_values.
        logic [31:0] values[9] = '{
            32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555,
            32'd2, 32'd1000, 32'hFFFFFFFE, 32'd101
        };

        // Seis operações binárias: 6 * 9 * 9 = 486 transações.
        for (int op = ula_item::OP_ADD; op <= ula_item::OP_OR; op++) begin
            foreach (values[i]) begin
                foreach (values[j]) begin
                    send_directed(op[2:0], values[i], values[j]);
                end
            end
        end

        // NOT não usa B: nove transações bastam para as categorias de A.
        foreach (values[i]) begin
            send_directed(ula_item::OP_NOT, values[i], 32'd0);
        end

        // Fronteiras adicionais da multiplicação em torno de 2**32.
        send_directed(ula_item::OP_MUL, 32'd65535, 32'd65535);
        send_directed(ula_item::OP_MUL, 32'd65536, 32'd65536);
        send_directed(ula_item::OP_MUL, 32'd65535, 32'd65536);
        send_directed(ula_item::OP_MUL, 32'd65536, 32'd65535);
    endtask

    virtual task body();
        ula_item trans_item;
        item_kind_t item_kind;

        directed_count = 0;
        foreach (type_count[i]) begin
            type_count[i] = 0;
        end
        if (run_corners) begin
            send_corner_cases();
        end

        for (int unsigned i = 0; i < num_transactions; i++) begin
            // O enum permite os cinco tipos com o mesmo peso no sorteio.
            if (!std::randomize(item_kind)) begin
                `uvm_fatal("SEQ_RANDOM", "Falha no sorteio do tipo de item")
            end

            case (item_kind)
                ITEM_MID:    trans_item = ula_item::type_id::create("mid_item");
                ITEM_LOW:    trans_item = facil_transaction::type_id::create("low_item");
                ITEM_HIGH:   trans_item = limite_transaction::type_id::create("high_item");
                ITEM_CORNER: trans_item = corner_transaction::type_id::create("corner_item");
                ITEM_FULL:   trans_item = full_range_transaction::type_id::create("full_item");
                default: `uvm_fatal("SEQ_KIND", "Tipo de item inválido")
            endcase

            start_item(trans_item);
            if (!trans_item.randomize()) begin
                `uvm_fatal("SEQ_RANDOM", "Falha ao randomizar operandos/operacao")
            end
            finish_item(trans_item);
            type_count[item_kind]++;
        end

        `uvm_info("SEQ_SUMMARY",
            $sformatf("Dirigidas=%0d Aleatorias=%0d Total=%0d | mid=%0d low=%0d high=%0d corner=%0d full=%0d",
                      directed_count, num_transactions, directed_count + num_transactions,
                      type_count[ITEM_MID], type_count[ITEM_LOW], type_count[ITEM_HIGH],
                      type_count[ITEM_CORNER], type_count[ITEM_FULL]), UVM_LOW)
    endtask
endclass
