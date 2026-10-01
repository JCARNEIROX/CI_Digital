"""Cria um módulo RTL acompanhado de um ambiente UVM básico."""

import argparse
import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent

# @MODULE@ é substituído pelo nome informado na linha de comando.
# Todos os arquivos de saída vivem aqui: o gerador não depende de outra pasta.
FILES = {
    "rtl/@MODULE@.sv": """`timescale 1ns/1ps
// Exemplo inicial: somador combinacional de 8 bits com carry.
// Substitua as portas e a lógica pelo seu módulo.
module @MODULE@ (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [8:0] sum
);
    assign sum = {1'b0, a} + {1'b0, b};
endmodule
""",
    "tb/@MODULE@_if.sv": """`timescale 1ns/1ps
interface @MODULE@_if(input logic clk);
    logic rst_n;
    logic valid;
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] sum;

    // Dirige na descida e observa na subida.
    clocking driver_cb @(negedge clk);
        default input #1step output #0;
        output valid, a, b;
    endclocking

    clocking monitor_cb @(posedge clk);
        default input #1step output #0;
        input rst_n, valid, a, b, sum;
    endclocking
endinterface
""",
    "tb/@MODULE@_pkg.sv": """`timescale 1ns/1ps
package @MODULE@_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef virtual @MODULE@_if @MODULE@_vif_t;

    // Ordem de dependência; estas classes não entram separadamente no filelist.
    `include "@MODULE@_sequence_item.sv"
    `include "@MODULE@_sequence.sv"
    `include "@MODULE@_driver.sv"
    `include "@MODULE@_monitor.sv"
    `include "@MODULE@_agent.sv"
    `include "@MODULE@_scoreboard.sv"
    `include "@MODULE@_env.sv"
    `include "@MODULE@_test.sv"
endpackage
""",
    "tb/@MODULE@_sequence_item.sv": """class @MODULE@_sequence_item extends uvm_sequence_item;
    rand bit [7:0] a;
    rand bit [7:0] b;
    logic [8:0] sum; // Mantém X/Z para detectar saídas inválidas.

    `uvm_object_utils_begin(@MODULE@_sequence_item)
        `uvm_field_int(a, UVM_ALL_ON)
        `uvm_field_int(b, UVM_ALL_ON)
        `uvm_field_int(sum, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "@MODULE@_sequence_item");
        super.new(name);
    endfunction
endclass
""",
    "tb/@MODULE@_sequence.sv": """class @MODULE@_sequence extends uvm_sequence #(@MODULE@_sequence_item);
    `uvm_object_utils(@MODULE@_sequence)
    int unsigned num_items = 100;

    function new(string name = "@MODULE@_sequence");
        super.new(name);
    endfunction

    task body();
        @MODULE@_sequence_item item;
        repeat (num_items) begin
            item = @MODULE@_sequence_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("RANDOMIZE", "Falha ao randomizar a transação")
            finish_item(item);
        end
    endtask
endclass
""",
    "tb/@MODULE@_driver.sv": """class @MODULE@_driver extends uvm_driver #(@MODULE@_sequence_item);
    `uvm_component_utils(@MODULE@_driver)
    @MODULE@_vif_t vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(@MODULE@_vif_t)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Interface virtual não configurada no driver")
    endfunction

    task run_phase(uvm_phase phase);
        @(vif.driver_cb);
        vif.driver_cb.valid <= 0;
        vif.driver_cb.a <= '0;
        vif.driver_cb.b <= '0;
        wait (vif.rst_n === 1'b1);
        forever begin
            seq_item_port.get_next_item(req);
            // Adapte o handshake e a latência ao protocolo do seu DUT.
            @(vif.driver_cb);
            vif.driver_cb.a <= req.a;
            vif.driver_cb.b <= req.b;
            vif.driver_cb.valid <= 1;
            @(vif.driver_cb);
            vif.driver_cb.valid <= 0;
            seq_item_port.item_done();
        end
    endtask
endclass
""",
    "tb/@MODULE@_monitor.sv": """class @MODULE@_monitor extends uvm_monitor;
    `uvm_component_utils(@MODULE@_monitor)
    @MODULE@_vif_t vif;
    uvm_analysis_port #(@MODULE@_sequence_item) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(@MODULE@_vif_t)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Interface virtual não configurada no monitor")
    endfunction

    task run_phase(uvm_phase phase);
        @MODULE@_sequence_item item;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.rst_n === 1'b1 && vif.monitor_cb.valid === 1'b1) begin
                item = @MODULE@_sequence_item::type_id::create("item");
                item.a = vif.monitor_cb.a;
                item.b = vif.monitor_cb.b;
                item.sum = vif.monitor_cb.sum;
                analysis_port.write(item);
            end
        end
    endtask
endclass
""",
    "tb/@MODULE@_agent.sv": """class @MODULE@_agent extends uvm_agent;
    `uvm_component_utils(@MODULE@_agent)
    uvm_sequencer #(@MODULE@_sequence_item) sequencer;
    @MODULE@_driver driver;
    @MODULE@_monitor monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = @MODULE@_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = uvm_sequencer#(@MODULE@_sequence_item)::type_id::create("sequencer", this);
            driver = @MODULE@_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
""",
    "tb/@MODULE@_scoreboard.sv": """class @MODULE@_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(@MODULE@_scoreboard)
    uvm_analysis_imp #(@MODULE@_sequence_item, @MODULE@_scoreboard) analysis_export;
    int unsigned checked = 0;
    int unsigned errors = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(@MODULE@_sequence_item item);
        logic [8:0] expected;
        // Substitua pelo modelo de referência do seu DUT.
        expected = {1'b0, item.a} + {1'b0, item.b};
        checked++;
        if (item.sum !== expected) begin
            errors++;
            `uvm_error("MISMATCH", $sformatf(
                "a=%0d b=%0d esperado=%0d recebido=%0d",
                item.a, item.b, expected, item.sum))
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (checked == 0)
            `uvm_error("NO_ITEMS", "Nenhuma transação foi verificada")
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SUMMARY", $sformatf(
            "Transações verificadas: %0d; divergências: %0d", checked, errors), UVM_LOW)
    endfunction
endclass
""",
    "tb/@MODULE@_env.sv": """class @MODULE@_env extends uvm_env;
    `uvm_component_utils(@MODULE@_env)
    @MODULE@_agent agent;
    @MODULE@_scoreboard scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = @MODULE@_agent::type_id::create("agent", this);
        scoreboard = @MODULE@_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.analysis_port.connect(scoreboard.analysis_export);
    endfunction
endclass
""",
    "tb/@MODULE@_test.sv": """class @MODULE@_test extends uvm_test;
    `uvm_component_utils(@MODULE@_test)
    @MODULE@_env env;
    int unsigned expected_items;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = @MODULE@_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        @MODULE@_sequence seq;
        phase.raise_objection(this);
        if (env.agent.get_is_active() != UVM_ACTIVE)
            `uvm_fatal("PASSIVE", "Este teste requer um agente ativo")
        seq = @MODULE@_sequence::type_id::create("seq");
        expected_items = seq.num_items;
        seq.start(env.agent.sequencer);
        // Para DUTs com latência, aguarde as respostas antes de baixar a objection.
        phase.drop_objection(this);
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (env.scoreboard.checked != expected_items)
            `uvm_error("ITEM_COUNT", $sformatf(
                "Esperadas %0d transações; observadas %0d",
                expected_items, env.scoreboard.checked))
    endfunction
endclass
""",
    "tb/tb_top.sv": """`timescale 1ns/1ps
module tb_top;
    import uvm_pkg::*;
    import @MODULE@_pkg::*;
    `include "uvm_macros.svh"

    logic clk = 0;
    @MODULE@_if vif(clk);
    @MODULE@ dut (.a(vif.a), .b(vif.b), .sum(vif.sum));
    always #5 clk = ~clk;

    // rst_n e valid são controles do TB; o somador é combinacional.
    initial begin
        vif.rst_n = 0;
        repeat (4) @(negedge clk);
        vif.rst_n = 1;
    end

    initial begin
        uvm_config_db#(@MODULE@_vif_t)::set(null, "uvm_test_top.env.agent.*", "vif", vif);
        run_test("@MODULE@_test");
    end

    initial begin
        #100us;
        `uvm_fatal("TIMEOUT", "O teste excedeu 100 us")
    end
endmodule
""",
    "filelist.f": """// Execute o simulador a partir da pasta que contém este arquivo.
// Habilite a biblioteca UVM nas opções do simulador.
+incdir+tb
rtl/@MODULE@.sv
tb/@MODULE@_if.sv
tb/@MODULE@_pkg.sv
tb/tb_top.sv
""",
    "README.md": """# @MODULE@ — ambiente UVM

O RTL inicial é um somador combinacional de 8 bits com carry. O testbench gera
100 transações, verifica a soma e confere quantas respostas foram observadas.

Fluxo: sequência → sequencer → driver → interface/DUT → monitor → scoreboard.
O sequencer padrão é criado pelo agente. As classes são incluídas pelo pacote
`tb/@MODULE@_pkg.sv`; não as compile separadamente.

Execute a partir desta pasta com um simulador compatível com UVM, por exemplo,
Xcelium:

```sh
xrun -64bit -uvm -sv -f filelist.f -top tb_top +UVM_TESTNAME=@MODULE@_test -l resultados/sim.log
```

Adapte as portas e o RTL, depois os sinais da interface, os itens, o driver,
o monitor e o modelo de referência do scoreboard. Para DUTs com latência,
aguarde as respostas pendentes antes de terminar o teste. Ao adicionar classes,
atualize os includes do pacote e, ao adicionar unidades independentes, atualize
o filelist. O script `scripts/run_all_tbs.py` usa Icarus e não executa UVM.
""",
}


def module_identifier(value):
    """Aceita identificadores simples, sem permitir caminhos no nome do módulo."""
    if not re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_]*", value):
        raise argparse.ArgumentTypeError(
            "Use um identificador SystemVerilog: letras, números e '_', "
            "sem começar por número."
        )
    if value in {"tb_top", "uvm_pkg"}:
        raise argparse.ArgumentTypeError("Nome reservado pela estrutura do testbench.")
    return value


def create_module(project_dir, module_name):
    """Cria os arquivos UVM sem sobrescrever um módulo existente."""
    module_name = module_identifier(module_name)
    module_dir = PROJECT_ROOT / project_dir / "modules" / module_name
    files = {
        path.replace("@MODULE@", module_name): content.replace("@MODULE@", module_name)
        for path, content in FILES.items()
    }

    # exist_ok=False também protege contra duas execuções simultâneas.
    module_dir.mkdir(parents=True, exist_ok=False)
    (module_dir / "resultados").mkdir()
    for relative_path, content in files.items():
        output_file = module_dir / relative_path
        output_file.parent.mkdir(parents=True, exist_ok=True)
        with output_file.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
    return module_dir, list(files)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Cria RTL, testbench UVM e filelist em <projeto>/modules/<modulo>."
    )
    parser.add_argument(
        "projeto", help="Pasta do projeto (relativa à raiz do repositório ou absoluta)."
    )
    parser.add_argument("modulo", type=module_identifier, help="Nome do módulo SystemVerilog.")
    args = parser.parse_args(argv)

    try:
        module_dir, files = create_module(args.projeto, args.modulo)
    except FileExistsError:
        parser.exit(1, f"[ERRO] O módulo '{args.modulo}' já existe ou o caminho está ocupado.\n")
    except OSError as error:
        parser.exit(1, f"[ERRO] Não foi possível criar o módulo: {error}\n")

    print(f"Ambiente UVM criado em: {module_dir}")
    for relative_path in files:
        print(f" - {relative_path}")
    print("Veja README.md no módulo gerado para simular e adaptar o exemplo.")


if __name__ == "__main__":
    main()
