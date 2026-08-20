class add_item extends uvm_sequence_item;
    `uvm_object_utils(add_item)
    
    rand logic [31:0] a;
    rand logic [31:0] b;
    logic [31:0] result;
    logic carry_o;
    
    // Constraints para valores razoáveis
    constraint reasonable_values {
        a inside {[0:32'hFFFFFFFF]};
	b inside {[0:32'hFFFFFFFF]};
    }
    constraint limite_values {
        b > 32'h00FFFFFF;
    }
    
    function new(string name = "add_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("a=0x%8h, b=0x%8h -> result=0x%8h, carry_o=%0d", 
                         a, b, result, carry_o);
    endfunction
    
endclass