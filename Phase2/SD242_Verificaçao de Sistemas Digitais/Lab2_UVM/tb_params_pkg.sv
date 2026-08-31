package tb_params_pkg;
    parameter int DATA_WIDTH = 16;
    parameter int ADDR_WIDTH = 8;
    typedef virtual dut_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
        ) dut_vif_t;
endpackage