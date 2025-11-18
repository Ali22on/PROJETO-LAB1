// FSM.v
//
module FSM (
    input CLOCK_50,
    input [1:0] KEY,
    
    // Portas do Gamepad
    input  GP_PIN1_UP_Z, input  GP_PIN2_DOWN_Y, input  GP_PIN3_LEFT_X,
    input  GP_PIN4_RIGHT_MODE, input  GP_PIN6_B_A, input  GP_PIN9_C_START,
    output GP_PIN7_SELECT,

    // Portas UART
    input GPIO_0_D,
    output GPIO_0_D_1,
    
    output [2:0] LEDR
);

    // --- Sinais Internos ---
    wire clk = CLOCK_50;
    wire rst = ~KEY[0]; 
    wire rx_pin = GPIO_0_D;
    wire tx_pin;

    // --- Sinais do UART ---
    wire rx_byte_ready;
    wire [7:0] rx_byte;
    reg  [7:0] tx_byte_para_enviar;
    reg  tx_pulso_de_envio;
    wire tx_esta_ocupado;

    // --- Sinais do Gamepad ---
    wire [11:0] gamepad_saidas;
    wire btn_up, btn_down, btn_left, btn_right, btn_a;
    // ... (registos e fios de 'posedge' do gamepad) ...
    reg btn_up_sync0, btn_up_sync1, btn_down_sync0, btn_down_sync1;
    reg btn_left_sync0, btn_left_sync1, btn_right_sync0, btn_right_sync1;
    reg btn_a_sync0, btn_a_sync1;
    wire btn_up_posedge, btn_down_posedge, btn_left_posedge, btn_right_posedge;
    wire btn_a_posedge;

    // --- Sinais da Lógica de Jogo ---
    reg [2:0] cursor_x;
    reg [2:0] cursor_y;
    
    // --- FSM Principal ---
    parameter STATE_LOAD_MAP = 0;
    parameter STATE_LOAD_HEALTH = 1;
    parameter STATE_PLAYING = 2;
    parameter STATE_CHECK_HIT = 3;
    parameter STATE_PROCESS_HIT = 4;
    parameter STATE_READ_HEALTH = 5;
    parameter STATE_WRITE_HEALTH = 6;
    parameter STATE_SUNK_SHIP = 7;
    
    reg [2:0] fsm_state;
    reg [6:0] map_addr_counter;
    reg [3:0] health_addr_counter;
    
    reg [7:0] hit_data_from_map;
    reg [3:0] hit_ship_id;
    reg [7:0] hit_health_data;
    
    // --- Sinais da RAM do Mapa (memo) ---
    wire [6:0] map_read_addr = (cursor_y << 3) | cursor_x;
    wire [7:0] map_data_out;
    wire map_write_enable;
    
    // --- Sinais da RAM de Vida (healt_memo) ---
    wire [3:0] health_read_addr = (fsm_state == STATE_READ_HEALTH) ? hit_ship_id : 4'd0;
    wire [3:0] health_write_addr = (fsm_state == STATE_WRITE_HEALTH) ? hit_ship_id : health_addr_counter;
    wire [7:0] health_data_out;
    wire [7:0] health_data_in;
    wire health_write_enable;
    
    // --- Instanciações (UART, Gamepad, 2x RAMs) ---
    
    // 1. Módulo UART
    uart_simple u_uart (
        .clk(clk), .rst(rst), .rx(rx_pin), .tx(tx_pin),
        .rx_byte_ready(rx_byte_ready), .rx_byte(rx_byte),
        .tx_data_in(tx_byte_para_enviar), .tx_start_in(tx_pulso_de_envio),
        .tx_busy_out(tx_esta_ocupado)
    );
    
    // 2. Módulo Gamepad
    gamepad_controlador u_gamepad (
        .clk(clk), .rst(rst), 
        .pin_up_z(GP_PIN1_UP_Z), .pin_down_y(GP_PIN2_DOWN_Y), .pin_left_x(GP_PIN3_LEFT_X),
        .pin_right_mode(GP_PIN4_RIGHT_MODE), .pin_b_a(GP_PIN6_B_A), .pin_c_start(GP_PIN9_C_START),
        .select_o(GP_PIN7_SELECT), .saidas(gamepad_saidas)
    );
    
    // 3. Memória do Mapa (IP do Quartus)
    memo memo_inst (
        .clock(clk),
        .wraddress({1'b0, (fsm_state == STATE_LOAD_MAP) ? map_addr_counter : map_read_addr}),
        .data((fsm_state == STATE_PROCESS_HIT) ? {1'b1, hit_data_from_map[6:0]} : rx_byte),
        .wren(map_write_enable),
        .rdaddress({1'b0, map_read_addr}),
        .q(map_data_out)
    );
    
    // 4. Memória de Vida (IP do Quartus)
    healt_memo healt_memo_inst (
        .clock(clk),
        .wraddress(health_write_addr),
        .data(health_data_in),
        .wren(health_write_enable),
        .rdaddress(health_read_addr),
        .q(health_data_out)
    );
    
    // (Lógica de Borda do Gamepad)
    always @(posedge clk) begin
        btn_up_sync0 <= btn_up; btn_up_sync1 <= btn_up_sync0;
        btn_down_sync0 <= btn_down; btn_down_sync1 <= btn_down_sync0;
        btn_left_sync0 <= btn_left; btn_left_sync1 <= btn_left_sync0;
        btn_right_sync0 <= btn_right; btn_right_sync1 <= btn_right_sync0;
        btn_a_sync0 <= btn_a; btn_a_sync1 <= btn_a_sync0;
    end
    assign btn_up_posedge = btn_up_sync0 & ~btn_up_sync1;
    assign btn_down_posedge = btn_down_sync0 & ~btn_down_sync1;
    assign btn_left_posedge = btn_left_sync0 & ~btn_left_sync1;
    assign btn_right_posedge = btn_right_sync0 & ~btn_right_sync1;
    assign btn_a_posedge = btn_a_sync0 & ~btn_a_sync1;
    
    // Mapeia o vetor de saídas
    assign btn_up = gamepad_saidas[0];
    assign btn_down = gamepad_saidas[1];
    assign btn_left = gamepad_saidas[2];
    assign btn_right = gamepad_saidas[3];
    assign btn_a = gamepad_saidas[4];

    // Lógica de "Acerto"
    assign is_hit = (map_data_out[3:0] != 4'd0);


    // --- CÉREBRO PRINCIPAL: FSM (Controlador) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state <= STATE_LOAD_MAP;
            map_addr_counter <= 6'd0;
            health_addr_counter <= 4'd0;
            tx_pulso_de_envio <= 1'b0;
            cursor_x <= 3'd0;
            cursor_y <= 3'd0;
        end else begin
            // Reseta gatilhos
            if (tx_pulso_de_envio) tx_pulso_de_envio <= 1'b0;
            
            case (fsm_state)
            
                STATE_LOAD_MAP: begin
                    if (rx_byte_ready) begin
                        map_addr_counter <= map_addr_counter + 1;
                        if (map_addr_counter == 7'd127) begin
                            fsm_state <= STATE_LOAD_HEALTH;
                        end
                    end
                end
                
                STATE_LOAD_HEALTH: begin
                    if (rx_byte_ready) begin
                        health_addr_counter <= health_addr_counter + 1;
                        if (health_addr_counter == 4'd15) begin
                            fsm_state <= STATE_PLAYING;
                        end
                    end
                end
                
                STATE_PLAYING: begin
                    // 1. Lógica de Movimento
                    if (btn_up_posedge && cursor_y > 0) cursor_y <= cursor_y - 1'b1;
                    else if (btn_down_posedge && cursor_y < 7) cursor_y <= cursor_y + 1'b1;
                    
                    if (btn_left_posedge && cursor_x > 0) cursor_x <= cursor_x - 1'b1;
                    else if (btn_right_posedge && cursor_x < 7) cursor_x <= cursor_x + 1'b1;
                    
                    // 2. Lógica de Disparo (Botão A)
                    if (btn_a_posedge) begin
                        fsm_state <= STATE_CHECK_HIT;
                    end
                    
                end
                
                STATE_CHECK_HIT: begin
                    hit_data_from_map <= map_data_out;
                    fsm_state <= STATE_PROCESS_HIT;
                end
                
                STATE_PROCESS_HIT: begin
                    hit_ship_id <= hit_data_from_map[3:0];
                    
                    if (hit_data_from_map[7]) begin // Já foi atingido?
                        tx_byte_para_enviar <= 8'h52; // 'R' (Repetido)
                        tx_pulso_de_envio <= 1'b1;
                        fsm_state <= STATE_PLAYING;
                        
                    end else begin
                        // Tiro novo!
                        if (hit_data_from_map[3:0] == 4'd0) begin // Água?
                            tx_byte_para_enviar <= 8'h4D; // 'M' (Miss)
                            tx_pulso_de_envio <= 1'b1;
                            fsm_state <= STATE_PLAYING;
                        
                        end else begin // Acertou um Navio!
                            tx_byte_para_enviar <= 8'h48; // 'H' (Hit)
                            tx_pulso_de_envio <= 1'b1;
                            fsm_state <= STATE_READ_HEALTH;
                        end
                    end
                end
                
                STATE_READ_HEALTH: begin
                    hit_health_data <= health_data_out;
                    fsm_state <= STATE_WRITE_HEALTH;
                end
                
                STATE_WRITE_HEALTH: begin
                    if ((hit_health_data - 1) == 8'd0) begin
                        fsm_state <= STATE_SUNK_SHIP;
                    end else begin
                        fsm_state <= STATE_PLAYING;
                    end
                end
                
                STATE_SUNK_SHIP: begin
                    tx_byte_para_enviar <= 8'h53; // 'S' (Sunk)
                    tx_pulso_de_envio <= 1'b1;
                    fsm_state <= STATE_PLAYING;
                end
                
            endcase
        end
    end
    
    // --- Processo 2: Lógica Combinacional (Saídas/Atribuições) ---
    assign map_write_enable = (fsm_state == STATE_LOAD_MAP && rx_byte_ready) ||
                              (fsm_state == STATE_PROCESS_HIT && !hit_data_from_map[7] && map_data_out[3:0] != 4'd0); // Escreve o "Hit Flag"

    assign health_write_enable = (fsm_state == STATE_LOAD_HEALTH && rx_byte_ready) ||
                                 (fsm_state == STATE_WRITE_HEALTH);
    
    assign health_data_in = (fsm_state == STATE_LOAD_HEALTH) ? rx_byte : (hit_health_data - 1);

    // Saídas Físicas
    assign GPIO_0_D_1 = tx_pin;
    assign LEDR[0] = (fsm_state == STATE_LOAD_MAP || fsm_state == STATE_LOAD_HEALTH);
    assign LEDR[1] = (fsm_state == STATE_PLAYING);
    assign LEDR[2] = (fsm_state == STATE_SUNK_SHIP);
    
endmodule