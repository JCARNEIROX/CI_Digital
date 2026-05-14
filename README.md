# CI_Digital
Desenvolvimento de códigos em Verilog no processo de capacitação no Ci Digital

## 🛠️ Como Compilar e Simular

O projeto conta com um script automatizado que varre a estrutura de diretórios, compila os módulos Verilog e executa a simulação principal.

## Scripts

```
run_all_tbs.py 
uso : python scripts/run_all_tbs.py 
Testa todos os modulos de uma vez e gera os arquivos de log e vcd na respectiva pasta de results

create_new_module.py
uso: python scripts/create_new_module.py <nome_do_modulo>
Gera a estrutura de pastas de um modulo novo no repositorio com um esqueleto de testbench e module
```