import os
import subprocess
from pathlib import Path

def main():
    script_dir = Path(__file__).parent
    project_root = Path(__file__).parent.parent
    modules_dir = project_root / "modules"

    print("Iniciando a bateria de testes...\n")

    # Diz ao compilador utiliar esses diretorios em sua busca pelos modulos 
    rtl_dirs = [d for d in modules_dir.glob("*/rtl") if d.is_dir()]
    
    # Monta a lista de flags "-y pasta1 -y pasta2 ..."
    lib_flags = []
    for d in rtl_dirs:
        lib_flags.extend(["-y", str(d)])

    if not rtl_dirs:
        print("[AVISO] Nenhuma pasta RTL encontrada no projeto para ser usada como biblioteca.")

    # Itera sobre cada pasta dentro de modules/
    # Descobre cada módulo presente na pasta
    for module_path in modules_dir.iterdir():
        if not module_path.is_dir():
            continue

        # Extrai o nome do módulo e define os caminhos para rtl, tb e resultados
        module_name = module_path.name
        rtl_dir = module_path / "rtl"
        tb_dir = module_path / "tb"
        res_dir = module_path / "resultados"

        # Pula se não tiver as pastas rtl e tb
        if not rtl_dir.exists() or not tb_dir.exists():
            continue

        print(f"[{module_name}] Preparando simulação...")
        
        # Cria a pasta resultados se não existir
        res_dir.mkdir(exist_ok=True)

        # Pega APENAS os arquivos do módulo atual (RTL local e TB específico)
        local_files = list(rtl_dir.glob("*.v")) + list(tb_dir.glob("*.v"))
        if not local_files:
            print(f"[{module_name}] Nenhum arquivo .v (RTL ou TB) encontrado. Pulando.\n")
            continue

        # Converte os caminhos dos arquivos para strings e define os caminhos de saída
        file_paths = [str(f) for f in local_files]
        # O arquivo de saída do compilador e o log da simulação serão salvos dentro da pasta resultados/
        output_vvp = res_dir / "sim.vvp"
        log_file = res_dir / "sim.log"

        # Compilação Inteligente
        # O comando passa os arquivos locais E as flags de busca de biblioteca (-y)
        compile_cmd = ["iverilog", "-o", str(output_vvp)] + lib_flags + file_paths
        
        # Compila o modulo RTL e o testbench atual. Caso o modulo instancie outros modulos (ex: mestre instanciando fsm),
        # o compilador vai procurar automaticamente nas pastas listadas nas flags -y.
        # EX: iverilog -o modules/spi_master_system/resultados/sim.vvp -y modules/spi_fsm/rtl -y modules/spi_master_system/rtl modules/spi_master_system/rtl/*.v modules/spi_master_system/tb/*.v
        try:
            # compila de fato
            subprocess.run(compile_cmd, check=True, capture_output=True, text=True)
            print(f"[{module_name}] Compilado com sucesso.")
        except subprocess.CalledProcessError as e:
            print(f"[{module_name}] ERRO DE COMPILAÇÃO:\n{e.stderr}\n")
            continue

        # 2. Execução (mudando o diretório de trabalho para 'resultados')
        print(f"[{module_name}] Iniciando simulação...")
        try:
            # Ao rodar com cwd=res_dir, qualquer arquivo gerado pelo TB (como .vcd)
            # será salvo automaticamente dentro da pasta resultados/
            with open(log_file, "w") as f_out:
                # Executa a simulação usando o vvp, redirecionando a saída para o log_file.
                # O codigo do TB deve conter as chamadas para gerar os arquivos de saída (como .vcd).
                # Como a execução do codigo compilado (sim.vvp) é feita com o diretório de trabalho sendo 'resultados', 
                # os arquivos gerados pelo TB serão salvos diretamente dentro da pasta resultados/ do módulo.
                result = subprocess.run(["vvp", "sim.vvp"], cwd=res_dir, stdout=f_out, stderr=subprocess.STDOUT, check=True)
            print(f"[{module_name}] Simulação concluída. Log salvo em: {log_file.relative_to(project_root)}")
        except subprocess.CalledProcessError as e:
            print(f"[{module_name}] ERRO NA SIMULAÇÃO. Código de saída: {e.returncode}")
            print(f"[{module_name}] Verifique o log em: {log_file.relative_to(project_root)}\n")
            continue
        except Exception as e:
            print(f"[{module_name}] ERRO INESPERADO: {e}\n")
            continue
        
        print("-" * 40)

if __name__ == "__main__":
    main()