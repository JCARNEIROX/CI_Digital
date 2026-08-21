class add_item extends uvm_sequence_item;
    `uvm_object_utils(add_item)
    
    rand logic [7:0] data_in;
    logic [7:0] data_out;
    rand logic enable;
    
    // Constraints para valores razoáveis
    constraint reasonable_values {
        data_in inside {[0:8'hFF]};
    }
    
    function new(string name = "add_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("enable=%b, data_in=0x%2h -> data_out=0x%2h", enable, data_in, data_out);
    endfunction
    
endclass