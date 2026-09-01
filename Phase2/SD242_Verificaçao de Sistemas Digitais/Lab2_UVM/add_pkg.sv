package tb_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import tb_params_pkg::*;

    `include "add_agent_config.sv"
    `include "add_env_config.sv"
    `include "add_item.sv"
    `include "add_coverage.sv"
    `include "add_sequencer.sv"
    `include "add_driver.sv"
    `include "add_monitor.sv"
    `include "add_agent.sv"
    `include "add_scoreboard.sv"
    `include "add_env.sv"
    `include "add_sequence.sv"
    `include "add_test_config.sv"
    `include "add_test.sv"
    `include "sanity_test.sv"
    `include "test_2clk.sv"
    `include "test_3clk.sv"
    `include "test_4clk.sv"

endpackage
