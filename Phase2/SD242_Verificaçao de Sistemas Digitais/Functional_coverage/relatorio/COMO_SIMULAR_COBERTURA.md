# Executar a cobertura funcional e consultar no IMC

**Sem acesso ao laboratório:** consulte o [fluxo EDA Playground](../eda_playground/README.md). A tentativa com Riviera-PRO foi bloqueada por licença de recursos avançados de SystemVerilog; o guia agora indica Xcelium no navegador como alternativa condicionada à validação da conta. As instruções abaixo são para o ambiente Cadence.

## Ambiente

Execute no ambiente com Xcelium e IMC configurados e com licença disponível, como o ambiente usado para as métricas anteriores. Na sessão Windows inspecionada, `xrun` e `imc` não foram encontrados no PATH. O teste isolado com Icarus da etapa 1 não gera a base de cobertura funcional deste ambiente UVM para o IMC.

Os comandos abaixo são para o terminal Linux do ambiente Cadence, a partir da pasta `ula_coverage_mod`, onde está `files.f`.

## 1. Executar o estado atual

```bash
xrun -64bit -uvm -access +rw -coverage all -covfile coverage.ccf \
  -svseed 1 \
  -covworkdir cov_etapa2 \
  -covtest etapa2_seed1 \
  -f files.f \
  +NUM_TRANSACTIONS=1000 +RUN_CORNERS=1 +COV_GOAL=95 \
  -l etapa2_seed1.log
```

- `-coverage all -covfile coverage.ccf`: habilita a instrumentação de cobertura e seleciona os covergroups funcionais.
- `-svseed 1`: fixa a semente de randomização para registrar e repetir esta execução.
- `-covworkdir cov_etapa2`: usa uma pasta própria para os dados desta etapa.
- `-covtest etapa2_seed1`: identifica esta execução dentro da base.
- `-l etapa2_seed1.log`: salva o log.
- Os plusargs configuram 1.000 transações aleatórias após as 499 dirigidas e meta de 95%.

`ula_if.sv` já está em `files.f`; não é necessário repeti-lo na linha de comando. O comando executa compilação, elaboração e simulação, sem abrir o SimVision. Aguarde a conclusão normal do teste para salvar a cobertura.

O comando não usa `-covoverwrite`. Em uma nova execução, escolha outro nome de teste e de log, por exemplo `etapa2_seed1_r2`. Preserve também a pasta original `cov_work` e as bases anteriores.

Ao terminar, consulte no log:

```text
=== COBERTURA FUNCIONAL: ...% ===
Scoreboard summary: Matches=..., Mismatches=...
```

A primeira linha vem de `ula_coverage::report_phase`. Confira erros de compilação, erros fatais e a conclusão do teste antes de interpretar a métrica. A etapa 2 reativou `uvm_error` do scoreboard. Exija `Matches > 0`, `Mismatches=0`, ausência de erros UVM e a meta atingida em `COV_GOAL`. Consulte `COV_DETAIL` e `ula_coverage.csv` para os totais por coverpoint/cross.

### Se aparecer `SVNOTY` em `uvm_sequence_item` ou `NOTDIR` nos macros UVM

Cada arquivo de classes compilado separadamente precisa importar `uvm_pkg` e incluir `uvm_macros.svh`. Os fontes atuais já possuem estas duas linhas. Confirme também que a opção `-uvm` está presente e que os arquivos copiados para o laboratório correspondem à versão atual.

Não acrescente `ula_if.sv` antes de `-f files.f`: a interface já está na primeira linha do arquivo de lista. A repetição causa o aviso `RECOME` e pode dificultar a leitura do log, embora não seja a causa dos erros UVM.

## 2. Abrir os resultados no IMC

Na mesma pasta:

```bash
imc -load ./cov_etapa2/scope/etapa2_seed1
```

Alternativamente, abra o IMC e use no console:

```tcl
load -run ./cov_etapa2/scope/etapa2_seed1
```

O caminho considera o scope padrão `scope`. Se houver configuração externa alterando esse nome, consulte a localização produzida pelo simulador. Preserve a árvore de cobertura completa: ela contém tanto o modelo `.ucm` quanto os dados `.ucd`.

Na visualização de cobertura funcional, localize o covergroup `cg_ula` da classe `ula_coverage`, associado ao componente `uvm_test_top.env.coverage`. Inspecione os bins e seus hits em `a_val`, `b_val`, `opr_cp`, `result_cp` e nos crosses. A apresentação exata da hierarquia varia com a versão do IMC.

Use uma versão de IMC compatível com a versão de Xcelium que gerou a base.

## 3. Comparar com a referência anterior

Mantenha as bases anterior e atual separadas. Para esta análise de antes/depois, não faça merge entre os dois modelos de coverage: eles têm bins e crosses diferentes.

Registre para cada execução:

| Informação | O que anotar |
|---|---|
| Versão dos fontes | Commit e diff da etapa |
| Ferramentas | Versões do Xcelium e do IMC |
| Estímulos | Nome do teste, seed e número de transações |
| Conferência funcional | Matches e mismatches do scoreboard |
| Cobertura | Porcentagem, bins atingidos e bins totais por coverpoint/cross |
| Lacunas | Nomes dos bins sem hits e motivo provável |

Uma porcentagem menor pode resultar da inclusão de novas metas. Por exemplo, antes um único valor na faixa `low` cobria esse bin; agora zero e um precisam de hits próprios. A porcentagem agregada anterior não mede exatamente os mesmos requisitos da atual.

A mudança do monitor também afeta a associação entre entradas e saídas. Portanto, a comparação com a base antiga documenta a evolução do ambiente, não apenas uma mudança de estímulos. Para medir o efeito de futuras sequências, use o mesmo coverage e o monitor corrigido em ambas as execuções.

## Evolução dos estímulos e estado da medição

Na medição anterior de 30,44%, a sequência gerava dez transações entre dois tipos e bloqueava vários corners. A etapa 2 acrescentou cinco tipos de item, liberou os casos definidos no RTL e criou 499 transações dirigidas. Veja o [registro da etapa 2](ETAPA_2_COBERTURA95.md). As definições dos bins foram preservadas; o objetivo é preenchê-los com estímulos reais.

**Estado da validação:** a primeira medição de 30,44% foi informada pelo usuário. Para a etapa 2, os 499 vetores passaram no RTL extraído e têm testemunhas para todas as metas revisadas. A nova compilação UVM e a medição nativa no Xcelium/IMC ainda estão pendentes; o assistente não executou esses simuladores localmente.

## Referências

- [Cadence: instrumentação de cobertura com Xcelium](https://community.cadence.com/cadence_technology_forums/f/functional-verification/62425/xcelium-dump-coverage-information-in-the-middle-of-a-simulation).
- [Cadence: opções de pasta e nome da execução de cobertura](https://community.cadence.com/cadence_technology_forums/f/functional-verification/22453/how-to-create-coverage-configuration-file/1311079).
- [Cadence: carregamento de bases no IMC e compatibilidade de versões](https://community.cadence.com/cadence_technology_forums/f/functional-verification/49374/imc-exception-on-opening-ucm-from-xrun-coverage-generation/1378906).
