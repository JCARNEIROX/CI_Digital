class add_agent_config extends uvm_object;
    `uvm_object_utils(add_agent_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int unsigned read_latency = 2;
    bit driver_uses_clocking_block = 1;
    bit monitor_collects_transactions = 1;

    function new(string name = "add_agent_config");
        super.new(name);
    endfunction
endclass
