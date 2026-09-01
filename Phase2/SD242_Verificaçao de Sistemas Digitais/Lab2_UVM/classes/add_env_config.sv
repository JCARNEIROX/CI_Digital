class add_env_config extends uvm_object;
    `uvm_object_utils(add_env_config)

    bit has_scoreboard = 1;
    bit has_coverage = 1;
    bit synchronize_components = 1;
    int unsigned read_latency = 2;
    add_agent_config agent_cfg;

    function new(string name = "add_env_config");
        super.new(name);
        agent_cfg = add_agent_config::type_id::create("agent_cfg");
    endfunction
endclass
