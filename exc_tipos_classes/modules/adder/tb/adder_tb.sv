class adder_test #(
    parameter int WIDTH     = 8,
    parameter int FRAC_BITS = 4 // Número de bits da parte fracionária do ponto fixo
);

    // Quatro atributos exigidos pelo exercício
    rand logic signed [WIDTH-1:0] a; // Declaração de a como rand para randomização automática
    rand logic signed [WIDTH-1:0] b;

    logic signed [WIDTH-1:0] expected_sum;
    logic                    expected_overflow;

    // Limites brutos do formato signed
    localparam logic signed [WIDTH-1:0] MAX_VALUE = { 
        1'b0,
        {(WIDTH-1){1'b1}}
    }; // Valor máximo para WIDTH bits signed (2^(WIDTH-1) - 1)

    localparam logic signed [WIDTH-1:0] MIN_VALUE = {
        1'b1,
        {(WIDTH-1){1'b0}}
    }; // Valor mínimo para WIDTH bits signed (-2^(WIDTH-1))

    // Limites numéricos usados no cálculo intermediário
    localparam longint signed MAX_CALC =
        (64'sd1 <<< (WIDTH-1)) - 1;

    localparam longint signed MIN_CALC =
        -(64'sd1 <<< (WIDTH-1));

    // Escala do ponto fixo
    localparam int SCALE = 1 << FRAC_BITS; // Escala do ponto fixo 1/(2^FRAC_BITS)


    // Construtor
    function new(); // Já chama o reset_values() para inicializar os atributos
        reset_values();
    endfunction


    // Função de reset da classe
    function void reset_values();

        a                 = '0;
        b                 = '0;
        expected_sum      = '0;
        expected_overflow = 1'b0;

    endfunction


    // Calcula o resultado de referência com saturação
    function void calculate_expected();

        longint signed full_result;

        full_result = $signed(a) + $signed(b);

        if (full_result > MAX_CALC) begin

            expected_sum      = MAX_VALUE; // Trunca no valor máximo (2^(WIDTH-1) - 1)
            expected_overflow = 1'b1;

        end
        else if (full_result < MIN_CALC) begin

            expected_sum      = MIN_VALUE; // Trunca no valor mínimo (-2^(WIDTH-1))
            expected_overflow = 1'b1;

        end
        else begin

            expected_sum      = full_result;
            expected_overflow = 1'b0;

        end

    endfunction

    // Funções auxiliares para obter os valores mínimo e máximo em ponto fixo

    // Converte a representação bruta para valor real
    function real fixed_to_real(
        input logic signed [WIDTH-1:0] value
    );

        return $itor($signed(value)) / SCALE; // Divide pelo fator de escala para obter o valor real

    endfunction

    function automatic logic signed [WIDTH-1:0] get_min_value();
        return MIN_VALUE;
    endfunction

    function automatic logic signed [WIDTH-1:0] get_max_value();
        return MAX_VALUE;
    endfunction

    function automatic real get_min_real();
        return $itor(MIN_CALC) / SCALE;
    endfunction

    function automatic real get_max_real();
        return $itor(MAX_CALC) / SCALE;
    endfunction



    // Gera, aplica e verifica 100 valores aleatórios
    task automatic generate_100_values(
        ref logic                          clk,

        ref logic signed [WIDTH-1:0]       dut_a,
        ref logic signed [WIDTH-1:0]       dut_b,
        ref logic signed [WIDTH-1:0]       dut_sum,
        ref logic                          dut_overflow,

        ref logic signed [WIDTH-1:0]       expected_sum_wave,
        ref logic                          expected_overflow_wave
    );

        int error_count;

        error_count = 0;

        for (int test_number = 1;
             test_number <= 100;
             test_number++) begin

            /*
             * Randomiza os atributos marcados como rand:
             *   a
             *   b
             */
            if (!this.randomize()) begin
                $fatal(
                    1,
                    "Falha na randomizacao do teste %0d",
                    test_number
                ); // Se a randomização falhar, encerra a simulação com erro
            end

            // Calcula o resultado esperado
            calculate_expected();

            /*
             * Aplica os estímulos na borda de descida.
             * Assim, ficam estáveis até a próxima borda de subida.
             */
            @(negedge clk);

            dut_a = this.a;
            dut_b = this.b;

            // Espelha o valor esperado para a waveform
            expected_sum_wave      = expected_sum;
            expected_overflow_wave = expected_overflow;

            /*
             * Aguarda a borda de subida para verificar.
             * Como o DUT é combinacional, houve meio período
             * de clock para o resultado estabilizar.
             */
            @(posedge clk);

            if (
                (dut_sum      !== expected_sum) ||
                (dut_overflow !== expected_overflow)
            ) begin

                error_count++;

                $error(
                    {
                        "TESTE %0d: FAIL\n",
                        "  A             = %0.4f (raw=%0d)\n",
                        "  B             = %0.4f (raw=%0d)\n",
                        "  SUM esperado  = %0.4f (raw=%0d)\n",
                        "  SUM DUT       = %0.4f (raw=%0d)\n",
                        "  OVF esperado  = %0b\n",
                        "  OVF DUT       = %0b"
                    },
                    test_number,

                    fixed_to_real(this.a),
                    $signed(this.a),

                    fixed_to_real(this.b),
                    $signed(this.b),

                    fixed_to_real(expected_sum),
                    $signed(expected_sum),

                    fixed_to_real(dut_sum),
                    $signed(dut_sum),

                    expected_overflow,
                    dut_overflow
                );

            end
            else begin

                $display(
                    "TESTE %0d: PASS | A=%0.4f (%0d) | B=%0.4f (%0d) | SUM=%0.4f (%0d) | OVF=%0b",
                    test_number,

                    fixed_to_real(this.a),
                    $signed(this.a),

                    fixed_to_real(this.b),
                    $signed(this.b),

                    fixed_to_real(dut_sum),
                    $signed(dut_sum),

                    dut_overflow
                );

            end

        end

        $display("");
        $display("======================================");

        if (error_count == 0) begin

            $display("RESULTADO: TODOS OS TESTES PASSARAM");
            $display("Testes executados: 100");
            $display("Erros encontrados: 0");

        end
        else begin

            $display("RESULTADO: TESTE REPROVADO");
            $display("Testes executados: 100");
            $display("Erros encontrados: %0d", error_count);

        end

        $display("======================================");

    endtask

endclass

module adder_tb;

    timeunit      1ns;
    timeprecision 1ps;

    localparam int WIDTH     = 8;
    localparam int FRAC_BITS = 4; // Especifica o número de bits da parte fracionária do ponto fixo

    logic clk;

    logic signed [WIDTH-1:0] a; // Entradas do dut continua como vetor de bits inteiros
    logic signed [WIDTH-1:0] b;
    logic signed [WIDTH-1:0] sum;

    logic overflow;

    /*
     * Sinais auxiliares para visualização na waveform.
     * Eles mostram o resultado esperado pelo testbench.
     */
    logic signed [WIDTH-1:0] expected_sum_wave;
    logic                    expected_overflow_wave;


    // DUT
    adder #(
        .WIDTH(WIDTH)
    ) dut (
        .a        (a),
        .b        (b),
        .sum      (sum),
        .overflow (overflow)
    );


    // Handle da classe parametrizada
    adder_test #(
        .WIDTH     (WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) test;


    // Clock com período de 10 ns
    initial begin

        clk = 1'b0;

        forever begin
            #5ns clk = ~clk;
        end

    end


    // Processo principal do teste
    initial begin

        // Cria o objeto
        test = new();

        /*
         * O construtor já chama reset_values().
         * Portanto, não seria obrigatório chamá-la novamente.
         */
        test.reset_values();

        // Inicialização dos sinais do módulo
        a                      = '0;
        b                      = '0;
        expected_sum_wave      = '0;
        expected_overflow_wave = 1'b0;

        $display("");
        $display("==============================================");
        $display("         TESTBENCH DO SOMADOR TRUNCADO");
        $display("==============================================");
        $display("Largura total       : %0d bits", WIDTH);
        $display("Bits fracionarios   : %0d bits", FRAC_BITS);
        $display("Escala              : %0d", 1 << FRAC_BITS);

        $display(
            "Valor minimo        : %0.4f (raw = %0d)",
            test.get_min_real(),
            $signed(test.get_min_value())
        );

        $display(
            "Valor maximo        : %0.4f (raw = %0d)",
            test.get_max_real(),
            $signed(test.get_max_value())
        );

        $display("Quantidade de testes: 100");
        $display("==============================================");
        $display("");

        /*
         * Desconsidera o início da simulação.
         * Nenhuma verificação é realizada nos dois
         * primeiros ciclos.
         */
        repeat (2) begin
            @(posedge clk);
        end

        // Executa os 100 testes
        test.generate_100_values(
            clk,

            a,
            b,
            sum,
            overflow,

            expected_sum_wave,
            expected_overflow_wave
        );

        $finish;

    end

endmodule