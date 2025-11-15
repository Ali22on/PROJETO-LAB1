
module top_level_uart_test (
    // Entradas Globais da Placa
    input CLOCK_50,     // Clock de 50MHz da placa
    input [1:0] KEY,    // KEY[0] (reset) e KEY[1] (envio)

    // Pinos da Comunicação Serial (para o conversor)
    input GPIO_0_D,     // RX (Pino 1 do JP5)
    output GPIO_0_D_1,   // TX (Pino 2 do JP5)

    // Saídas de Debug (para ver o resultado)
    output [1:0] LEDR   // 2 LEDs vermelhos da placa
);

    // --- Sinais Internos ---
    wire clk = CLOCK_50;
    // O botão KEY é "ativo em baixo" (0 quando pressionado).
    // O módulo uart_simple espera um reset "ativo em alto" (1 para resetar).
    wire rst = ~KEY[0]; 

    wire rx_pin = GPIO_0_D; // Sinal vindo do pino RX
    wire tx_pin;          // Sinal indo para o pino TX

    // Sinais da lógica de Recepção (RX)
    wire cmd_ready;       // Sinaliza que um comando foi recebido
    reg led_cmd_ok;

    // Sinais da lógica de Transmissão (TX)
    reg [7:0] tx_byte_para_enviar;
    reg tx_pulso_de_envio;
    wire tx_esta_ocupado;
    wire tx_key_pressed = ~KEY[1]; // Botão KEY[1] pressionado (ativo em 0)
    reg tx_key_sync0;
    reg tx_key_sync1;
    wire tx_key_posedge; // Pulso de 1 ciclo ao pressionar o botão

    // --- Instanciação do seu módulo UART ---
    uart_simple u_uart (
        .clk(clk),
        .rst(rst),
        .rx(rx_pin),        // Conecta à entrada do pino GPIO
        .tx(tx_pin),        // Conecta à saída do pino GPIO
        
        .cmd_ready(cmd_ready),

        // Conexões para a lógica de Transmissão (TX)
        .tx_data_in(tx_byte_para_enviar),
        .tx_start_in(tx_pulso_de_envio),
        .tx_busy_out(tx_esta_ocupado)
    );

   
// --- Lógica de Validação Visual (Parser RX com TOGGLE/INVERSÃO) ---
// Esta lógica INVERTE o LED a cada 'P' recebido
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Começa apagado
        led_cmd_ok <= 1'b0; 
    end else if (cmd_ready) begin
        // SE o 'P' for detetado (pelo pulso cmd_ready)...
        // ...INVERTE O ESTADO ATUAL DO LED!
        led_cmd_ok <= ~led_cmd_ok; 
    end
    // (Se cmd_ready for 0, o LED mantém o seu valor)
end

    // --- Lógica de Envio (TX) ao Apertar KEY[1] ---
    
    
    // 1. Filtro de "debounce"
    always @(posedge clk) begin
        tx_key_sync0 <= tx_key_pressed;
        tx_key_sync1 <= tx_key_sync0;
    end
    assign tx_key_posedge = tx_key_sync0 & ~tx_key_sync1;

    // 2. Lógica principal de envio
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_byte_para_enviar <= 8'h00;
            tx_pulso_de_envio <= 1'b0;
        end else begin
            if (tx_pulso_de_envio) begin
                tx_pulso_de_envio <= 1'b0;
            end

            if (tx_key_posedge && !tx_esta_ocupado) begin
                tx_byte_para_enviar <= 8'h53; // 'S'
                tx_pulso_de_envio <= 1'b1;
            end
        end
    end

    // --- Atribuição das Saídas Físicas ---
    assign GPIO_0_D_1 = tx_pin;
    
    // Mapeamento dos LEDs (agora só o LEDR[9] importa para o RX)
    assign LEDR[1] = led_cmd_ok;
    assign LEDR[0] = 1'b0; 

endmodule
