# Etapa 2 — Estímulos e diagnóstico para a meta de 95%

## Referência anterior

Resultado informado pelo usuário no EDA Playground: **30,44%**, **28 matches**, **zero mismatches**. Os fontes anteriores a esta etapa estão no commit `c42547d`. O [diff completo](02_cobertura95.diff) registra o antes/depois dos códigos desta etapa.

## Revisão dos quatro pontos solicitados

| Ponto | Diagnóstico | Decisão |
|---|---|---|
| `opr_carry_cross` | O arquivo modificado já excluía `carry=1` para AND, OR e NOT. | Manter essas três exclusões e manter `carry=0` para as operações lógicas. |
| `opr_zero_cross` | Cruza operação com **zero**, não com carry. Todos os 14 bins são alcançáveis. | Manter todos os bins e gerar os operandos necessários. |
| `num_transactions` | Apenas 10 transações aleatórias; não era suficiente para explorar as categorias. | Usar 1.000 aleatórias por padrão, configuráveis por plusarg, após 499 dirigidas. |
| Seleção do tipo | O bit sorteava corretamente dois tipos. A limitação era não selecionar classe média, corners ou faixa completa. | Sortear um enum com cinco tipos e reportar as quantidades efetivamente selecionadas. |
| Restrições | `a > b` em SUB e `b != 0` em DIV bloqueavam comportamentos previstos na ULA e no coverage. | Remover essas duas restrições; preservar opcodes de 0 a 6. |

### Por que não excluir operações lógicas de `opr_zero_cross`?

| Operação | Exemplo com zero=1 | Exemplo com zero=0 |
|---|---|---|
| AND | `0 & FFFFFFFF` | `1 & 1` |
| OR | `0 | 0` | `0 | 1` |
| NOT | `~FFFFFFFF` | `~0` |

O RTL usa o resultado completo de 64 bits para definir `zero`. A extensão por zeros dos resultados lógicos não impede nenhum desses exemplos.

**Nenhum bin ou cross foi removido/adicionado nesta etapa.** As metas permanecem as mesmas da medição de 30,44%; houve mudanças nos estímulos e nos relatórios. `other_values` continua um único bin com quatro intervalos; atingir um desses intervalos cobre esse bin. Assim, 100% deste modelo não significa ter exercitado todos os valores de 32 bits.

## Antes e depois nos códigos

### 1. `ula_item.sv`: liberar os comportamentos de borda

**Antes:**

```systemverilog
constraint operacao_subtrair {
    (opr == OP_SUB) -> (a > b);
}
constraint operacao_dividir {
    (opr == OP_DIV) -> (b != 32'b0);
}
```

**Depois:** essas duas constraints foram removidas. Subtração com igualdade/emprestimo e divisão por zero podem ser sorteadas. A divisão por zero é um caso funcional do RTL: resultado zero e carry/erro em 1; não é tratada como estímulo proibido.

Na classe `limite_transaction`, o limite inferior passou a ser inclusivo:

```systemverilog
// Antes
a > {32'hFFFFFF00};

// Depois (também para B)
a inside {[32'hFFFFFF00:32'hFFFFFFFF]};
```

Foram acrescentadas duas subclasses que substituem `reasonable_values`:

```systemverilog
// corner_transaction, também para B
a inside {32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555};

// full_range_transaction, também para B
a inside {[32'd0:32'hFFFFFFFF]};
```

O `convert2string()` agora informa também opcode, zero e os 64 bits do resultado.

### 2. `ula_sequence.sv`: cinco tipos e duas fases de estímulos

**Antes:**

```systemverilog
rand int num_transactions = 10;
rand bit rand_item;
constraint rand_i { rand_item inside {0, 1}; }
// std::randomize(rand_item) e escolha entre facil_transaction/limite_transaction.
```

**Depois:**

```systemverilog
int unsigned num_transactions = 1000;
bit run_corners = 1;
typedef enum int unsigned {
    ITEM_MID, ITEM_LOW, ITEM_HIGH, ITEM_CORNER, ITEM_FULL
} item_kind_t;
```

O corpo sorteia `item_kind` com `std::randomize` e seleciona a classe em um `case`. O enum limita os valores aos cinco tipos. Eles têm o mesmo peso de sorteio, mas não se exige exatamente 200 de cada tipo em 1.000 transações. Os contadores `type_count` tornam essa distribuição observável no log.

O `rand_i` anterior era redundante para um bit e não era aplicado como constraint da classe por `std::randomize(rand_item)`. Isso não tornava inválido o sorteio binário; o problema funcional era a escolha entre apenas duas classes.

Antes da fase aleatória, `send_corner_cases()` percorre os representantes:

```systemverilog
logic [31:0] values[9] = '{
    32'd0, 32'd1, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555,
    32'd2, 32'd1000, 32'hFFFFFFFE, 32'd101
};
```

- ADD, SUB, MUL, DIV, AND e OR: todas as combinações de A e B, **6 × 9 × 9 = 486** transações.
- NOT: cada representante de A, **9** transações; B não participa da operação.
- MUL: quatro pares adicionais com 65535/65536, em torno da fronteira de resultado de 32 bits.
- **Total dirigido: 499**. Com a configuração padrão, **1.499 transações enviadas**.

As dirigidas atribuem `opr`, `a` e `b` diretamente entre `start_item` e `finish_item`. Não chamam `randomize()`, portanto não entram em conflito com a faixa média da classe base. Elas percorrem somente opcodes válidos. A fase aleatória continua usando as constraints das subclasses.

Falhas de randomização passaram de `uvm_error` seguido de envio do item para `uvm_fatal`, impedindo que um item não randomizado continue no teste.

### 3. `ula_test.sv`: configuração pela linha de comando

Antes, não havia ajuste de quantidade por plusarg. Agora:

- `+NUM_TRANSACTIONS=N`: número de transações **aleatórias**, aceitando zero; valores negativos são rejeitados.
- `+RUN_CORNERS=1` ou `0`: habilita/desabilita a fase dirigida; padrão 1.

O teste ainda mantém a espera final de `#100`. No pacote Playground, `timescale 1ns/1ps` torna essa espera suficiente para a última coleta na borda de descida. O monitor continua observando ciclos: matches não devem ser interpretados como contagem de transações únicas.

### 4. Scoreboard e diagnóstico

**Antes:** a chamada de `uvm_error` estava comentada; só o contador de mismatches era incrementado.

**Depois:** uma chamada válida de `uvm_error` informa opcode, operandos e resultado/flags esperados e observados. As mensagens são concatenadas com `{...}`, substituindo as barras invertidas do trecho comentado. `check_phase` também sinaliza erro se nenhuma amostra foi conferida.

Os logs de cada drive e cada match passaram para `UVM_HIGH`, evitando milhares de linhas no Playground. Resumos e erros permanecem visíveis. Para depurar cada amostra, use `+UVM_VERBOSITY=UVM_HIGH`.

### 5. `ula_coverage.sv`: detalhamento e meta

**Antes:** somente a porcentagem agregada no `report_phase`.

**Depois:** mantém o agregado e acrescenta, para os nove coverpoints e cinco crosses:

```systemverilog
percent = cg_ula.opr_carry_cross.get_inst_coverage(covered, total);
report_metric("opr_carry_cross", percent, covered, total, csv);
```

O resultado aparece como `COV_DETAIL` no log e em `ula_coverage.csv`, com as colunas `metric,percent,covered_bins,total_bins`. O CSV contém totais por métrica, não os hits individuais dos bins.

`COV_GOAL` compara a cobertura agregada com **95% por padrão**, ajustável por `+COV_GOAL=95`. Se a meta não for atingida, ou nenhuma amostra for observada, emite `uvm_error`. A mensagem de meta atingida indica somente a cobertura: o teste também precisa ter zero mismatches e nenhum erro de execução.

## Validação local realizada

O script [validar_metas.py](validacao/validar_metas.py) lê os representantes dirigidos e as definições de bins dos fontes atuais. Para cada meta, procura um vetor com os operandos e o resultado esperado que a exercitam.

| Métrica | Metas com vetor testemunha |
|---|---:|
| `opr_cp` | 7/7 |
| `a_val`, `b_val` | 9/9 cada |
| `result_cp` | 6/6 |
| `carry_cp`, `zero_cp` | 2/2 cada |
| `sub_order_cp`, `div_denominator_cp` | 3/3 cada |
| `alternating_pair_cp` | 4/4 |
| `opr_a_cross` | 63/63 |
| `opr_b_cross` | 54/54 |
| `logical_pattern_cross` | 8/8 |
| `opr_carry_cross` | 11/11 |
| `opr_zero_cross` | 14/14 |

São **195 metas com testemunha**. Os exemplos, inclusive resultados e flags, estão em [metas_dirigidas.csv](validacao/metas_dirigidas.csv).

Os **499 vetores dirigidos passaram** em uma simulação Icarus do corpo RTL extraído de `ula.sv`, com a interface substituída por sinais locais. A referência usa aritmética Python independente: resultado de subtração módulo 2^64, carry por comparação, e os comportamentos definidos para divisão por zero e operações lógicas. Resultado completo: [resultado_metas.txt](validacao/resultado_metas.txt).

Para reproduzir, a partir de `ula_coverage_mod`, com Python e Icarus no PATH:

```powershell
python relatorio/validacao/validar_metas.py
```

**Limite da evidência:** esta auditoria demonstra que o plano de estímulos possui casos para todas as metas do modelo atual e que o RTL extraído respondeu corretamente aos vetores. Ela não executa as classes UVM, o solver das constraints, a seleção dos cinco tipos ou os covergroups nativos. **Não é uma medição de 100% no Xcelium.** A primeira medição conhecida continua sendo 30,44%; o resultado desta etapa ainda deve ser obtido no Playground. Não foi possível instalar um verificador adicional de sintaxe neste ambiente por restrição de rede.

## Próxima execução no Playground

As cópias em `eda_playground` foram regeneradas. Substitua o conteúdo das duas abas pelo conteúdo atual dos arquivos gerados.

Use **Xcelium**, **UVM 1.2**, Compile Options:

```text
-coverage all -covoverwrite
```

Run Options para a execução padrão:

```text
-svseed 1 +NUM_TRANSACTIONS=1000 +RUN_CORNERS=1 +COV_GOAL=95
```

Uma execução curta, somente com as 499 dirigidas, pode usar:

```text
-svseed 1 +NUM_TRANSACTIONS=0 +RUN_CORNERS=1 +COV_GOAL=95
```

Para investigar o efeito somente do aumento/seleção aleatória, use `+RUN_CORNERS=0`. Nesse modo, a meta pode falhar porque casos exatos deixam de ser garantidos.

Guarde `SEQ_SUMMARY`, `COV_DETAIL`, `COV_GOAL`, o resumo do scoreboard, a versão do simulador e a seed. Marque **Download files after run** para baixar o CSV e o log. A expectativa é que o plano dirigido cubra todas as metas atuais se a execução e a amostragem UVM ocorrerem como previsto; confirme os números em vez de registrá-los antecipadamente como medidos.
