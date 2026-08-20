class add_sequencer extends uvm_sequencer #(add_item);
    `uvm_component_utils(add_sequencer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass