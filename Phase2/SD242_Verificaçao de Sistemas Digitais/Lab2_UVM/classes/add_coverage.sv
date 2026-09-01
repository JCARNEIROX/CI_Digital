class add_coverage extends uvm_subscriber #(add_item);
    `uvm_component_utils(add_coverage)

    logic w_en;
    logic r_en;
    logic [ADDR_WIDTH-1:0] addr;

    covergroup transaction_cg;
        option.per_instance = 1;
        write_cp: coverpoint w_en;
        read_cp: coverpoint r_en;
        address_cp: coverpoint addr;
        operation_cross: cross write_cp, read_cp;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        transaction_cg = new();
    endfunction

    function void write(add_item t);
        w_en = t.w_en;
        r_en = t.r_en;
        addr = t.addr;
        transaction_cg.sample();
    endfunction
endclass
