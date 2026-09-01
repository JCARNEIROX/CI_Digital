class test_2clk extends add_test;
    `uvm_component_utils(test_2clk)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg.env_cfg.read_latency = 2;
        cfg.env_cfg.agent_cfg.read_latency = 2;
        seq.read_latency = 2;
    endfunction
endclass
