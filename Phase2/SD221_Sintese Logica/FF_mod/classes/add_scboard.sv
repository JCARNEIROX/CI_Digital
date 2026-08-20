class add_scboard extends uvm_scoreboard;
    `uvm_component_utils(add_scboard)

    add_item item;
    
    // Analysis export implementation
    uvm_analysis_imp #(add_item, add_scboard) agent_aep;

    // Report Counters
    int compared_pass;
    int compared_fail;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        compared_pass = 0;
        compared_fail = 0;
    endfunction

    task run_phase(uvm_phase phase);
        // todo
    endtask

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_aep  = new("agent_aep" , this);
        item = add_item::type_id::create("item");

    endfunction

    function void write(add_item t);
        logic [31:0] expected_result;
        logic        expected_carry;
        {expected_carry, expected_result} = {1'b0, t.a} + {1'b0, t.b};

        if (expected_result == t.result && expected_carry == t.carry_o) begin
            compared_pass++;
            `uvm_info(get_type_name(), 
                      $sformatf("PASS: %s", t.convert2string()), 
                      UVM_MEDIUM)
        end else begin
            compared_fail++;
            `uvm_error(get_type_name(), 
                       $sformatf("FAIL: %s Expected result=0x%8h carry=%0d", 
                                 t.convert2string(), expected_result, expected_carry))
        end
    endfunction
endclass