class ula_sequence extends uvm_sequence #(ula_item);
    `uvm_object_utils(ula_sequence)
    
    rand int num_transactions = 10;
    rand bit rand_item;
    constraint rand_i { rand_item inside {0 , 1}; }

    function new(string name = "ula_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        ula_item trans_item;

        for (int i = 0; i < num_transactions; i++) begin


	    if (!std::randomize(rand_item)) begin
                `uvm_error("SEQ", "Randomization failed: std::randomize(rand_item)")
            end

	    `uvm_info("[SEQ1] ", $sformatf("Class sel: %d", rand_item), UVM_LOW)

            if (rand_item == 1'b0) trans_item = facil_transaction::type_id::create("facil_transaction");
	    else trans_item = limite_transaction::type_id::create("limite_transaction");

            start_item(trans_item);

            if (!trans_item.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end

            finish_item(trans_item);

           `uvm_info("[SEQ] ", $sformatf(" Generated: %s", trans_item.convert2string()), UVM_LOW)
        end
    endtask
    
endclass
