class add_sequence extends uvm_sequence #(add_item);
    `uvm_object_utils(add_sequence)
    
    int unsigned num_transactions = 10;
    int unsigned read_latency = 2;
    
    function new(string name = "add_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        add_item trans_item;
        
        // Populate known locations first so every read has a defined expectation.
        for (int i = 0; i < num_transactions; i++) begin
            trans_item = add_item::type_id::create($sformatf("add_item%0d", i));
            start_item(trans_item);
            trans_item.w_en    = 1'b1;
            trans_item.r_en    = 1'b0;
            trans_item.addr    = i;
            trans_item.data_in = DATA_WIDTH'(16'h100 + i);
            finish_item(trans_item);
        end

        // The DUT accepts one read request at a time and responds two cycles later.
        for (int i = 0; i < num_transactions; i++) begin
            trans_item = add_item::type_id::create($sformatf("read_item%0d", i));
            start_item(trans_item);
            trans_item.w_en    = 1'b0;
            trans_item.r_en    = 1'b1;
            trans_item.addr    = i;
            trans_item.data_in = '0;
            finish_item(trans_item);

            repeat (read_latency) begin
                trans_item = add_item::type_id::create("idle_item");
                start_item(trans_item);
                trans_item.w_en    = 1'b0;
                trans_item.r_en    = 1'b0;
                trans_item.addr    = '0;
                trans_item.data_in = '0;
                finish_item(trans_item);
            end
        end
    endtask
    
endclass
