module ControladorPrincipalBN (
    input clock,
    input reset,
    input Start,    
    input [11:0] Gamepad,
    input tx_busy,
    output reg [7:0] DataMemoTX,
    output reg WEnableTX,
    output reg [8:0] AddrMemoTX,        
    output reg clkMemoTX,
    output reg tx_start,
    input [7:0] rx_data,
    input rx_ready
);

    parameter   Zera_Timer = 0,
                Aguarda_Start = 1,
                
                // SETUP
                RX_Wait_Soltar = 2, RX_Aguarda = 3, RX_Grava = 4, Setup_Fim = 5,
                
                // RENDER
                Inicializa_TX = 10,
                Escreve_Header_1 = 11, Escreve_Header_2 = 12,
                Carrega_Mapas = 13, Escreve_Mapa_Byte = 14, Atualiza_Loop = 15,
                Escreve_Score_P1 = 16, Escreve_Score_P2 = 17,
                Escreve_Cur_P1 = 18, Escreve_Cur_P2 = 19,
                
                // UART
                TX_Inicio = 30, TX_Check = 31, TX_Send = 32, TX_Wait = 33,
                
                // JOGO
                Aguardar_Gamepad = 40, Movimentar_Cursor = 41, Atirar = 42, Verificar_Dano = 43, 
                Fim_de_Jogo = 99;

    reg [6:0] estado_atual, estado_futuro; 
    reg FlagTerminoTransmissao;

    reg [7:0] MapaOponente [0:63]; 
    reg [7:0] MapaJogador  [0:63]; 

    reg [7:0] PlacarP1, PlacarP2;
    reg signed [7:0] Cursor_P1_X, Cursor_P1_Y; 
    reg signed [7:0] Cursor_P2_X, Cursor_P2_Y; 
    
    reg VezDoJogador; 
    reg [7:0] ID_Atingido;

    // Vidas P2 (Alvos do P1)
    reg [2:0] Vida_P2_Porta, Vida_P2_Encour;
    reg [2:0] Vida_P2_Hidro1, Vida_P2_Hidro2, Vida_P2_Cruz1, Vida_P2_Cruz2;
    
    // Vidas P1 (Alvos do P2)
    reg [2:0] Vida_P1_Porta, Vida_P1_Encour;
    reg [2:0] Vida_P1_Hidro1, Vida_P1_Hidro2, Vida_P1_Cruz1, Vida_P1_Cruz2;

    reg [7:0] Indice;
    integer i, k;
    reg [9:0] Addr;   

    always @ (posedge clock) begin
        if (reset) begin
            estado_atual <= Zera_Timer;
            Cursor_P1_X <= 3; Cursor_P1_Y <= 3; Cursor_P2_X <= 4; Cursor_P2_Y <= 4;
            PlacarP1 <= 0; PlacarP2 <= 0; VezDoJogador <= 0;
            i <= 0; Indice <= 0;
        end
        else begin
            estado_atual <= estado_futuro;

            // RX GRAVAÇÃO
            if (estado_futuro == RX_Grava) begin
                if (Indice >= 2 && Indice < 66) MapaOponente[Indice - 2] <= rx_data;
                else if (Indice >= 66 && Indice < 130) MapaJogador[Indice - 66] <= rx_data;
                Indice <= Indice + 1;
            end

            // INICIALIZAÇÃO DE VIDAS (IDS NOVOS)
            if (estado_futuro == Setup_Fim) begin
                // ID 6: Porta-Aviões (Tam 5)
                Vida_P2_Porta<=5; Vida_P1_Porta<=5;
                // ID 7: Encouraçado (Tam 4)
                Vida_P2_Encour<=4; Vida_P1_Encour<=4;
                // ID 8, 9: Hidros (Tam 3)
                Vida_P2_Hidro1<=3; Vida_P2_Hidro2<=3; Vida_P1_Hidro1<=3; Vida_P1_Hidro2<=3;
                // ID 10, 11: Cruzadores (Tam 2)
                Vida_P2_Cruz1<=2; Vida_P2_Cruz2<=2; Vida_P1_Cruz1<=2; Vida_P1_Cruz2<=2;
                // IDs 1-5 (Subs): Vida 1 (Não precisa de contador)
                
                Indice <= 0;
            end

            // MOVIMENTAÇÃO
            if (estado_futuro == Movimentar_Cursor) begin
                if (VezDoJogador == 0) begin 
                    if (Gamepad[0] && Cursor_P1_Y > 0) Cursor_P1_Y <= Cursor_P1_Y - 1;
                    if (Gamepad[1] && Cursor_P1_Y < 7) Cursor_P1_Y <= Cursor_P1_Y + 1;
                    if (Gamepad[2] && Cursor_P1_X > 0) Cursor_P1_X <= Cursor_P1_X - 1;
                    if (Gamepad[3] && Cursor_P1_X < 7) Cursor_P1_X <= Cursor_P1_X + 1;
                end else begin
                    if (Gamepad[0] && Cursor_P2_Y > 0) Cursor_P2_Y <= Cursor_P2_Y - 1;
                    if (Gamepad[1] && Cursor_P2_Y < 7) Cursor_P2_Y <= Cursor_P2_Y + 1;
                    if (Gamepad[2] && Cursor_P2_X > 0) Cursor_P2_X <= Cursor_P2_X - 1;
                    if (Gamepad[3] && Cursor_P2_X < 7) Cursor_P2_X <= Cursor_P2_X + 1;
                end
            end

            // TIRO
            if (estado_futuro == Atirar) begin
                ID_Atingido <= 0; 
                if (VezDoJogador == 0) begin 
                    if ((MapaOponente[Cursor_P1_Y*8 + Cursor_P1_X] & 8'h80) == 8'h80) begin
                        MapaOponente[Cursor_P1_Y*8 + Cursor_P1_X] <= MapaOponente[Cursor_P1_Y*8 + Cursor_P1_X] & 8'h7F;
                        ID_Atingido <= MapaOponente[Cursor_P1_Y*8 + Cursor_P1_X] & 8'h7F;
                        VezDoJogador <= 1;
                    end
                end else begin 
                    if ((MapaJogador[Cursor_P2_Y*8 + Cursor_P2_X] & 8'h80) == 8'h80) begin
                        MapaJogador[Cursor_P2_Y*8 + Cursor_P2_X] <= MapaJogador[Cursor_P2_Y*8 + Cursor_P2_X] & 8'h7F;
                        ID_Atingido <= MapaJogador[Cursor_P2_Y*8 + Cursor_P2_X] & 8'h7F;
                        VezDoJogador <= 0;
                    end
                end
            end

            // DANO E PONTOS (IDS NOVOS)
            if (estado_futuro == Verificar_Dano) begin
                if (ID_Atingido != 0) begin
                    if (VezDoJogador == 1) begin // P1 Pontua
                        case(ID_Atingido) 
                            1,2,3,4,5: PlacarP1 <= PlacarP1 + 1; // Subs
                            6: begin if(Vida_P2_Porta>0) Vida_P2_Porta<=Vida_P2_Porta-1; if(Vida_P2_Porta==1) PlacarP1<=PlacarP1+5; end
                            7: begin if(Vida_P2_Encour>0) Vida_P2_Encour<=Vida_P2_Encour-1; if(Vida_P2_Encour==1) PlacarP1<=PlacarP1+4; end
                            8: begin if(Vida_P2_Hidro1>0) Vida_P2_Hidro1<=Vida_P2_Hidro1-1; if(Vida_P2_Hidro1==1) PlacarP1<=PlacarP1+3; end
                            9: begin if(Vida_P2_Hidro2>0) Vida_P2_Hidro2<=Vida_P2_Hidro2-1; if(Vida_P2_Hidro2==1) PlacarP1<=PlacarP1+3; end
                            10: begin if(Vida_P2_Cruz1>0) Vida_P2_Cruz1<=Vida_P2_Cruz1-1; if(Vida_P2_Cruz1==1) PlacarP1<=PlacarP1+2; end
                            11: begin if(Vida_P2_Cruz2>0) Vida_P2_Cruz2<=Vida_P2_Cruz2-1; if(Vida_P2_Cruz2==1) PlacarP1<=PlacarP1+2; end
                        endcase
                    end else begin // P2 Pontua
                        case(ID_Atingido) 
                            1,2,3,4,5: PlacarP2 <= PlacarP2 + 1;
                            6: begin if(Vida_P1_Porta>0) Vida_P1_Porta<=Vida_P1_Porta-1; if(Vida_P1_Porta==1) PlacarP2<=PlacarP2+5; end
                            7: begin if(Vida_P1_Encour>0) Vida_P1_Encour<=Vida_P1_Encour-1; if(Vida_P1_Encour==1) PlacarP2<=PlacarP2+4; end
                            8: begin if(Vida_P1_Hidro1>0) Vida_P1_Hidro1<=Vida_P1_Hidro1-1; if(Vida_P1_Hidro1==1) PlacarP2<=PlacarP2+3; end
                            9: begin if(Vida_P1_Hidro2>0) Vida_P1_Hidro2<=Vida_P1_Hidro2-1; if(Vida_P1_Hidro2==1) PlacarP2<=PlacarP2+3; end
                            10: begin if(Vida_P1_Cruz1>0) Vida_P1_Cruz1<=Vida_P1_Cruz1-1; if(Vida_P1_Cruz1==1) PlacarP2<=PlacarP2+2; end
                            11: begin if(Vida_P1_Cruz2>0) Vida_P1_Cruz2<=Vida_P1_Cruz2-1; if(Vida_P1_Cruz2==1) PlacarP2<=PlacarP2+2; end
                        endcase
                    end
                end
            end

            // RENDERIZAÇÃO
            if (estado_futuro == Inicializa_TX) begin Addr <= 0; Indice <= 0; end
            if (estado_futuro == Escreve_Header_1 || estado_futuro == Escreve_Header_2 || estado_futuro == Escreve_Mapa_Byte || estado_futuro == Escreve_Score_P1 || estado_futuro == Escreve_Score_P2 || estado_futuro == Escreve_Cur_P1 || estado_futuro == Escreve_Cur_P2) 
                Addr <= Addr + 1;
            if (estado_futuro == Atualiza_Loop) Indice <= Indice + 1;
            if (estado_futuro == TX_Inicio) i <= 0;
            if (estado_futuro == TX_Send) i <= i + 1;
            if (i == 134) FlagTerminoTransmissao <= 1; else FlagTerminoTransmissao <= 0;
        end
    end

    // FSM E SAIDAS (IDÊNTICAS AO ANTERIOR, PODE COPIAR)
    // ...
    // (Mantenha o bloco always @ (*) de transição e o de saída que você já tem, 
    // pois eles não dependem dos IDs, apenas dos estados).
    always @ (*) begin
        case (estado_atual)
            Zera_Timer: estado_futuro = Aguarda_Start;
            Aguarda_Start: if (Start) estado_futuro = RX_Wait_Soltar; else estado_futuro = Aguarda_Start;
            RX_Wait_Soltar: if (!Start) estado_futuro = RX_Aguarda; else estado_futuro = RX_Wait_Soltar;
            RX_Aguarda: if (rx_ready) estado_futuro = RX_Grava; else estado_futuro = RX_Aguarda;
            RX_Grava: if (Indice == 133) estado_futuro = Setup_Fim; else estado_futuro = RX_Aguarda;
            Setup_Fim: estado_futuro = Inicializa_TX;
            Inicializa_TX: estado_futuro = Escreve_Header_1;
            Escreve_Header_1: estado_futuro = Escreve_Header_2;
            Escreve_Header_2: estado_futuro = Carrega_Mapas;
            Carrega_Mapas: estado_futuro = Escreve_Mapa_Byte;
            Escreve_Mapa_Byte: estado_futuro = Atualiza_Loop;
            Atualiza_Loop: if (Indice < 128) estado_futuro = Carrega_Mapas; else estado_futuro = Escreve_Score_P1;
            Escreve_Score_P1: estado_futuro = Escreve_Score_P2;
            Escreve_Score_P2: estado_futuro = Escreve_Cur_P1;
            Escreve_Cur_P1: estado_futuro = Escreve_Cur_P2;
            Escreve_Cur_P2: estado_futuro = TX_Inicio;
            TX_Inicio: estado_futuro = TX_Check;
            TX_Check: estado_futuro = TX_Send;
            TX_Send: estado_futuro = TX_Wait;
            TX_Wait: if (tx_busy) estado_futuro = TX_Wait; else if (FlagTerminoTransmissao) estado_futuro = Aguardar_Gamepad; else estado_futuro = TX_Check;
            Aguardar_Gamepad:
                if (PlacarP1 >= 24 || PlacarP2 >= 24) estado_futuro = Fim_de_Jogo;
                else if (Gamepad[6]) estado_futuro = Atirar; 
                else if (Gamepad[0] || Gamepad[1] || Gamepad[2] || Gamepad[3]) estado_futuro = Movimentar_Cursor;
                else estado_futuro = Aguardar_Gamepad;
            Movimentar_Cursor: estado_futuro = Inicializa_TX; 
            Atirar: estado_futuro = Verificar_Dano;
            Verificar_Dano: estado_futuro = Inicializa_TX;
            default: estado_futuro = Zera_Timer;
        endcase
    end

    always @ (*) begin
        clkMemoTX = 0; WEnableTX = 0; tx_start = 0; AddrMemoTX = 0; DataMemoTX = 0;
        case (estado_atual)
            Escreve_Header_1: begin AddrMemoTX=0; DataMemoTX=8'hFF; clkMemoTX=1; WEnableTX=1; end
            Escreve_Header_2: begin AddrMemoTX=1; DataMemoTX=8'hFF; clkMemoTX=1; WEnableTX=1; end
            Escreve_Mapa_Byte: begin
                AddrMemoTX = Addr;
                if (Indice < 64) DataMemoTX = MapaOponente[Indice];
                else             DataMemoTX = MapaJogador[Indice - 64];
                clkMemoTX=1; WEnableTX=1;
            end
            Escreve_Score_P1: begin AddrMemoTX=Addr; DataMemoTX=PlacarP1; clkMemoTX=1; WEnableTX=1; end
            Escreve_Score_P2: begin AddrMemoTX=Addr; DataMemoTX=PlacarP2; clkMemoTX=1; WEnableTX=1; end
            Escreve_Cur_P1: begin AddrMemoTX=Addr; DataMemoTX={Cursor_P1_X[3:0], Cursor_P1_Y[3:0]}; clkMemoTX=1; WEnableTX=1; end
            Escreve_Cur_P2: begin AddrMemoTX=Addr; DataMemoTX={Cursor_P2_X[3:0], Cursor_P2_Y[3:0]}; clkMemoTX=1; WEnableTX=1; end
            TX_Check: begin AddrMemoTX=i; end
            TX_Send:  begin AddrMemoTX=i; tx_start=1; end
        endcase
    end
endmodule