# Digital Verification & SystemVerilog

Repository containing exercises, notes, simulations and projects developed
during my postgraduate studies in Digital Verification and SystemVerilog.

## Topics

- SystemVerilog
- Digital Design Verification
- Object-Oriented Programming
- Assertions (SVA)
- Functional Coverage
- Constrained Random Verification
- UVM
- Testbench Architecture

## Repository Structure

Each directory contains exercises and examples related to a specific topic.

Most exercises are organized as:

- `src/` - Design Under Test (DUT)
- `tb/` - Testbench
- `docs/` - Documentation and simulation results
- `README.md` - Description of the activity

## Tools

Tools used throughout the course may include:

- SystemVerilog
- QuestaSim / ModelSim
- Vivado
- Verilator
- GTKWave
- Git / GitHub

## Gerador de módulos UVM

Na raiz do repositório, execute:

```sh
python scripts/create_new_module.py MeuProjeto adder
```

O comando cria `MeuProjeto/modules/adder/`, mantendo a organização do gerador
anterior, com `rtl/`, `tb/`, `resultados/`, `filelist.f` e um README com instruções
de simulação e adaptação. O testbench contém os componentes UVM conectados e um
somador de exemplo com verificação automática. Módulos existentes não são
sobrescritos. As definições dos arquivos ficam dentro do próprio
`scripts/create_new_module.py`; não há uma pasta de templates necessária.

Para simular, utilize um simulador com UVM (como Xcelium), conforme o README
gerado. O executor legado `run_all_tbs.py` não é compatível com esse ambiente.

## Purpose

This repository serves both as a record of my postgraduate studies and as a
technical portfolio focused on RTL design verification.
