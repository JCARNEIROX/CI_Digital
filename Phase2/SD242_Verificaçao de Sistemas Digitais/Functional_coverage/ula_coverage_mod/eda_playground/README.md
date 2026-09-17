# Verificar a ULA em casa pelo EDA Playground

O EDA Playground executa o simulador no servidor. **A tentativa com Riviera-PRO foi bloqueada por licença na elaboração do UVM.** Os administradores informaram restrições na licença do Riviera, afetando UVM e cobertura funcional. A indicação anterior, baseada na FAQ, não refletia esse bloqueio. Consulte os [avisos do suporte](https://groups.google.com/g/eda-playground).

Os arquivos preparados continuam úteis para um simulador com os recursos liberados. A alternativa é **Cadence Xcelium no próprio Playground**, caso a conta tenha acesso validado. Isso não exige instalar Cadence no computador pessoal. A validação da conta requer identificação e e-mail institucional/profissional, conforme a [FAQ](https://github.com/edaplayground/eda-playground/blob/master/docs/faq.rst).

## Executar com Xcelium na conta validada

O usuário confirmou que a conta já está validada e, após a orientação de trocar para Xcelium, informou cobertura de **30,44%**, com **28 matches e zero mismatches**. O resultado e seus limites estão no [registro de alterações](../relatorio/REGISTRO_ALTERACOES.md). O bloqueio anterior do Riviera foi de licença.

Use SystemVerilog e UVM 1.2; mantenha o conteúdo das duas abas indicado abaixo. Selecione **Cadence Xcelium** e substitua as opções do Riviera por:

```text
Compile Options: -coverage all -covoverwrite
Run Options:     -svseed 1 +NUM_TRANSACTIONS=1000 +RUN_CORNERS=1 +COV_GOAL=95
```

Deixe `Use run.do Tcl file` desmarcado e execute com `Run`. Como os arquivos estão reunidos nas duas abas, não adicione `-f files.f`. O log deve conter o resumo do scoreboard e a porcentagem de cobertura. O trecho fornecido pelo usuário confirma a medição agregada, mas não inclui a versão da ferramenta nem a seed efetivamente usada.

## Configuração Riviera anteriormente tentada (bloqueada por licença)

1. Abra <https://www.edaplayground.com/> e crie um playground.
2. Em **Testbench + Design**, selecione **SystemVerilog**.
3. Em **UVM / OVM**, selecione **UVM 1.2**.
4. Em **Tools & Simulators**, selecione **Aldec Riviera-PRO**.
5. Cole o conteúdo completo de [design.sv](design.sv) na aba padrão `design.sv` (Design).
6. Cole o conteúdo completo de [testbench.sv](testbench.sv) na aba padrão `testbench.sv` (Testbench).
7. Use `-sv2k12` em **Compile Options** e `-sv_seed 1` em **Run Options**. Não use as opções `-coverage all`, `-covoverwrite` ou `-svseed` do Xcelium neste fluxo Riviera.
8. Deixe **Use run.do Tcl file** e **Open EPWave after run** desmarcados nesta primeira execução. Marque **Download files after run** para guardar os fontes e o log.
9. Clique em **Run**.

Esses dois arquivos já reúnem todos os fontes da lista: não adicione `-f files.f` nem cópias extras dos módulos/classes.

## O que verificar no log

**Se aparecer `COVNSM` e todas as métricas indicarem `0/0 bins`:** o simulador informa que a coleta do covergroup está desabilitada. Confira se a linha de `xrun` no início do log contém `-coverage all` e execute novamente com essa opção em Compile Options. `-covoverwrite` sozinho não habilita cobertura. Um contador positivo de amostras recebidas não comprova que os bins foram contabilizados. Essa execução não fornece uma porcentagem válida para comparar com as anteriores.

```text
Scoreboard summary: Matches=..., Mismatches=...
=== COBERTURA FUNCIONAL: ...% ===
```

Primeiro confirme que a compilação e a simulação terminaram. Depois confira `Matches > 0`, `Mismatches=0` e ausência de erros UVM. Na etapa 2, `uvm_error` do scoreboard foi reativado e a ausência de amostras também gera erro.

O relatório atual fornece a porcentagem agregada, `COV_DETAIL` por coverpoint/cross e o arquivo `ula_coverage.csv`. Consulte também `SEQ_SUMMARY` (padrão: 499 dirigidas + 1.000 aleatórias) e `COV_GOAL` (meta de 95%). Os detalhes são totais de bins por métrica, não hits individuais. O [antes/depois da etapa 2](../relatorio/ETAPA_2_COBERTURA95.md) contém a auditoria dos estímulos e os limites da validação local. A nova cobertura deve ser medida; os 30,44% são a referência anterior.

Para testar apenas as 499 transações dirigidas, use `+NUM_TRANSACTIONS=0 +RUN_CORNERS=1`. Para testar somente as aleatórias, use `+RUN_CORNERS=0`; nesse modo a meta não é garantida. Ative **Download files after run** para baixar o CSV junto ao log.

Este fluxo não exige gerar nem abrir bases `.ucm/.ucd`. A seed é repetível dentro da mesma configuração do simulador; a mesma seed em Riviera e Xcelium não garante a mesma sequência de valores.

## Atualizar as cópias após editar o projeto

Edite os arquivos originais em `ula_coverage_mod`. Depois, a partir dessa pasta:

```powershell
python eda_playground/preparar.py
python eda_playground/preparar.py --check
```

Cole novamente os dois arquivos gerados nas abas do Playground. Os comentários `BEGIN SOURCE` e `END SOURCE` identificam o arquivo original de cada trecho.

## Antes/depois da preparação

- **Antes:** os fontes individuais eram compilados por `files.f` no ambiente Cadence.
- **Depois:** uma cópia dos mesmos fontes é agrupada em duas abas. `design.sv` contém a interface e a ULA; `testbench.sv` contém as classes na ordem de dependência e `top_tb` ao final.
- A cópia acrescenta `timescale 1ns/1ps` em cada aba para definir os atrasos do exemplo e um include/import UVM antes das classes. Os corpos dos fontes são preservados; não há alteração dos bins, constraints, operações ou lógica de conferência nesta preparação.
- **Validação feita localmente:** geração e conferência de correspondência com os fontes.
- **Tentativa do usuário:** elaboração interrompida por falta de licença de recursos avançados de SystemVerilog em `uvm_pkg` / `uvm_bottomup_phase`. A simulação não iniciou e nenhuma métrica de cobertura desta tentativa foi validada. Isso não demonstra falha funcional da ULA nem confirma a correção completa do ambiente.

## Registro do bloqueio informado pelo usuário

```text
ELBREAD: Error: You do not have a valid license to simulate module
"uvm_1_2.\uvm_pkg uvm_bottomup_phase " using SystemVerilog advanced verification features.
ELBREAD: Error: Elaboration process completed with errors.
VSIM: Error: Simulation initialization failed.
```

Alterar os bins, o monitor ou a versão da biblioteca UVM não fornece a licença ausente. A restrição precisa ser resolvida pelo provedor ou é necessário usar outro simulador autorizado. Os testes locais isolados com Icarus permanecem úteis para a lógica/temporização que exercitam, mas não validam a execução completa das classes UVM e dos covergroups.

## Referências

- [FAQ oficial: simuladores e validação de conta](https://github.com/edaplayground/eda-playground/blob/master/docs/faq.rst).
- [Opções oficiais: Riviera-PRO](https://github.com/edaplayground/eda-playground/blob/master/docs/compile_run_options.rst).
- [Configuração de UVM e download dos resultados](https://eda-playground.readthedocs.io/en/latest/settings.html).
