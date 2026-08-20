class add_sequence extends uvm_sequence #(add_item);
    `uvm_object_utils(add_sequence)
    
    rand int num_transactions = 10;
    
    function new(string name = "add_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        add_item trans_item;
        
        for (int i = 0; i < num_transactions; i++) begin
            trans_item = add_item::type_id::create($sformatf("add_item%0d", i));
            start_item(trans_item);
            if (!trans_item.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            finish_item(trans_item);
            `uvm_info("SEQ", $sformatf("Generated: %s", trans_item.convert2string()), UVM_LOW)
        end
    endtask
    
endclass