class add_scboard extends uvm_scoreboard;
    `uvm_component_utils(add_scboard)

    add_item item;
    
    // Analysis export implementation
    uvm_analysis_imp #(add_item, add_scboard) agent_aep;

    // Report Counters
    int compared_pass;
    int compared_fail;

    //resultado esperado
    logic [7:0] expected_data_out;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        compared_pass = 0;
        compared_fail = 0;

        //zera após o reset
        expected_data_out = 8'h00;
        
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
        
        if (expected_data_out == t.data_out) begin
            compared_pass++;
            `uvm_info(get_type_name(), 
                      $sformatf("PASS: %s", t.convert2string()), 
                      UVM_MEDIUM)
        end else begin
            compared_fail++;
            `uvm_error(get_type_name(), 
                       $sformatf("FAIL: %s | Expected data_out=0x%2h", 
                                 t.convert2string(), expected_data_out))
        end

        if (t.enable == 1'b1) begin
            expected_data_out = t.data_in;
        end
        // Se enable for 0, o expected_data_out mantém o valor antigo (não muda).
        
    endfunction
endclass