# Protocolo SPI recuperado do SDK A121 v1.13.0

Leia primeiro o [escopo e os limites](README.md). Todos os valores internos abaixo classificados como **R** vieram de análise estática do SDK. Nenhuma transação foi executada por uma FPGA em bancada nesta análise.

## 1. Camada elétrica e temporal — D

- SPI modo 0: CPOL = 0, CPHA = 0.
- MSB primeiro.
- SCK em nível baixo quando ocioso.
- MOSI amostrado na subida de SCK; MISO atualizado na descida.
- SS ativo em nível baixo.
- Frequência máxima SCK: 50 MHz.
- Datasheet: SS setup mínimo de 1 ns; hold mínimo de 2 ns.
- MOSI setup mínimo de 1 ns; hold mínimo de 2,5 ns.
- Atraso máximo de MISO especificado de 5,5 ns a 3,3 V/10 pF e 7,5 ns a 1,8 V/10 pF, nas condições/configuração indicadas na tabela.
- Respeitar todas as condições de teste da tabela ao fechar timing; esses números isolados não calculam a margem da sua placa.

As transações observadas no SDK são montadas como palavras de 16 bits. É possível serializá-las com um deslocador de bits ou de bytes, preservando rigorosamente a ordem no fio.

### Pendência importante: SS

O datasheet e o guia de integração descrevem SS baixo durante a transação e liberação entre transações. O `main.c:466` coloca SPI_SS inicialmente em zero, e a função `acc_hal_integration_sensor_transfer16` deste port XM125 não alterna explicitamente esse GPIO.

Esta análise não demonstrou a razão dessa diferença. O controlador proposto deve permitir configurar os intervalos de SS e partir da sequência documentada. Antes de fixar esse comportamento no RTL, conferir esquema, execução real do firmware e sinais em bancada. Não usar o comportamento isolado da HAL para concluir que SS é dispensável.

## 2. Notação

`W0`, `W1` etc. são palavras sucessivas de **16 bits** no fio; o bit 15 sai primeiro. `N16` é quantidade de palavras de payload de 16 bits, não quantidade de bytes.

Nas leituras, o mestre transmite zeros suficientes para gerar o clock da resposta. Descartar as palavras recebidas antes da posição de payload identificada. Não dividir uma transação em várias pulsações de SS.

Não generalizar uma máscara de endereço de 12 bits para todos os comandos: o acesso ao buffer tem um campo de endereço separado.

## 3. Formatos encontrados — R

| Operação | Palavras transmitidas | Resposta útil | Evidência em `out/example_service.list` |
|---|---|---|---|
| Escrever registrador | `0x1000 OR reg`, `valor` | Não usada nesta rotina | `internal_reg_write`, trechos em 2061 e 3348 |
| Ler registrador | `0x3000 OR reg`, `0`, `0` | RX W2 | `acc_sensor_status`, a partir de 2009 |
| Escrever memória de configuração | `0x5000 OR endereço`, `N16-1`, payload | Não usada | `acc_sensor_a121_load_confmem`, 2411 |
| Ler uma instrução de configuração | `0xA000 OR endereço`, `1`, `0`, `0`, `0` | RX W3 = metade alta; RX W4 = metade baixa | `acc_confprogram_live_patch`, 8466, leitura em 8558 |
| Ler buffer de dados | `0x8000`, `endereço`, `N16-1`, `0`, N16 zeros | RX W4 em diante | `internal_buffer_processed_read`, 8368 |
| Escrever LUT | `0xC000 OR endereço`, `N16-1`, payload | Não usada | `acc_sensor_a121_lut_buffer_write`, 7780 |

A leitura de configuração acima foi confirmada no caso de uma instrução de 32 bits. A fórmula geral de blocos deve ser confrontada com a rotina completa antes de ser usada.

Há variantes internas de comando que esta tabela não cobre, incluindo escrita com strobe. Não inferir seus códigos por progressão numérica.

### Exemplo: identificar o circuito

```text
MOSI:  3000  0000  0000
MISO:  xxxx  xxxx  ID
```

O caminho de criação do sensor lê o registrador 0x0000 e testa:

`(ID & 0xFFF0) == 0x1210`.

**R:** listagem, linhas 18099–18135. Os quatro bits inferiores são ignorados pelo teste de revisão principal. Este é um bom primeiro teste de comunicação; não demonstra que o radar já esteja configurado.

### Exemplo: escrever uma instrução de 32 bits

Para endereço de instrução `a` e instrução `0x12345678`:

```text
MOSI: (5000 OR a)  0001  1234  5678
```

O endereço é tratado como índice de instrução de 32 bits pelo caminho de configuração. Já o tamanho informado é de palavras de 16 bits. Confirmar a unidade de cada memória evita avançar o endereço pelo dobro ao carregar blocos.

## 4. Registradores identificados — R

| Endereço | Uso observado | Semântica recuperada |
|---|---|---|
| 0x0000 | ASIC ID | Comparação de revisão principal descrita acima |
| 0x001B | MAIN_RUN_CONFIG | Início de programa: escrever 0; depois `0x0800 OR entry_address` |
| 0x001C | Estado de execução | Máscara 0x0800 indica programa executando |
| 0x0037 | Status de interrupção | Máscara combinada A/B 0x00C0 no caminho `prepare_load` |
| 0x0033 | Evento buffer A | Campo de código em bits [2:0] |
| 0x0032 | Evento buffer B | Campo de código em bits [2:0] |
| 0x0045 | ACK de evento A | A rotina faz **leitura**, com efeito de reconhecimento |
| 0x0046 | ACK de evento B | A rotina faz **leitura**, com efeito de reconhecimento |
| 0x0083 | Wakeup associado a A | Escrita zero quando `clear_wakeup` é solicitado |
| 0x0084 | Wakeup associado a B | Escrita zero quando `clear_wakeup` é solicitado |
| 0x007B | Mux de saída de interrupção | RMW de máscara 0x00FF para valor 0 na inicialização |
| 0x008B | Configuração de GPIO de interrupção | RMW bit 1 = 1; RMW bit 7 = 0 |

RMW significa ler, alterar só os bits indicados e escrever de volta:

`novo = (antigo & ~mask) | ((valor << posição) & mask)`.

O reconhecimento de evento não é uma escrita genérica de “limpar bit”. Uma leitura exploratória de todos os registradores pode consumir eventos. A rotina de ACK também verifica se o valor retornado é diferente de zero.

A enumeração de software usa ANY = 0, A = 1 e B = 2. Esses números não são as máscaras de interrupção. A semântica completa dos códigos de evento/erro deve ser consolidada antes da FSM definitiva.

### Execução do programa de medição

A primeira chamada de medida inicia a entrada `MEAS_SESSION_MAIN`, recuperada como **21 decimal / 0x15**, resultando em escrita 0x0815 no registrador 0x001B depois de escrever zero e verificar o estado.

Isso só faz sentido **após** carregar o programa correspondente devidamente alterado e configurar os recursos necessários. Não é um comando autossuficiente de “medir distância”.

Nas medidas seguintes, o caminho observado reconhece o evento e libera o programa para continuar. A ordem exata de ler/confirmar/avançar deve seguir o modo de aquisição escolhido; não reconhecer o buffer antes de terminar de usá-lo.

## 5. Memória de dados e dimensionamento — R/P

O caminho de leitura seleciona:

- base do buffer A: 0x0000;
- base do buffer B: 0x1000;
- capacidade total verificada pelo software: 8192 palavras de 16 bits;
- em double buffering, orçamento de metade dessa memória para cada buffer.

Evidência: `acc_radar_engine_121_populate_metadata`, linha 2251, e caminho inlined em 18680–18700.

O payload não é necessariamente só o frame I/Q. Os metadados contêm comprimento total e offsets para saturação, temperatura, CCA, frame e subsweeps. Não confundir posição de um campo na estrutura C de metadados com posição do próprio campo no fio.

Para uma leitura em bloco:

`bits_spi = 16 × (4 + N16)`.

Para vários blocos, somar o cabeçalho de quatro palavras de cada transação. O SDK usa seu limite de transferência para fragmentar e mantém blocos intermediários pares. Uma implementação com FIFOs separados de comando/dados não precisa repetir as manobras de `memcpy` usadas para sobrepor buffers na RAM do STM32.

**Exemplo de orçamento, não configuração validada:** 1024 palavras de payload em uma transação a 10 MHz consomem cerca de 1,645 ms no fio, excluindo intervalos de SS, aquisição, calibração e processamento.

## 6. Imagens extraídas — R

| Programa | Bytes | Palavras de 32 bits | Palavras de 16 bits |
|---|---:|---:|---:|
| Medição | 5056 | 1264 | 2528 |
| Calibração | 5784 | 1446 | 2892 |

As duas bases juntas ocupam 10840 bytes. Isso não inclui tabelas, configuração modificada, dados, filtros, coeficientes e memória do controlador.

A imagem de medição coincide entre os ELFs de serviço e detector de distância. A de calibração coincide entre serviço, detector e bring-up. Os hashes completos estão em `generated/manifest.json`.

### Ordem das palavras

No ELF do STM32 as palavras de 32 bits estão armazenadas em little-endian. A rotina `acc_confprogram_copy` converte cada palavra:

```text
uint32 = 0x12345678
bytes no ELF:       78 56 34 12
palavras SPI:       1234 5678
bytes no fio:       12 34 56 78
```

Por isso, ler o `.host_le.bin` byte a byte e transmiti-lo diretamente não reproduz o SDK. Usar os arquivos `.spi16.hex` como representação da ordem das palavras, e serializar cada palavra MSB primeiro.

## 7. Como as imagens são alteradas — R

Cada entrada da tabela de referências tem 8 bytes nesta compilação:

| Offset na entrada | Conteúdo |
|---:|---|
| +0 | Campo de 16 bits preservado como `field0_raw`; sem semântica presumida |
| +2 | Quantidade de referências, 16 bits |
| +4 | Ponteiro de 32 bits para referências no ELF do STM32 |

Os ponteiros 0x0800.... são endereços do host. **Não devem ser enviados ao A121.** O extrator resolve esses ponteiros e exporta o conteúdo das referências.

Em cada referência de 32 bits:

- bits [15:0]: índice de palavra/instrução de 32 bits da imagem;
- bits [29:28]: tipo de alteração;
- para tipo 0: bits [25:21] são largura; [20:16] são posição do campo;
- para os tipos condicionais: bits [19:16] contêm o opcode.

Para tipo 0:

```text
mask = ((1 << largura) - 1) << posição
nova_instrução = (antiga & ~mask) | ((valor << posição) & mask)
```

A rotina rejeita valores que não cabem na largura. O tipo 1 é `runif`: limpa os quatro bits inferiores da instrução e insere o opcode se o valor for diferente de zero. O tipo 2 segue o caminho condicional inverso, cujo detalhe deve ser conferido antes de implementar o mecanismo completo.

Além da alteração em RAM antes do carregamento, existe `acc_confprogram_live_patch`, que lê uma instrução já no sensor e a modifica.

### Correspondência da configuração de medição

A rotina `patch_program_parameters`, a partir da linha 4353, percorre 226 valores de 16 bits da estrutura de parâmetros. Para cada valor, uma tabela de bytes informa qual entrada da tabela da imagem será alterada.

O manifesto fornece:

`parameter_struct_byte_offset → image_parameter_index → references_decoded`.

Os tipos DWARF fornecem os nomes e posições dos membros da estrutura. A estrutura contém calibração, subsweeps, contadores, tempos, estados de repouso e flags. Isso recupera **onde** aplicar os valores; reconstruir `acc_translation_a121_translate` é o trabalho necessário para calcular **quais** valores aplicar.

## 8. Navegação na listagem

Todos os números abaixo referem-se ao arquivo original `out/example_service.list`.

| Linha inicial | Função/assunto |
|---:|---|
| 1939 | Transferência do dispositivo pela integração |
| 2251 | Metadados e orçamento de buffer |
| 2363 | Escrita de instrução de configuração |
| 2411 | Carregamento de memória de configuração |
| 2468 | Início de programa |
| 2556 | ACK de evento |
| 2668 | Leitura de evento |
| 3137 | Alteração de campos da imagem |
| 3325 | RMW de registrador |
| 3387 | Inicialização da interrupção |
| 3419 | Preparação para carregamento |
| 4353 | Aplicação dos parâmetros de medição |
| 7780 | Escrita de LUT |
| 7905 | Correções de fase e desequilíbrio I/Q |
| 8368 | Leitura de buffer |
| 8466 | Alteração de programa já no sensor |
| 8602 | Tradução da configuração de alto nível |
| 11194 | Calibração e preparação, com funções inlined |
| 18099 | Leitura de identificação |
| 18340 | Entrada 0x15 do programa de medição |

Os trechos C estão intercalados pelo otimizador e podem aparecer repetidos ou incompletos. Eles ajudam a interpretar o assembly; não formam automaticamente um código fonte recompilável.

