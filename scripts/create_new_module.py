import sys
from pathlib import Path

def main():
    # Verifica se o usuário passou o nome do módulo
    if len(sys.argv) < 2:
        print("Uso correto: python scripts/create_module.py <nome_do_modulo>")
        sys.exit(1)

    module_name = sys.argv[1]
    
    # Define os caminhos
    project_root = Path(__file__).parent.parent
    module_dir = project_root / "modules" / module_name
    rtl_dir = module_dir / "rtl"
    tb_dir = module_dir / "tb"
    res_dir = module_dir / "resultados"

    # Verifica se o módulo já existe para não sobrescrever nada
    if module_dir.exists():
        print(f"[ERRO] O módulo '{module_name}' já existe em {module_dir}")
        sys.exit(1)

    print(f"Criando a estrutura para o módulo: {module_name}...")

    # Cria as pastas
    rtl_dir.mkdir(parents=True, exist_ok=True)
    tb_dir.mkdir(parents=True, exist_ok=True)
    res_dir.mkdir(parents=True, exist_ok=True)

    # Cria o arquivo RTL (.v) com o esqueleto básico
    rtl_file = rtl_dir / f"{module_name}.v"
    with open(rtl_file, "w") as f:
        f.write(f"module {module_name} (\n")
        f.write(");\n\n")
        f.write("    // Sua lógica aqui\n\n")
        f.write("endmodule\n")

    # Cria o arquivo Testbench (_tb.v) com o esqueleto básico
    tb_file = tb_dir / f"{module_name}_tb.v"
    with open(tb_file, "w") as f:
        f.write("`timescale 1ns/1ns\n\n")
        f.write(f"module tb_{module_name};\n\n")
        f.write(f"    {module_name} dut (\n")
        f.write("    );\n\n")
        f.write("    initial begin\n")
        f.write(f"        $dumpfile(\"{module_name}.vcd\");\n")
        f.write(f"        $dumpvars(0, tb_{module_name});\n\n")
        f.write("        // Inicialização\n")
        f.write("        #20 reset = 0;\n\n")
        f.write("        // Estímulos do teste aqui\n\n")
        f.write("        #100 $finish;\n")
        f.write("    end\n\n")
        f.write("endmodule\n")

    print("Estrutura criada com sucesso!")
    print(f" - {rtl_file.relative_to(project_root)}")
    print(f" - {tb_file.relative_to(project_root)}")

if __name__ == "__main__":
    main()