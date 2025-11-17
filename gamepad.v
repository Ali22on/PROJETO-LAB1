// gamepad_controlador.v
// *** MODIFICADO PARA REMOVER O V_SYNC ***
// Agora corre num loop contínuo.

module gamepad_controlador (
    input clk,          // Clock de 50MHz
    input rst,

    // --- (REMOVIDO: input v_sync) ---

    // --- Entradas do Conector DB9 (Ativo-Baixo) ---
    input pin_up_z,     // Pino 1
    input pin_down_y,   // Pino 2
    input pin_left_x,   // Pino 3
    input pin_right_mode, // Pino 4
    input pin_b_a,      // Pino 6
    input pin_c_start,  // Pino 9
    
    // --- Saída para o Conector DB9 ---
    output reg select_o,  // Pino 7

    // --- Saídas de Botões (Agrupadas em um vetor) ---
    output reg [11:0] saidas // (Ativo-Alto: 1 = pressionado)
);

    // --- Definições dos Estados da FSM (Sem S_AGUARDAR_ATIVACAO) ---
    parameter   S_ESTADO_0 = 1,
                S_ESTADO_1 = 2, S_ESTADO_2 = 3, S_ESTADO_3 = 4,
                S_ESTADO_4 = 5, S_ESTADO_5 = 6, S_ESTADO_6 = 7,
                S_ESTADO_7 = 8;
    
    reg [3:0] estado_atual, estado_futuro;

    // --- (REMOVIDO: Lógica da Flag v_sync) ---

    // --- Contador de Tempo (para os 20µs) ---
    reg [12:0] contador;
    localparam COUNT_1000 = 13'd1000, COUNT_2000 = 13'd2000,
               COUNT_3000 = 13'd3000, COUNT_4000 = 13'd4000,
               COUNT_5000 = 13'd5000, COUNT_6000 = 13'd6000,
               COUNT_7000 = 13'd7000, COUNT_8000 = 13'd8000;


    // --- Processo 1: Bloco Sequencial (Registos) ---
    always @(posedge clk) begin
        if (rst) begin
            estado_atual <= S_ESTADO_0; // Começa direto no ESTADO_0
            contador <= 13'd0;
            saidas <= 12'd0;
        end else begin
            estado_atual <= estado_futuro;
            
            // O contador reinicia no fim do ciclo
            if (estado_futuro == S_ESTADO_0 && estado_atual == S_ESTADO_7) begin
                contador <= 13'd0;
            end else begin
                contador <= contador + 1'b1;
            end
            
            // Amostragem dos botões
            if (estado_futuro == S_ESTADO_1) begin 
                saidas[4] <= ~pin_b_a;     // Saida_A
                saidas[10] <= ~pin_c_start; // Saida_Start
            end
            if (estado_futuro == S_ESTADO_2) begin
                saidas[0] <= ~pin_up_z;    // Saida_Up
                saidas[1] <= ~pin_down_y;  // Saida_Down
                saidas[2] <= ~pin_left_x;  // Saida_Left
                saidas[3] <= ~pin_right_mode; // Saida_Right
            end
            if (estado_futuro == S_ESTADO_4) begin
                saidas[5] <= ~pin_b_a;     // Saida_B
                saidas[6] <= ~pin_c_start; // Saida_C
            end
            if (estado_futuro == S_ESTADO_6) begin
                saidas[7] <= ~pin_left_x;   // Saida_X (Pino 3)
                saidas[8] <= ~pin_down_y;   // Saida_Y (Pino 2)
                saidas[9] <= ~pin_up_z;     // Saida_Z (Pino 1)
                saidas[11] <= ~pin_right_mode; // Saida_Mode (Pino 4)
            end
        end
    end

    // --- Processo 2: Bloco Combinacional (Lógica de Próximo Estado) ---
    always @(*) begin
        case (estado_atual)
            // (S_AGUARDAR_ATIVACAO removido)
            S_ESTADO_0:
                if (contador < COUNT_1000) estado_futuro = S_ESTADO_0;
                else estado_futuro = S_ESTADO_1;
            S_ESTADO_1:
                if (contador < COUNT_2000) estado_futuro = S_ESTADO_1;
                else estado_futuro = S_ESTADO_2;
            S_ESTADO_2:
                if (contador < COUNT_3000) estado_futuro = S_ESTADO_2;
                else estado_futuro = S_ESTADO_3;
            S_ESTADO_3:
                if (contador < COUNT_4000) estado_futuro = S_ESTADO_3;
                else estado_futuro = S_ESTADO_4;
            S_ESTADO_4:
                if (contador < COUNT_5000) estado_futuro = S_ESTADO_4;
                else estado_futuro = S_ESTADO_5;
            S_ESTADO_5:
                if (contador < COUNT_6000) estado_futuro = S_ESTADO_5;
                else estado_futuro = S_ESTADO_6;
            S_ESTADO_6:
                if (contador < COUNT_7000) estado_futuro = S_ESTADO_6;
                else estado_futuro = S_ESTADO_7;
            S_ESTADO_7:
                if (contador < COUNT_8000) estado_futuro = S_ESTADO_7;
                else estado_futuro = S_ESTADO_0; // Volta ao início do loop
            default: estado_futuro = S_ESTADO_0;
        endcase
    end
    
    // --- Processo 3: Bloco Combinacional (Saída 'Select') ---
    always @(*) begin
        select_o = 1'b1; // Valor padrão
        case (estado_atual)
            S_ESTADO_1: select_o = 1'b0;
            S_ESTADO_3: select_o = 1'b0;
            S_ESTADO_5: select_o = 1'b0;
            S_ESTADO_7: select_o = 1'b0;
            default:    select_o = 1'b1;
        endcase
    end

endmodule