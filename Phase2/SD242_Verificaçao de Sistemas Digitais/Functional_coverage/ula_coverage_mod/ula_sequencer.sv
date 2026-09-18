class ula_sequencer extends uvm_sequencer #(ula_item);
    `uvm_component_utils(ula_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

