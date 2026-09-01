class add_item extends uvm_sequence_item;
    `uvm_object_utils(add_item)

    rand logic                      w_en;
    rand logic                      r_en;
    rand logic [ADDR_WIDTH-1:0]     addr;
    rand logic [DATA_WIDTH-1:0]     data_in;
         logic [DATA_WIDTH-1:0]     data_out;
    
    function new(string name = "add_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("w_en=%b r_en=%b addr=0x%0h data_in=0x%0h data_out=0x%0h",
                         w_en, r_en, addr, data_in, data_out);
    endfunction
    
endclass
