# Registro de alterações — ULA e cobertura funcional

Este registro apresenta o problema, o código antes/depois e a validação de cada etapa em `ula_coverage_mod`. As próximas etapas devem ser acrescentadas ao final, preservando o histórico.

Para executar a simulação de cobertura e comparar as bases no IMC, consulte [Como simular a cobertura](COMO_SIMULAR_COBERTURA.md).

Para verificar os fontes em casa sem instalar ferramentas comerciais, consulte o [fluxo EDA Playground](../eda_playground/README.md). A preparação cria duas cópias agrupadas, com unidade de tempo explícita e import UVM, preservando os corpos dos fontes. A tentativa com Riviera-PRO foi bloqueada por licença na elaboração do UVM; o README registra a evidência e a alternativa Xcelium condicionada ao acesso validado da conta. Não há métricas de cobertura medidas nessa tentativa.

Os arquivos `.diff` associados são fotografias das alterações: linhas com `-` representam o código anterior e linhas com `+` representam o código posterior. A referência inicial desses diffs é o commit `93f7f4c`.

## Etapa 0 — Reestruturação do coverage

Registro retrospectivo da alteração realizada antes da correção de sincronização.

**Arquivo:** `ula_coverage.sv`.

### Problema e alteração

Os bins de operandos agrupavam valores de interesse e deixavam intervalos sem representação. O novo modelo distingue os corner cases e permite verificar seu uso por operação.

| Categoria em A e B | Antes | Depois |
|---|---|---|
| Zero | Incluído em `low` | Bin `zero`, valor `32'd0` |
| Um | Incluído em `low` | Bin `one`, valor `32'd1` |
| Máximo sem sinal | Incluído em `high` | Bin `max_unsigned`, valor `32'hFFFFFFFF` |
| Bits alternados | Sem bins específicos | `alternating_10 = AAAAAAAA` e `alternating_01 = 55555555` |
| `low` | `[0:100]` | `[2:100]` |
| `mid` | `[1000:2000]` | Mesmo intervalo |
| `high` | `[FFFFFF00:FFFFFFFF]` | `[FFFFFF00:FFFFFFFE]` |
| Demais valores | Sem representação | Bin `other_values` com quatro intervalos disjuntos |

Também foram adicionados crosses de operação com operandos; cenários de subtração, divisão e padrões alternados; bins explícitos de resultado; e exclusões para carry impossível em AND/OR/NOT e para B em NOT. O relatório passou a usar cobertura por instância.

**Antes/depois completo:** [00_coverage.diff](00_coverage.diff).

### Validação e limites

- A verificação dos intervalos confirmou que os nove bins de cada operando particionam os valores conhecidos de 32 bits sem lacunas ou sobreposição. Os seis bins de resultado fazem o mesmo para 64 bits.
- `other_values` é um único bin: um hit em qualquer um dos seus intervalos o cobre; não comprova hits em todos os intervalos.
- Essa validação não compila nem simula o covergroup. A simulação UVM e a medição de cobertura continuam pendentes.
- Criar bins não gera estímulos. As constraints e a sequência ainda precisam exercitar os novos cenários.

## Etapa 1 — Sincronização do monitor e espera do reset

**Data:** 17/09/2026.

**Arquivos:** `ula_monitor.sv` e `ula_driver.sv`.

### 1.1 Monitor: associar entradas e saídas da mesma operação

**Problema:** a ULA registra as saídas com atribuições não bloqueantes (`<=`). O monitor lia entradas e saídas imediatamente na borda de subida, antes da atualização das saídas. Ao trocar a operação, isso podia associar entradas atuais ao resultado anterior.

**Antes — corpo da coleta:**

```systemverilog
@(posedge vif.clk or negedge vif.rst_n);
if (!vif.rst_n) continue;
trans = ula_item::type_id::create("trans");
trans.opr     = vif.opr;
trans.a       = vif.a;
trans.b       = vif.b;
trans.result  = vif.result;
trans.carry_o = vif.carry_o;
trans.zero    = vif.zero;
item_collected_port.write(trans);
```

**Depois — mesmo trecho, com comentários abreviados:**

```systemverilog
@(posedge vif.clk or negedge vif.rst_n);
if (vif.rst_n !== 1'b1) continue;

if ($isunknown(vif.opr) || $isunknown(vif.a) ||
    $isunknown(vif.b)) continue;

// Entradas usadas pela ULA nesta borda de subida.
trans = ula_item::type_id::create("trans");
trans.opr     = vif.opr;
trans.a       = vif.a;
trans.b       = vif.b;

// Resultado registrado, lido na borda de descida seguinte.
@(negedge vif.clk or negedge vif.rst_n);
if (vif.rst_n !== 1'b1) continue;
trans.result  = vif.result;
trans.carry_o = vif.carry_o;
trans.zero    = vif.zero;
item_collected_port.write(trans);
```

**Efeito:** o monitor guarda os operandos que a ULA usa no `posedge` e lê as saídas no `negedge` seguinte. A verificação de entradas desconhecidas evita enviar amostras antes do primeiro estímulo. Saídas desconhecidas continuam sendo encaminhadas ao scoreboard quando as entradas são conhecidas. Um reset durante a espera descarta a amostra em andamento.

### 1.2 Driver: aguardar uma borda com reset desativado

**Problema:** o driver aplicava a primeira transação na próxima borda, mesmo durante o reset.

**Antes — início de `drive_transaction`:**

```systemverilog
@(posedge vif.clk);
vif.a <= i_trans.a;
vif.b <= i_trans.b;
vif.opr <= i_trans.opr;
```

**Depois:**

```systemverilog
do begin
    @(posedge vif.clk);
end while (vif.rst_n !== 1'b1);
vif.a <= i_trans.a;
vif.b <= i_trans.b;
vif.opr <= i_trans.opr;
```

**Efeito:** cada transação só começa em uma borda de subida na qual o reset está conhecido e desativado. As atribuições continuam não bloqueantes; portanto, a ULA processa esses novos operandos na borda de subida seguinte.

### Linha do tempo de uma transação

| Instante | Driver / ULA | Monitor |
|---|---|---|
| Subida N | Driver agenda novos operandos; ULA ainda usa os anteriores | Captura os operandos anteriores |
| Descida N | Saídas anteriores já atualizadas | Publica a operação anterior, se válida |
| Subida N+1 | ULA usa os novos operandos e agenda seu resultado | Captura os novos operandos |
| Descida N+1 | Resultado da nova operação está estável | Publica entradas e saídas correspondentes |

**Antes/depois completo:** [01_sincronizacao.diff](01_sincronizacao.diff).

### Validação

Foi executado um teste isolado com Icarus Verilog, usando dez vetores que exercitam as sete operações, incluindo carry de soma, empréstimo de subtração, multiplicação acima de 32 bits, divisão por zero e padrões alternados.

| Versão do monitor | Amostras conferidas | Divergências | Vetores observados |
|---|---:|---:|---:|
| Antes | 22 | 12 | 10/10 |
| Depois | 19 | 0 | 10/10 |

As duas versões do teste usam o driver com a espera de reset, isolando a comparação do monitor. O teste também verifica que o driver não escreve durante o reset inicial e aplica um pulso de reset entre a captura de entradas e a leitura das saídas. O total de amostras diminui porque a versão nova descarta amostras sem entradas conhecidas e a amostra interrompida pelo reset, além de publicar na borda de descida.

**Artefatos:** [monitor_antes.sv](validacao/monitor_antes.sv), [monitor_depois.sv](validacao/monitor_depois.sv) e [resultado.txt](validacao/resultado.txt).

O teste extrai a lógica da ULA e as tarefas do driver/monitor. Para executar sem UVM, substitui a interface por sinais locais, a transação por uma struct e o analysis port por uma tarefa de conferência. Substitui também `continue` por saída de um bloco nomeado equivalente. Os resultados esperados dos dez vetores são constantes independentes da lógica da ULA.

Para repetir, a partir da pasta `relatorio`, no PowerShell com Icarus no PATH:

```powershell
iverilog -g2012 -s timing_tb -o "$env:TEMP/ula_monitor_antes.vvp" validacao/monitor_antes.sv
vvp "$env:TEMP/ula_monitor_antes.vvp"
iverilog -g2012 -s timing_tb -o "$env:TEMP/ula_monitor_depois.vvp" validacao/monitor_depois.sv
vvp "$env:TEMP/ula_monitor_depois.vvp"
```

A versão anterior deve falhar; a versão posterior deve terminar com `errors=0` e `seen=1111111111`.

**Limites:** este teste valida a temporização extraída, não a compilação das classes UVM nem o coverage no Xcelium. O clocking block existente ainda não é usado. O monitor observa ciclos, sem sinal de validade por transação, e pode publicar a mesma operação mantida por vários ciclos. A mudança não implementa reenvio de uma transação interrompida por reset. O filtro de entradas X/Z é adequado aos estímulos binários atuais; testes de propagação de X/Z precisariam de tratamento específico.

### Próxima etapa

Restaurar uma chamada válida de `uvm_error` no scoreboard para reportar divergências como erros UVM. Depois, ajustar as constraints e criar os estímulos dirigidos. Essas mudanças ainda não foram feitas nesta etapa.

## Primeira medição UVM informada pelo usuário — EDA Playground

Após a troca de Riviera-PRO para o fluxo Xcelium, o usuário forneceu o seguinte trecho do log:

```text
UVM_INFO testbench.sv(590) @ 305000: uvm_test_top.env.coverage [COV] === COBERTURA FUNCIONAL: 30.44% ===
UVM_INFO testbench.sv(427) @ 305000: uvm_test_top.env.sb [ula_scoreboard] Scoreboard summary: Matches=28, Mismatches=0
```

| Métrica | Valor observado |
|---|---:|
| Cobertura funcional agregada | 30,44% |
| Amostras com resultado e flags esperados | 28 |
| Amostras com divergência | 0 |
| Instante impresso no log | 305000 |

**Interpretação:** a execução chegou à fase de relatório e o scoreboard não encontrou divergências nas 28 amostras recebidas. Elas não representam necessariamente 28 operações distintas: o monitor publica por ciclo e pode conferir novamente operandos mantidos pelo driver, inclusive durante a espera final do teste.

Os 30,44% são uma referência do modelo de coverage reestruturado com os estímulos ainda limitados. Esse valor não significa que 30,44% das operações estejam corretas e não permite identificar sozinho os bins atingidos ou ausentes. As lacunas previstas pelas constraints e pela sequência ainda precisam ser tratadas.

**Proveniência e limites:** resultado executado pelo usuário e transcrito nesta sessão, não executado localmente pelo assistente. O trecho não inclui versão do simulador, seed efetivamente utilizada, resumo completo de erros UVM ou identificação exata dos fontes executados. A configuração recomendada era seed 1, mas o trecho não a confirma. Guarde o log completo e as cópias usadas no Playground para permitir reprodução. Esta medição não é diretamente comparável à porcentagem do modelo antigo, cujos bins e crosses eram diferentes.

**Próximos passos:** restaurar o erro do scoreboard; acrescentar um resumo por coverpoint/cross para localizar as lacunas; depois modificar os estímulos e medir novamente com a mesma configuração.

## Etapa 2 — Revisão dos crosses e estímulos para pelo menos 95%

Implementada a revisão solicitada dos quatro pontos: preservação das exclusões válidas de carry, manutenção de todos os bins de zero, aumento para 1.000 transações aleatórias, seleção entre cinco tipos e liberação das constraints que impediam SUB com `a <= b` e DIV por zero. Acrescentadas 499 transações dirigidas, relatório por coverpoint/cross, CSV, meta de 95% e erros ativos no scoreboard.

O [registro detalhado da etapa 2](ETAPA_2_COBERTURA95.md) contém o antes/depois, o [diff completo](02_cobertura95.diff), os parâmetros de execução e a revisão dos pontos solicitados. A auditoria local encontrou testemunhas para as 195 metas atuais e os 499 vetores passaram na simulação do RTL extraído. **A nova porcentagem UVM ainda não foi medida; 30,44% continua sendo a referência anterior.**

### Execução da etapa 2 informada pelo usuário — coleta de cobertura desabilitada

O log fornecido identifica a instalação `/xcelium25.03` e a biblioteca `CDNS-1.2`. Foram observados:

| Informação | Resultado |
|---|---:|
| Transações dirigidas | 499 |
| Transações aleatórias | 1.000 |
| Total enviado | 1.499 |
| Tipos aleatórios mid / low / high / corner / full | 191 / 206 / 191 / 192 / 220 |
| Amostras recebidas pelo coverage | 3.006 |
| Matches / mismatches | 3.006 / 0 |
| Cobertura impressa | 0,00%, com 0/0 bins em todas as métricas |

O simulador emitiu `COVNSM`, informando que a amostragem de `ula_coverage::cg_ula` não estava habilitada e que os métodos de consulta retornariam zero. Consequentemente, o teste emitiu `UVM_ERROR [COV_GOAL]`.

**Conclusão:** a geração de estímulos e a conferência do scoreboard executaram, sem divergências nas amostras observadas. Entretanto, **a cobertura não foi coletada**. O valor 0,00% não é uma regressão válida frente aos 30,44% anteriores; esta execução deve ser registrada como cobertura indisponível por configuração.

`samples_observed` conta chamadas a `write()`/`sample()` e não confirma que o simulador contabilizou os bins. A ausência de instrumentação é a primeira hipótese a verificar: a linha efetiva de `xrun` deve conter `-coverage all`. O trecho recebido não contém essa linha, portanto não permite determinar se a opção foi omitida ou se outra configuração desabilitou a coleta.

**Ação para repetir:** no Playground, usar `-coverage all -covoverwrite -covfile coverage.ccf` em Compile Options e `-svseed 1 +NUM_TRANSACTIONS=1000 +RUN_CORNERS=1 +COV_GOAL=95` em Run Options. O arquivo `coverage.ccf` foi incluído para selecionar explicitamente os covergroups funcionais. Executar novamente pelo botão Run para compilar/elaborar com cobertura habilitada. Confirmar a ausência de `COVNSM` e denominadores não nulos, por exemplo `opr_cp` com sete bins, antes de interpretar o percentual.

## Etapa 3 — Revisão de estilo e preparação da coleta funcional

**Data:** 18/09/2026.

**Arquivos principais:** `ula.sv`, `ula_if.sv`, `ula_item.sv`, `ula_driver.sv`, `ula_monitor.sv`, `ula_scoreboard.sv`, `ula_coverage.sv`, sequência, ambiente, teste, `files.f` e arquivos do EDA Playground.

### Antes e depois

| Ponto | Antes | Depois |
|---|---|---|
| Formatação | Mistura de tabs/espaços, blocos de uma linha e comentários com caracteres corrompidos | Quatro espaços, blocos explícitos e comentários revisados |
| Lista de compilação | Todos os arquivos em uma linha e `top_tb.sv` antes das classes | Um arquivo por linha, em ordem de dependência, com `top_tb.sv` ao final |
| Reset do resultado | `u_if.result <= 32'b0` para sinal de 64 bits | `u_if.result <= 64'b0` |
| Modelo de referência | Comparava `result[63:0]` com `32'b0`; códigos da operação repetidos em literais | Compara com `64'b0` e usa `ula_item::OP_*` |
| Monitor | Declarava e criava `trans_collected`, que não era usado | Variável e criação removidas |
| Coleta no Xcelium | O aviso `COVNSM` resultava em todos os bins `0/0` | Adicionados `coverage.ccf` e instruções para `-covfile coverage.ccf` |

O `coverage.ccf` contém `select_functional` e `select_coverage covergroup`. A chamada `cg_ula.start()` também deixa explícito, no código, que a instância deve aceitar amostras. Ela não substitui a instrumentação do simulador: a confirmação definitiva ainda depende de executar Xcelium sem `COVNSM`.

O gerador `eda_playground/preparar.py` passou a copiar o arquivo de configuração, além de `design.sv` e `testbench.sv`. Após editar fontes, execute:

```powershell
python eda_playground/preparar.py
python eda_playground/preparar.py --check
```

### Validação

- `preparar.py --check`: cópias do Playground atualizadas.
- `validar_metas.py`: 499 vetores dirigidos aprovados; 195 de 195 metas têm uma testemunha no plano dirigido.
- `monitor_depois.sv`: Icarus concluiu com `samples=19`, `errors=0` e os dez vetores observados.

O Icarus não elabora a interface completa com `clocking block`/`modport` usada pelo UVM. Por isso, a validação RTL extrai a lógica da ULA para sinais locais; a compilação e a coleta de cobertura completas continuam pendentes no Xcelium.

## Etapa 4 — Visibilidade do UVM em arquivos compilados separadamente

**Data:** 21/09/2026.

### Erro observado

Na primeira execução local com Xcelium, `ula_item.sv` produziu `SVNOTY` para `uvm_sequence_item` e `NOTDIR` para `` `uvm_object_utils``. Os erros seguintes sobre `rand`, constraints, classes e `uvm_config_db` foram efeitos em cascata após o compilador deixar de reconhecer a classe UVM inicial.

O comando também forneceu `ula_if.sv` explicitamente e por meio de `files.f`, produzindo o aviso `RECOME` de recompilação da interface.

### Causa

No arquivo agrupado do EDA Playground, um único `import uvm_pkg::*;` deixava o pacote visível para todas as classes seguintes. No fluxo `-f files.f`, cada fonte é compilado separadamente. Sete arquivos de classes não possuíam seu próprio `include` dos macros nem o `import` do pacote.

### Alteração

Foram acrescentadas as linhas abaixo no início de `ula_item.sv`, `ula_driver.sv`, `ula_monitor.sv`, `ula_sequencer.sv`, `ula_sequence.sv`, `ula_agent.sv` e `ula_env.sv`:

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;
```

O [diff da etapa 4](03_import_uvm_xcelium.diff) registra o antes/depois. O guia de execução também passou a registrar o diagnóstico desses códigos de erro.

### Comando corrigido

Use somente `files.f`, pois ele já contém `ula_if.sv`, e selecione explicitamente o arquivo de cobertura:

```bash
xrun -64bit -uvm -access +rw -coverage all -covfile coverage.ccf \
  -svseed 1 -covworkdir cov_etapa2 -covtest etapa2_seed1 \
  -f files.f \
  +NUM_TRANSACTIONS=1000 +RUN_CORNERS=1 +COV_GOAL=95 \
  -l etapa2_seed1.log
```

### Validação

- Todos os arquivos de classes listados em `files.f` possuem agora `uvm_macros.svh` e `import uvm_pkg::*;` no próprio escopo de compilação.
- `eda_playground/preparar.py --check` confirmou os 15 fontes preservados nas cópias agrupadas.
- A nova compilação com Xcelium permanece pendente no computador do laboratório; esta máquina não possui `xrun` no PATH.
