`timescale 1ns / 1ps

module testbench_memoria_ip;

    // --- Parâmetros ---
    localparam CLK_PERIOD = 20;   // 50MHz
    localparam BIT_PERIOD = 8680; // 115200 Baud

    // --- Sinais do UUT ---
    reg  CLOCK_50;
    reg  [1:0] KEY;
    reg  v_sync_in; 
    reg  GPIO_0_D; // UART RX
    
    // Pinos do Gamepad
    reg  GP_PIN1_UP_Z, GP_PIN2_DOWN_Y, GP_PIN3_LEFT_X;
    reg  GP_PIN4_RIGHT_MODE, GP_PIN6_B_A, GP_PIN9_C_START;

    // Saídas
    wire GPIO_0_D_1;
    wire [2:0] LEDR;
    wire GP_PIN7_SELECT; 

    // --- Debug ---
    wire [2:0] fsm_state = uut.fsm_state;
    wire [2:0] cursor_x  = uut.cursor_x;
    wire [2:0] cursor_y  = uut.cursor_y;
    wire tx_pin          = uut.tx_pin;

    // --- Instanciação ---
    FSM uut (
        .CLOCK_50(CLOCK_50), .KEY(KEY), .v_sync_in(v_sync_in),
        .GP_PIN1_UP_Z(GP_PIN1_UP_Z), .GP_PIN2_DOWN_Y(GP_PIN2_DOWN_Y), 
        .GP_PIN3_LEFT_X(GP_PIN3_LEFT_X), .GP_PIN4_RIGHT_MODE(GP_PIN4_RIGHT_MODE), 
        .GP_PIN6_B_A(GP_PIN6_B_A), .GP_PIN9_C_START(GP_PIN9_C_START), 
        .GP_PIN7_SELECT(GP_PIN7_SELECT),
        .GPIO_0_D(GPIO_0_D), .GPIO_0_D_1(GPIO_0_D_1), .LEDR(LEDR)
    );

    // --- Clock ---
    initial begin CLOCK_50=0; forever #(CLK_PERIOD/2) CLOCK_50=~CLOCK_50; end
    
   // --- TAREFAS AUXILIARES (Modo "Force") ---

    // Envia dados do PC para FPGA
    task uart_send_byte;
        input [7:0] byte_to_send;
        integer i;
    begin
        GPIO_0_D <= 1'b0; #(BIT_PERIOD); // Start
        for (i = 0; i < 8; i = i + 1) begin
            GPIO_0_D <= byte_to_send[i]; #(BIT_PERIOD);
        end
        GPIO_0_D <= 1'b1; #(BIT_PERIOD); // Stop
        GPIO_0_D <= 1'b1; #(BIT_PERIOD); // Idle
    end
    endtask

    // Recebe resposta do FPGA (com timeout simples)
    task uart_receive_byte;
        output [7:0] byte_received;
        reg [7:0] byte_reg;
        integer j;
    begin
        // Bloco nomeado para permitir disable
        begin : rx_block
            fork
                // 1. Tenta receber
                begin
                    @(negedge tx_pin);
                    #(BIT_PERIOD / 2);
                    for (j = 0; j < 8; j = j + 1) begin
                        #(BIT_PERIOD); byte_reg[j] = tx_pin;
                    end
                    #(BIT_PERIOD); 
                    byte_received = byte_reg;
                    disable rx_block; // Sucesso
                end
                // 2. Timeout se demorar muito
                begin
                    #(BIT_PERIOD * 20);
                    disable rx_block; // Falha/Timeout
                end
            join
        end
    end
    endtask

    // --- SEQUÊNCIA PRINCIPAL COM "FORCE" ---
    initial begin : teste_memoria_force
        integer k;
        reg [7:0] resposta;

        $display("--- INICIANDO TESTE COM FORCE (IGNORANDO GAMEPAD) ---");
        
        // 1. Inicialização Segura
        GPIO_0_D <= 1'b1; KEY <= 2'b11; v_sync_in <= 1'b0;
        GP_PIN1_UP_Z <= 1'b1; GP_PIN2_DOWN_Y <= 1'b1; GP_PIN3_LEFT_X <= 1'b1;
        // (Os pinos do gamepad não importam aqui, mas deixamos em 1)
        
        // Reset
        KEY[0] <= 1'b0; #(CLK_PERIOD * 10); KEY[0] <= 1'b1; #(CLK_PERIOD * 10);

        // ------------------------------------------------------------
        // FASE 1: CARREGAR MAPA (128 BYTES)
        // Navios em: 2, 4, 6, 8, 10 (Linear) -> Como Y=0, X=2,4,6...
        // ------------------------------------------------------------
        $display("[%0t ns] Carregando Mapa (128 bytes)...", $time);
        
        for (k = 0; k < 128; k = k + 1) begin
            if (k == 2 || k == 4 || k == 6 || k == 8 || k == 10)
                uart_send_byte(8'h01); // Navio
            else
                uart_send_byte(8'h00); // Água
        end
        
        // ------------------------------------------------------------
        // FASE 2: CARREGAR VIDA (16 BYTES)
        // ------------------------------------------------------------
        $display("[%0t ns] Carregando Vida...", $time);
        for (k = 0; k < 16; k = k + 1) uart_send_byte(8'h03);

        #(BIT_PERIOD * 10); // Espera processar

        // Verifica se entrou em jogo
        if (fsm_state == uut.STATE_PLAYING) 
            $display(">>> [OK] FSM entrou em PLAYING.");
        else begin
            $display(">>> [FALHA] FSM presa no estado %d. Verifique o contador (128 bytes)!", fsm_state);
            $stop;
        end

        // ------------------------------------------------------------
        // FASE 3: - TIRO NO NAVIO DA POSIÇÃO 2
        // Vamos forçar as variáveis internas da FSM
        // ------------------------------------------------------------
        
        $display("--- TESTE 1: Forcando Cursor para (2,0) e Disparando ---");

        // 1. Força as coordenadas X e Y (ignorando botões de movimento)
        force uut.cursor_x = 3'd2;
        force uut.cursor_y = 3'd0;
        #(CLK_PERIOD * 5); // Espera estabilizar

        if (cursor_x == 2 && cursor_y == 0) $display("   -> Cursor forçado com sucesso para (2,0).");

        // 2. Força o pulso de tiro (Simula btn_a_posedge)
        $display("   -> Injetando sinal de disparo (btn_a_posedge)...");
        force uut.btn_a_posedge = 1'b1;
        #(CLK_PERIOD * 2); // Mantém por 2 clocks para a FSM pegar
        force uut.btn_a_posedge = 1'b0;
        
        // 3. Verifica a resposta da UART
        uart_receive_byte(resposta);

        if (resposta == 8'h48) // 'H'
            $display(">>> SUCESSO: Acertou Navio! (Recebeu 'H')");
        else if (resposta == 8'h4D) 
            $display(">>> ERRO: Deu Agua (Miss). Memoria nao gravou ou leu errado.");
        else
            $display(">>> ERRO: Resposta inesperada: 0x%h", resposta);


        // ------------------------------------------------------------
        // FASE 4: - TIRO REPETIDO (WRITE-BACK)
        // Dispara de novo no mesmo lugar para ver se virou 'R'
        // ------------------------------------------------------------
        #(CLK_PERIOD * 100); // Pequena pausa
        $display("--- TESTE 2: Disparando novamente em (2,0) ---");

        // Pulso de tiro novamente
        force uut.btn_a_posedge = 1'b1;
        #(CLK_PERIOD * 2);
        force uut.btn_a_posedge = 1'b0;

        uart_receive_byte(resposta);

        if (resposta == 8'h52) // 'R'
            $display(">>> SUCESSO: Detectou tiro repetido! (Recebeu 'R') - Escrita na RAM OK.");
        else
            $display(">>> ERRO: Nao detectou repeticao. Recebeu: 0x%h", resposta);

        // ------------------------------------------------------------
        // LIMPEZA
        // Solta as variaveis para o sistema voltar ao normal (se quisesse continuar)
        release uut.cursor_x;
        release uut.cursor_y;
        release uut.btn_a_posedge;

        $display("--- FIM DO TESTE ---");
        $stop;
    end
endmodule