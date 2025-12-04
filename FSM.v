module ControladorPrincipalBN (
    input clock,
    input reset,
    input Start,    
    input [11:0] Gamepad,
    
    // UART TX
    input tx_busy,
    output reg [7:0] DataMemoTX,
    output reg WEnableTX,
    output reg [8:0] AddrMemoTX,        
    output reg clkMemoTX,
    output reg tx_start,
    
    // UART RX (Ignorado neste modo)
    input [7:0] rx_data,
    input rx_ready
);

    parameter   Zera_Timer = 0,
                Aguarda_Start = 1,
                Carrega_Espelho_MIF = 2, // Estado de Carga Manual
                
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
    
    // CORREÇÃO: 'Addr' é o contador interno. 'AddrMemoTX' é apenas a saída.
    reg [8:0] Addr;   

    always @ (posedge clock) begin
        if (reset) begin
            estado_atual <= Zera_Timer;
            Cursor_P1_X <= 3; Cursor_P1_Y <= 3; Cursor_P2_X <= 4; Cursor_P2_Y <= 4;
            PlacarP1 <= 0; PlacarP2 <= 0; VezDoJogador <= 0;
            i <= 0; Indice <= 0;
            Addr <= 0;
        end
        else begin
            estado_atual <= estado_futuro;

    // --- ESTADO 2: CARREGA O GABARITO DO MIF512.MIF ---
            if (estado_futuro == Carrega_Espelho_MIF) begin
                // 1. Limpa tudo com Água Escondida (128)
                for (k=0; k<64; k=k+1) begin 
                    MapaOponente[k] <= 128; 
                    MapaJogador[k]  <= 128; 
                end
                
                // 2. Inicializa Vidas (IDs conforme naval.ts)
                // 6=Porta, 7=Encour, 8-9=Hidro, 10-11=Cruz
                Vida_P2_Porta<=5; Vida_P2_Encour<=4; Vida_P2_Hidro1<=3; Vida_P2_Hidro2<=3; Vida_P2_Cruz1<=2; Vida_P2_Cruz2<=2;
                Vida_P1_Porta<=5; Vida_P1_Encour<=4; Vida_P1_Hidro1<=3; Vida_P1_Hidro2<=3; Vida_P1_Cruz1<=2; Vida_P1_Cruz2<=2;

                // 3. MAPA OPONENTE (Baseado no seu mif512.mif - Endereços 2 a 65)
                // Obs:NÃO Adicionamos +128 (Bit 7) para começar ESCONDIDO
                
                // Sub (ID 5) em pos 0
                MapaOponente[0] <= 5;
                // Hidro 1 (ID 8) espalhado
                MapaOponente[4] <= 8; MapaOponente[13] <= 8; MapaOponente[20] <= 8; 
                // Sub (ID 4) em pos 9
                MapaOponente[9] <= 4;
                // Sub (ID 3) em pos 18
                MapaOponente[18] <= 3;
                // Sub (ID 2) em pos 27
                MapaOponente[27] <= 2;
                // Hidro 2 (ID 9) espalhado
                MapaOponente[28] <= 9; MapaOponente[37] <= 9; MapaOponente[44] <= 9;
                // Encouraçado (ID 7) - Vertical Coluna 0 (Indices 30,38,46,54 no seu MIF sao 32,40,48,56)
                // Corrigindo pelos endereços do seu MIF: 32, 40, 48, 56 -> Indices 30, 38, 46, 54
                MapaOponente[30]<=7; MapaOponente[38]<=7; MapaOponente[46]<=7; MapaOponente[54]<=7;
                // PortaAvião (ID 6) - Vertical Coluna 7
                MapaOponente[31]<=6; MapaOponente[39]<=6; MapaOponente[47]<=6; MapaOponente[55]<=6; MapaOponente[63]<=128+6;
                // Cruzador 1 (ID 10) - Vertical
                MapaOponente[32]<=10; MapaOponente[40]<=10;
                // Cruzador 2 (ID 11) - Vertical
                MapaOponente[34]<=11; MapaOponente[42]<=11;
                // Sub (ID 1) em pos 36
                MapaOponente[36]<=1;

                // 4. MAPA JOGADOR (Baseado no seu mif512.mif - Endereços 66 a 129)
                // Obs: NÃO adicionamos 128, pois seus navios devem ser visíveis para você
                
         // Sub (ID 5) em pos 0
                MapaJogador[0] <= 5;
                // Hidro 1 (ID 8) espalhado
                MapaJogador[4] <= 8; MapaJogador[13] <= 8; MapaJogador[20] <= 8; 
                // Sub (ID 4) em pos 9
                MapaJogador[9] <= 4;
                // Sub (ID 3) em pos 18
                MapaJogador[18] <= 3;
                // Sub (ID 2) em pos 27
                MapaJogador[27] <= 2;
                // Hidro 2 (ID 9) espalhado
                MapaJogador[28] <= 9; MapaJogador[37] <= 9; MapaJogador[44] <= 9;
                // Encouraçado (ID 7) - Vertical Coluna 0 (Indices 30,38,46,54 no seu MIF sao 32,40,48,56)
                // Corrigindo pelos endereços do seu MIF: 32, 40, 48, 56 -> Indices 30, 38, 46, 54
                MapaJogador[30]<=7; MapaJogador[38]<=7; MapaJogador[46]<=7; MapaJogador[54]<=7;
                // PortaAvião (ID 6) - Vertical Coluna 7
                MapaJogador[31]<=6; MapaJogador[39]<=6; MapaJogador[47]<=6; MapaJogador[55]<=6; MapaJogador[63]<=128+6;
                // Cruzador 1 (ID 10) - Vertical
                MapaJogador[32]<=10; MapaJogador[40]<=10;
                // Cruzador 2 (ID 11) - Vertical
                MapaJogador[34]<=11; MapaJogador[42]<=11;
                // Sub (ID 1) em pos 36
                MapaJogador[36]<=1;
            // --- TIRO ---
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

            // --- DANO ---
            if (estado_futuro == Verificar_Dano) begin
                if (ID_Atingido != 0) begin
                    if (VezDoJogador == 1) begin // P1 Pontua
                        case(ID_Atingido) 
                            1,2,3,4,5: PlacarP1 <= PlacarP1 + 1; 
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

            // --- CONTROLE DE ENDEREÇO DA RAM (SEQUENCIAL) ---
            if (estado_futuro == Inicializa_TX) begin 
                Addr <= 0; 
                Indice <= 0; 
            end
            
            // CORREÇÃO DO ERRO 10028: Aqui incrementamos a variável interna 'Addr'
            // Não mexemos no 'AddrMemoTX' aqui!
            if (estado_futuro == Escreve_Header_1 || estado_futuro == Escreve_Header_2 || 
                estado_futuro == Escreve_Mapa_Byte || estado_futuro == Escreve_Score_P1 || 
                estado_futuro == Escreve_Score_P2 || estado_futuro == Escreve_Cur_P1 || 
                estado_futuro == Escreve_Cur_P2) 
            begin
                Addr <= Addr + 1;
            end

            if (estado_futuro == Atualiza_Loop) Indice <= Indice + 1;

            // --- UART ---
            if (estado_futuro == TX_Inicio) i <= 0;
            if (estado_futuro == TX_Send) i <= i + 1;
            if (i == 134) FlagTerminoTransmissao <= 1; else FlagTerminoTransmissao <= 0;
        end
    end

    // --- FSM (Transições) ---
    always @ (*) begin
        case (estado_atual)
            Zera_Timer: estado_futuro = Aguarda_Start;
            Aguarda_Start: if (Start) estado_futuro = Carrega_Espelho_MIF; else estado_futuro = Aguarda_Start;
            Carrega_Espelho_MIF: estado_futuro = Inicializa_TX;

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

    // --- SAÍDAS (Combinacional Puro) ---
    always @ (*) begin
        clkMemoTX = 0; WEnableTX = 0; tx_start = 0; AddrMemoTX = 0; DataMemoTX = 0;
        
        case (estado_atual)
            // ESCREVENDO NA RAM (Usamos 'Addr' como fonte do endereço)
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

            // LENDO PARA UART (Usamos 'i' como fonte do endereço)
            TX_Check: begin AddrMemoTX=i; end
            TX_Send:  begin AddrMemoTX=i; tx_start=1; end
        endcase
    end
endmodule