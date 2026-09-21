`include "uvm_macros.svh"
import uvm_pkg::*;

class ula_item extends uvm_sequence_item;
    `uvm_object_utils(ula_item)

    rand logic [31:0] a;
    rand logic [31:0] b;
    rand logic [2:0] opr;
    logic [63:0] result;
    logic carry_o;
    logic zero;

    // Operações (mesmos códigos usados no RTL)
    localparam logic [2:0] OP_ADD = 3'b000;
    localparam logic [2:0] OP_SUB = 3'b001;
    localparam logic [2:0] OP_MUL = 3'b010;
    localparam logic [2:0] OP_DIV = 3'b011;
    localparam logic [2:0] OP_AND = 3'b100;
    localparam logic [2:0] OP_OR  = 3'b101;
    localparam logic [2:0] OP_NOT = 3'b110;

    constraint opr_val {
        opr inside {[OP_ADD:OP_NOT]};
    }

    constraint reasonable_values {
        a inside {[32'd1000:32'd2000]};
        b inside {[32'd1000:32'd2000]};
    }

    // SUB com a <= b e DIV por zero sao comportamentos definidos no RTL.
    // Não os excluímos: precisam aparecer nos testes e no coverage.

    function new(string name = "ula_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s: opr=%0d a=0x%08h b=0x%08h -> result=0x%016h carry=%0b zero=%0b",
                         get_type_name(), opr, a, b, result, carry_o, zero);
    endfunction
    
endclass

class facil_transaction extends ula_item;
    `uvm_object_utils(facil_transaction)

    constraint reasonable_values {
        a inside {[0:32'd100]};
        b inside {[32'd0:32'd100]};
    }

    function new(string name = "facil_transaction");
        super.new(name);
    endfunction

endclass

class limite_transaction extends ula_item;
    `uvm_object_utils(limite_transaction)

    constraint reasonable_values {
        a inside {[32'hFFFFFF00:32'hFFFFFFFF]};
        b inside {[32'hFFFFFF00:32'hFFFFFFFF]};
    }

    function new(string name = "limite_transaction");
        super.new(name);
    endfunction

endclass

class corner_transaction extends ula_item;
    `uvm_object_utils(corner_transaction)

    constraint reasonable_values {
        a inside {32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555};
        b inside {32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555};
    }

    function new(string name = "corner_transaction");
        super.new(name);
    endfunction
endclass

class full_range_transaction extends ula_item;
    `uvm_object_utils(full_range_transaction)

    constraint reasonable_values {
        a inside {[32'd0:32'hFFFFFFFF]};
        b inside {[32'd0:32'hFFFFFFFF]};
    }

    function new(string name = "full_range_transaction");
        super.new(name);
    endfunction
endclass
