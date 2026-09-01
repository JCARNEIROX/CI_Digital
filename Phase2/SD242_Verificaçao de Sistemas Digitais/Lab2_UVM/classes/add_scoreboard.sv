class add_scboard extends uvm_scoreboard;
    `uvm_component_utils(add_scboard)

    // Analysis export implementation
    uvm_analysis_imp #(add_item, add_scboard) agent_aep;

    // Report Counters
    int compared_pass;
    int compared_fail;

    logic [DATA_WIDTH-1:0] model_mem [int unsigned];
    logic [DATA_WIDTH-1:0] expected_reads[$];
    int unsigned latency_counter;
    add_env_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        compared_pass = 0;
        compared_fail = 0;

        latency_counter = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(add_env_config)::get(this, "", "cfg", cfg))
            cfg = add_env_config::type_id::create("cfg");
        agent_aep  = new("agent_aep" , this);
    endfunction

    function void write(add_item t);
        
        logic [DATA_WIDTH-1:0] read_value;
        bit accept_read;

        // Match the RTL ordering: a simultaneous write/read returns old memory data.
        accept_read = t.r_en && (latency_counter == 0);
        if (accept_read) begin
            if (model_mem.exists(t.addr))
                read_value = model_mem[t.addr];
            else
                read_value = 'x;
        end

        if (latency_counter > 0) begin
            latency_counter--;
            if (latency_counter == 0) begin
                read_value = expected_reads.pop_front();
                if (read_value === t.data_out) begin
                    compared_pass++;
                    `uvm_info(get_type_name(),
                              $sformatf("PASS: read data 0x%0h", t.data_out), UVM_MEDIUM)
                end else begin
                    compared_fail++;
                    `uvm_error(get_type_name(),
                               $sformatf("FAIL: expected read data 0x%0h, got 0x%0h",
                                         read_value, t.data_out))
                end
            end
        end

        if (t.w_en)
            model_mem[t.addr] = t.data_in;

        if (accept_read) begin
            expected_reads.push_back(read_value);
            latency_counter = cfg.read_latency;
        end
    endfunction

    function void check_phase(uvm_phase phase);
        if (expected_reads.size() != 0)
            `uvm_error(get_type_name(), "Simulation ended before all read responses arrived")
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
                  $sformatf("Scoreboard: %0d pass, %0d fail", compared_pass, compared_fail),
                  UVM_NONE)
    endfunction
endclass
