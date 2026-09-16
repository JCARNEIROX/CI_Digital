
class ula_item extends uvm_sequence_item;
    `uvm_object_utils(ula_item)
    
    rand logic [31:0] a;
    rand logic [31:0] b;
    rand logic [2:0] opr;
    logic [63:0] result;
    logic carry_o;
    logic zero;

    // Operações (mesmos códigos usados no RTL)
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_MUL = 3'b010;
    localparam OP_DIV = 3'b011;
    localparam OP_AND = 3'b100;
    localparam OP_OR  = 3'b101;
    localparam OP_NOT = 3'b110;

    constraint opr_val {
	opr inside {0,1};
    }

    constraint reasonable_values {
        a inside {[32'd1000:32'd2000]};
	b inside {[32'd1000:32'd2000]};
    }

    constraint operacao_subtrair {
        (opr == OP_SUB) -> (a > b);
    }

    constraint operacao_dividir {
        (opr == OP_DIV) -> (b != 32'b0);
    }

    function new(string name = "ula_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf( "%s: a=0x%8h, b=0x%8h -> result=0x%8h, carry_o=%0d", get_type_name(), 
                         a, b, result, carry_o);
    endfunction
    
endclass

class facil_transaction extends ula_item;
    `uvm_object_utils(facil_transaction)

    constraint reasonable_values {
        a inside {[0:32'd100]};
	b inside {[0:32'd100]};
    }

    function new(string name = "facil_transaction");
        super.new(name);
    endfunction

endclass

class limite_transaction extends ula_item;
    `uvm_object_utils(limite_transaction)

    constraint reasonable_values {
        a > {32'hFFFFFF00};
	b > {32'hFFFFFF00};
    }

    function new(string name = "limite_transaction");
        super.new(name);
    endfunction

endclass
