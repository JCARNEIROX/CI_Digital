class add_test_config extends uvm_object;
    `uvm_object_utils(add_test_config)

    int unsigned num_transactions = 10;
    add_env_config env_cfg;

    function new(string name = "add_test_config");
        super.new(name);
        env_cfg = add_env_config::type_id::create("env_cfg");
    endfunction

    function void apply_plusargs();
        int value;

        if ($value$plusargs("NUM_TRANSACTIONS=%d", value) && value > 0)
            num_transactions = value;
        if ($value$plusargs("READ_LATENCY=%d", value) && value > 0) begin
            env_cfg.read_latency = value;
            env_cfg.agent_cfg.read_latency = value;
        end
        if ($value$plusargs("AGENT_ACTIVE=%d", value))
            env_cfg.agent_cfg.is_active = value ? UVM_ACTIVE : UVM_PASSIVE;
        if ($value$plusargs("ENABLE_SCOREBOARD=%d", value))
            env_cfg.has_scoreboard = value;
        if ($value$plusargs("ENABLE_COVERAGE=%d", value))
            env_cfg.has_coverage = value;
        if ($value$plusargs("ENABLE_SYNC=%d", value))
            env_cfg.synchronize_components = value;
        if ($value$plusargs("ENABLE_MONITOR=%d", value))
            env_cfg.agent_cfg.monitor_collects_transactions = value;
        if ($value$plusargs("DRIVER_USE_CB=%d", value))
            env_cfg.agent_cfg.driver_uses_clocking_block = value;
    endfunction
endclass
