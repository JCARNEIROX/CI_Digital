# A121 em SystemVerilog: levantamento para medir distância até líquidos

**Escopo:** substituir o host STM32 por lógica própria, controlar diretamente o A121, obter distância à superfície de um líquido e converter o resultado em PWM ou tensão.
**Base analisada:** SDK local `a121-v1.13.0`, datasheet A121 v1.8 de 03/02/2025 e guia de integração incluído no SDK.
**Estado:** pesquisa e extração de evidências concluídas para esta entrega; controlador completo ainda não implementado nem validado em bancada.

## 1. Conclusão prática

Há mais informação nesta pasta do que apenas as APIs dos arquivos `.h`. As listagens `out/*.list` incluem assembly acompanhado de trechos do código C interno, e os executáveis `.elf` incluem imagens de programa do A121, tabelas de alteração dessas imagens e informações de depuração.

Foi possível recuperar comandos SPI, parte dos registradores, imagens base de calibração e medição, referências de parâmetros e nomes das etapas de calibração. Portanto, existe uma base concreta para estudar uma implementação em SystemVerilog.

**Ainda não existe aqui uma sequência completa e validada que possa ser colocada numa ROM e produzir distância ao ligar.** A calibração depende das respostas do sensor. A configuração de alto nível é traduzida em parâmetros internos e alterações no programa. Depois da aquisição ainda há processamento no host. Os elementos pendentes estão explicitados na seção 10.

### Como ler as evidências

- **D — documentado:** datasheet, guia ou API pública.
- **R — recuperado:** interpretação do binário/listagem desta versão específica.
- **P — proposto:** arquitetura para o seu projeto.
- **V — por validar:** falta confirmação em bancada ou reconstrução completa.

Os números recuperados não constituem uma especificação oficial independente de versão.

## 2. O que foi entregue

| Arquivo/pasta | Conteúdo |
|---|---|
| [PROTOCOLO.md](PROTOCOLO.md) | Transações SPI, registradores identificados, imagens e alterações de parâmetros |
| [ARQUITETURA.md](ARQUITETURA.md) | Blocos SystemVerilog, processamento para líquidos, PWM/tensão e validação |
| [generated/manifest.json](generated/manifest.json) | SHA256, símbolos, imagens, tabelas de referências e correspondência dos parâmetros |
| [generated/debug_types.json](generated/debug_types.json) | Enumerações e posições dos membros de estruturas recuperadas de DWARF |
| [generated/verification.json](generated/verification.json) | Resultado das verificações estáticas da extração |
| `generated/*.spi16.hex` | Imagens base como palavras de 16 bits na ordem usada na transferência |
| `generated/*.words32.hex` | As mesmas imagens como palavras de 32 bits |
| `generated/*.host_le.bin` | Bytes originais extraídos do ELF do STM32 |
| `generated/*.source_fragments.txt` | Trechos C das listagens, com números das linhas originais |
| [generated/function_index.json](generated/function_index.json) | Índice de funções para navegar nas listagens |
| [tools/extract_sdk_evidence.py](tools/extract_sdk_evidence.py) | Extração reproduzível, somente biblioteca padrão Python |
| [tools/extract_debug_types.py](tools/extract_debug_types.py) | Extração de tipos com pyelftools |
| [tools/verify_evidence.py](tools/verify_evidence.py) | Verificação de integridade e consistência |

**As imagens são bases, não programas prontos para enviar sem configuração.** Os arquivos `.hex` são texto de palavras hexadecimais, adequado para preparar ROMs/`$readmemh`; não são Intel HEX.

## 3. Sensor, módulo e interfaces

- **A121:** circuito integrado de radar que será controlado.
- **XM125:** módulo que já incorpora A121, STM32 e componentes de suporte.
- **I²C do firmware XM125:** interface externa disponibilizada pelo STM32, com registradores de distância/presença.
- **SPI do A121:** interface interna usada para carregar programas, configurar e adquirir dados do radar.

Os endereços em `presence_reg_protocol.h` e no protocolo de distância do XM125 **não são o mapa SPI do A121**. Se você substituir o STM32, precisará implementar as funções internas que ele executa; o A121 sozinho não oferece automaticamente a interface I²C de distância do módulo.

O objetivo descrito corresponde a uma placa própria com A121 e controlador. Conectar uma FPGA ao XM125 exige primeiro verificar esquema, acesso aos sinais internos e como impedir que o STM32 dirija o mesmo barramento.

### Memória de programa da Figura 2.1

A presença de memória no diagrama não significa que o programa de medição esteja gravado permanentemente. O guia de integração informa que o host transfere o programa pela SPI na inicialização. Hibernação pode preservar a memória, enquanto uma inicialização após perda de alimentação exige novo carregamento.

A sequência inclui programa de calibração e programa de medição. Não se deve carregar novamente toda a imagem a cada amostra por padrão.

## 4. Hardware mínimo ao redor do A121

**D:** datasheet, tabelas de pinos e seções de alimentação, referência de aplicação e inicialização.

| Função | Ligação/requisito |
|---|---|
| Alimentação analógica/digital | VRX, VTX e VDIG nominais de 1,8 V; intervalo 1,71–1,89 V |
| Alimentação de I/O | VIO em 1,71–1,89 V **ou** 2,97–3,45 V; combinar com os níveis do controlador |
| Referência do sensor | Cristal externo de 24 MHz, com circuito/capacitâncias conforme datasheet |
| SPI | SS, SCK, MOSI, MISO |
| Controle | ENABLE |
| Notificação | INTERRUPT, necessário para coordenar os programas e as aquisições |
| RESET_N | Conectar a VIO conforme tabela de pinos |
| Desacoplamento | Reproduzir o circuito recomendado; BOM inclui capacitores de 1 µF nas alimentações |
| PCB/antena | Seguir o desenho de aplicação e as restrições físicas do fabricante |

Pinos do encapsulamento identificados: SS J2, SCK K2, MISO K3, MOSI K6, ENABLE F10, INTERRUPT K8, RESET_N J1, VIO K9, VDIG J9, VRX C2/D1, VTX C9/D10, XIN J10 e XOUT H10. Esta lista **não substitui o pinout completo para criar o footprint**, particularmente os pinos de terra e reservados.

Analog0/Analog1 não são saídas de distância. O datasheet permite NC ou GND, recomendando GND. CTRL e GPIO1–GPIO4 são reservados e indicados para GND.

### Sequenciamento

1. Durante a subida das alimentações, manter as entradas do A121 no estado exigido pelo datasheet; a seção de startup indica I/Os em 0 V durante t1.
2. ENABLE só pode subir junto ou depois da última entre VDIG e VIO.
3. Aguardar alimentação e oscilador estáveis. O datasheet menciona partida do cristal **tipicamente de 2 ms**; isso não é um máximo garantido para qualquer placa.
4. Antes de transacionar, colocar a SPI em estado ocioso adequado e executar a sequência de carregamento.
5. Não interpretar INTERRUPT como “dados disponíveis” durante a energização: ele fica em alta impedância até o programa do sensor iniciar.
6. Para desligar, baixar ENABLE e seguir a ordem/níveis de I/O especificados antes de retirar VIO.

A espera de 2 ms encontrada nas funções de enable/disable do SDK é uma referência de implementação. O temporizador da sua placa deve ter margem justificada pelo circuito e pelos ensaios.

## 5. Os três clocks são diferentes

| Clock | Papel | O que se sabe |
|---|---|---|
| Referência do A121 | Base temporal interna do sensor | 24 MHz no circuito recomendado |
| SCK da SPI | Transporte dos comandos/dados | Até 50 MHz segundo datasheet; **não é um mínimo** |
| Clock da FPGA | Executa FSMs, aritmética e PWM | Escolhido conforme placa, volume de dados e fechamento de timing |

Você pode usar uma SPI mais lenta no início. O clock da FPGA não precisa ser 24 MHz, nem precisa igualar o SCK. Para um mestre SPI feito com um contador de meio período de K ciclos:

`f_SCK = f_FPGA / (2 × K)`, com `K >= 1`.

Essa fórmula descreve uma implementação possível, não uma exigência do A121. Interfaces DDR/recursos dedicados da FPGA podem usar outra arquitetura.

O SDK XM125 configura SPI1 com modo 0, palavras de 16 bits e MSB primeiro; a configuração de clock do projeto corresponde a SCK de 40 MHz. O próprio A121 não exige que o host use exatamente esse clock.

## 6. Sequência funcional que precisa ser implementada

```text
ALIMENTAR / ENABLE / AGUARDAR
             |
       IDENTIFICAR A121
             |
  INICIALIZAR CONTROLE E IRQ
             |
   CARREGAR BASE DE CALIBRAÇÃO
             |
 EXECUTAR ETAPAS + LER RESULTADOS
       + CALCULAR CORREÇÕES
             |
 TRADUZIR CONFIGURAÇÃO DE MEDIÇÃO
             |
 ALTERAR E CARREGAR PROGRAMA/LUT
             |
       INICIAR MEDIÇÃO
             |
    AGUARDAR IRQ COM TIMEOUT
             |
 VERIFICAR EVENTO / LER BUFFER
             |
 CORRIGIR E PROCESSAR DADOS I/Q
             |
 DETECTAR SUPERFÍCIE / DISTÂNCIA
             |
    FILTRAR / ATUALIZAR SAÍDA
             |
    PRÓXIMO CICLO OU RECALIBRAR
```

**V:** este desenho especifica responsabilidades; não fornece ainda todos os valores necessários para executar cada transição.

### Correspondência com as APIs locais

O exemplo [example_service.c](../../Src/examples/getting_started/example_service.c) mostra:

1. registrar HAL e criar configuração;
2. criar processamento e reservar buffer;
3. habilitar e criar sensor;
4. chamar `acc_sensor_calibrate` até `cal_complete`, aguardando interrupção entre etapas;
5. executar `acc_sensor_prepare`;
6. executar `acc_sensor_measure`, esperar IRQ e `acc_sensor_read`;
7. executar `acc_processing_execute`;
8. recalibrar se `calibration_needed` for sinalizado.

O [example_detector_distance.c](../../Src/examples/getting_started/example_detector_distance.c) acrescenta o detector e sua própria calibração.

### Calibração não é uma constante universal

**R:** enumeração `acc_calibration_a121_state_t`, recuperada de DWARF:

| Estado | Etapa aguardada |
|---:|---|
| 0 | Ainda não iniciada |
| 1 | PLL CBANK e temperatura |
| 2 | PLL IBIAS e VFAST2 LDO |
| 3 | DELAY CBANK |
| 4 | BBA/VGA |
| 5 | AREA INDEX |
| 6 | Frequência TX |
| 7 | Frequência RX |
| 8 | Melhoria de fase |
| 9 | PULSESHAPER |
| 10 | Completa |

Os nomes acima são estados do software, não comandos SPI. As listagens mostram leitura de amostras, cálculos, alterações no programa e início de novas etapas. A estrutura interna `acc_calibration_a121_result_t` ocupa 236 bytes nesta compilação e contém, entre outros, temperatura, ajustes de osciladores/atrasos, padrões de fase e compensação I/Q.

Copiar uma calibração fixa obtida de uma unidade não demonstra funcionamento com outros sensores, temperaturas ou ciclos de alimentação.

## 7. Configuração de distância e dados recebidos

O [acc_config.h](../../Inc/acc_config.h) documenta parâmetros como:

- `start_point`, `num_points` e `step_length`;
- perfil de pulso, HWAAS e ganho do receptor;
- sweeps por frame, taxas, PRF e estados de economia;
- correção I/Q e opções por subsweep.

Esses parâmetros são a configuração da API C. O SDK os traduz em programação interna; não existe evidência de que enviar a estrutura `acc_config_t` pela SPI funcione.

O caminho identificado é:

`acc_config → acc_translation_a121_translate → parâmetros internos → patches da imagem/LUT → SPI`.

Para a medição, a estrutura interna tem 452 bytes, organizados em 226 campos de 16 bits para a rotina de patch. Uma tabela de 226 bytes associa esses campos a índices de uma tabela de 242 entradas da imagem. As correspondências estão no manifesto. A tradução que calcula os valores desses campos **ainda precisa ser reconstruída para a configuração escolhida**.

### O MISO não entrega metros prontos

O resultado público do serviço é um frame de amostras complexas I/Q, com componentes de 16 bits, acompanhado de metadados. O resultado em metros é calculado no host pelo processamento/detector.

A leitura SPI inclui cabeçalhos, latências e payload. O buffer C usado pelo SDK também contém um cabeçalho gerado pelo host, incluindo dados da calibração. Portanto, o conteúdo de `acc_sensor_read` não deve ser confundido com uma cópia simples de todos os bytes vindos do MISO.

Já foram encontrados os acessos ao buffer, bases A/B e campos de metadados. Faltam consolidar os offsets e o formato ADC para uma configuração concreta e confrontá-los com `acc_processing_execute`.

## 8. O que muda para líquidos

A referência local [ref_app_tank_level.c](../../Src/use_cases/reference_apps/ref_app_tank_level.c) usa o detector de distância, refletor `PLANAR`, seleção de picos e filtragem temporal. Isso fornece um ponto de partida mais específico do que apenas procurar a maior amostra do frame.

Presets presentes **nesta versão local**:

| Preset | Faixa nominal configurada | Ordenação dos picos | Perfil máximo | Mediana / médias |
|---|---|---|---:|---|
| Pequeno | 0,03–0,5 m | CLOSEST | 3 | 3 / 2 |
| Médio | 0,05–6 m | STRONGEST | 5 | 3 / 1 |
| Grande | 0,1–15 m | STRONGEST | 5 | 1 / 1 |

São exemplos de configuração, não garantias de alcance/precisão para o seu tanque. A aplicação expande a faixa usada pelo detector e trata condições de borda.

A documentação oficial descreve montagem no topo e cálculo do nível a partir da distância à superfície, além de filtragem por mediana e média: [Tank level reference application](https://docs.acconeer.com/en/latest/ref_apps/a121/tank_level.html). A página online pode corresponder a uma versão posterior; para reproduzir este SDK, prevalecem os valores do código local.

Definir separadamente:

- **distância d:** sensor até a superfície, que você pediu inicialmente;
- **nível h:** altura de líquido em relação ao fundo; se H é a distância sensor–fundo, `h = H - d`.

O processamento deve distinguir superfície, reflexos das paredes/fundo, ausência de detecção e saturação. Espuma, agitação, condensação e instalação física precisam entrar nos ensaios; não é possível especificar desempenho apenas pelo tipo genérico “líquido”.

## 9. Como verificar e reproduzir

No diretório raiz do projeto:

```powershell
python analysis/a121_systemverilog/tools/extract_sdk_evidence.py
python analysis/a121_systemverilog/tools/verify_evidence.py
python analysis/a121_systemverilog/tools/extract_debug_types.py
```

Os dois primeiros scripts usam só a biblioteca padrão. O terceiro usa `pyelftools==0.33`, instalado localmente em `tools/_vendor`. Para recriar essa dependência:

```powershell
python -m pip install --target analysis/a121_systemverilog/tools/_vendor pyelftools==0.33
```

Verificações realizadas:

- SHA256 dos arquivos fonte;
- equivalência entre bytes originais, palavras de 32 bits e palavras SPI de 16 bits;
- igualdade da imagem de medição em dois executáveis e da imagem de calibração em três;
- limites e tipos de 991 referências nas tabelas extraídas, contando as cópias nos diferentes executáveis;
- validade dos índices da correspondência dos 226 parâmetros de medição.

Isso verifica a extração. Não verifica eletricamente a SPI nem comprova que um controlador já consiga calibrar ou medir.

## 10. Pendências que realmente impedem um controlador completo

| Pendência | Evidência disponível | O que falta produzir |
|---|---|---|
| Sequência inicial completa de registradores | `acc_sensor_create` e `prepare_load` nas listagens | Todos os endereços, máscaras, valores e ordem, inclusive configuração fora da retenção |
| Execução da calibração | Imagem, 40 entradas da tabela, 11 estados e algoritmos parcialmente legíveis | Entradas dos subprogramas, interpretação das respostas, aritmética e valores de patch de cada etapa |
| Configuração de uma faixa/perfil | `acc_translation_a121_translate`, estrutura e tabela de correspondência | Modelo de referência executável para gerar parâmetros e LUT |
| Payload | Comando de buffer, bases A/B, tipos e metadados | Layout concreto, unidades dos offsets, formato ADC, correções e estados de erro |
| Handshake e SS | Rotinas de eventos; diferença entre guia e HAL XM125 | Trace de referência em bancada e confirmação do comportamento correto |
| Cálculo de distância | Exemplo de interpolação, detector e aplicação de tanque | Escolha e validação do algoritmo em ponto fixo |
| Dimensionamento final | Arquitetura parametrizada | Faixa de distância, taxa desejada, precisão e FPGA/clock disponíveis |

**Próximo marco recomendado:** executar no kit uma configuração fixa, capturar SPI + ENABLE + IRQ desde a partida e salvar, para o mesmo frame, payload, metadados, I/Q processado e distância do SDK. Essa comparação permite transformar os trechos recuperados em uma especificação verificável para o RTL. Uma captura fixa sozinha não substitui a calibração adaptativa.

Se a Acconeer disponibilizar a especificação interna e os fontes necessários para esse uso, eles devem substituir as inferências do binário. Até lá, este material permite avançar no projeto, mas não justifica afirmar que todas as etapas internas já foram reconstruídas.

## 11. Fontes e pontos de entrada

- Datasheet fornecido pelo usuário: `H:/Meu Drive/Faculdade/CI Digital/Projeto/A121-Datasheet.pdf`, v1.8; pinout pp. 7–9, alimentação p. 11, SPI pp. 16–17, circuito/startup pp. 18–21, integração p. 22.
- [A121 SW Integration User Guide.pdf](../../doc/A121%20SW%20Integration%20User%20Guide.pdf): seções de integração SPI, enable/disable e hibernação. A numeração impressa difere em uma página da contagem física.
- [acc_sensor.h](../../Inc/acc_sensor.h), [acc_config.h](../../Inc/acc_config.h), [acc_processing.h](../../Inc/acc_processing.h).
- [acc_hal_integration_stm32cube_xm.c](../../Src/integration/acc_hal_integration_stm32cube_xm.c).
- [example_service.list](../../out/example_service.list): identificação, SPI, calibração, tradução e processamento.
- [Distance detector](https://docs.acconeer.com/en/latest/detectors/a121/distance_detector.html): descrição oficial de filtragem, limiares e detecção de distância.


