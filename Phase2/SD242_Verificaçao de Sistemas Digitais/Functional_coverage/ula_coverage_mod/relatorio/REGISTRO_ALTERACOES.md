# Registro de alterações — ULA e cobertura funcional

Este registro apresenta o problema, o código antes/depois e a validação de cada etapa em `ula_coverage_mod`. As próximas etapas devem ser acrescentadas ao final, preservando o histórico.

Para executar a simulação de cobertura e comparar as bases no IMC, consulte [Como simular a cobertura](COMO_SIMULAR_COBERTURA.md).

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
