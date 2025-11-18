// gamepad_controlador.v
// Inclui sincronização v_sync e FSM de 2 processos.

module gamepad_controlador (
    input clk,          // Clock de 50MHz
    input rst,
    input v_sync,       // Sinal de Sincronização Vertical (do controlador VGA)

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
    // (Ativo-Alto: 1 = pressionado)
    output reg [11:0] saidas
    // saidas[0] = Up, [1]=Down, [2]=Left, [3]=Right
    // saidas[4] = A,  [5]=B,    [6]=C,    [10]=Start
    // saidas[7] = X,  [8]=Y,    [9]=Z,    [11]=Mode
);

    // --- Definições dos Estados da FSM ---
    parameter   S_AGUARDAR_ATIVACAO = 0,
                S_ESTADO_0 = 1,
                S_ESTADO_1 = 2,
                S_ESTADO_2 = 3,
                S_ESTADO_3 = 4,
                S_ESTADO_4 = 5,
                S_ESTADO_5 = 6,
                S_ESTADO_6 = 7,
                S_ESTADO_7 = 8;
    
    reg [3:0] estado_atual, estado_futuro;

    // --- Lógica de Sincronização v_sync ---
    // Detecta a borda de descida do v_sync para gerar um pulso 'Flag'
    reg v_sync_d0, v_sync_d1;
    wire flag_v_sync;
    
    always @(posedge clk) begin
        v_sync_d0 <= v_sync;
        v_sync_d1 <= v_sync_d0;
    end
    
    // Flag é '1' por um ciclo de clock na borda de descida de v_sync
    assign flag_v_sync = v_sync_d1 && !v_sync_d0;

    // --- Contador de Tempo (para os 20µs) ---
    reg [12:0] contador;
    localparam COUNT_1000 = 13'd1000; // 1000 * 20ns = 20µs
    localparam COUNT_2000 = 13'd2000;
    localparam COUNT_3000 = 13'd3000;
    localparam COUNT_4000 = 13'd4000;
    localparam COUNT_5000 = 13'd5000;
    localparam COUNT_6000 = 13'd6000;
    localparam COUNT_7000 = 13'd7000;
    localparam COUNT_8000 = 13'd8000;


    // --- Processo 1: Bloco Sequencial (Registos) ---
    // Atualiza o estado atual e os registos de saída
    always @(posedge clk) begin
        if (rst) begin
            estado_atual <= S_AGUARDAR_ATIVACAO;
            contador <= 13'd0;
            saidas <= 12'd0; // Zera todas as saídas
        end else begin
            estado_atual <= estado_futuro;
            
            // O contador avança em todos os estados, exceto AGUARDAR
            if (estado_futuro == S_AGUARDAR_ATIVACAO) begin
                contador <= 13'd0;
            end else begin
                contador <= contador + 1'b1;
            end
            
            // A amostragem (leitura) dos botões é feita aqui
            
            // Lê A, Start
            if (estado_futuro == S_ESTADO_1) begin 
                saidas[4] <= ~pin_b_a;     // Saida_A
                saidas[10] <= ~pin_c_start; // Saida_Start
            end
            
            // Lê D-Pad
            if (estado_futuro == S_ESTADO_2) begin
                saidas[0] <= ~pin_up_z;    // Saida_Up
                saidas[1] <= ~pin_down_y;  // Saida_Down
                saidas[2] <= ~pin_left_x;  // Saida_Left
                saidas[3] <= ~pin_right_mode; // Saida_Right
            end
            
            // Lê B, C
            if (estado_futuro == S_ESTADO_4) begin
                saidas[5] <= ~pin_b_a;     // Saida_B
                saidas[6] <= ~pin_c_start; // Saida_C
            end
            
            // Lê X, Y, Z, Mode
            // (Baseado na sua FSM: X=Pino3, Y=Pino2, Z=Pino1)
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
            S_AGUARDAR_ATIVACAO: begin
                if (flag_v_sync) begin
                    estado_futuro = S_ESTADO_0;
                end else begin
                    estado_futuro = S_AGUARDAR_ATIVACAO;
                end
            end
            S_ESTADO_0: begin
                if (contador < COUNT_1000) estado_futuro = S_ESTADO_0;
                else estado_futuro = S_ESTADO_1;
            end
            S_ESTADO_1: begin
                if (contador < COUNT_2000) estado_futuro = S_ESTADO_1;
                else estado_futuro = S_ESTADO_2;
            end
            S_ESTADO_2: begin
                if (contador < COUNT_3000) estado_futuro = S_ESTADO_2;
                else estado_futuro = S_ESTADO_3;
            end
            S_ESTADO_3: begin
                if (contador < COUNT_4000) estado_futuro = S_ESTADO_3;
                else estado_futuro = S_ESTADO_4;
            end
            S_ESTADO_4: begin
                if (contador < COUNT_5000) estado_futuro = S_ESTADO_4;
                else estado_futuro = S_ESTADO_5;
            end
            S_ESTADO_5: begin
                if (contador < COUNT_6000) estado_futuro = S_ESTADO_5;
                else estado_futuro = S_ESTADO_6;
            end
            S_ESTADO_6: begin
                if (contador < COUNT_7000) estado_futuro = S_ESTADO_6;
                else estado_futuro = S_ESTADO_7;
            end
            S_ESTADO_7: begin
                if (contador < COUNT_8000) estado_futuro = S_ESTADO_7;
                else estado_futuro = S_AGUARDAR_ATIVACAO; // Volta ao início
            end
            default: estado_futuro = S_AGUARDAR_ATIVACAO;
        endcase
    end
    
    // --- Processo 3: Bloco Combinacional (Lógica de Saída 'Select') ---
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