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
    output reg tx_start
);

    // --- ESTADOS ---
    parameter   Zera_Timer = 0,
                Aguarda_Start = 1,
                Carrega_Mapas = 2,       
                Posiciona_Cursor_Default = 3,
                
                // Renderização
                Inicializa_Ponteiros_MemoTX = 10,
                Carrega_Dado_Atual = 11,
                Calcula_Dezena_Unidade = 12,
                Escreve_Dezena = 13,
                Escreve_Unidade = 14,
                Escreve_Virgula = 15,
                Atualiza_Loop = 16,
                Escreve_Separador_Mapas = 20, Escreve_Separador_Final = 21,
                Escreve_Placar = 22, Escreve_Cursor = 23, Escreve_New_Line = 24,
                
                // UART
                TX_Inicio = 30, TX_Config = 31, TX_Ler = 32,
                TX_Transmite = 33, TX_Inc = 34, TX_Wait = 35,
                
                // Jogo - Turno JOGADOR
                Aguardar_Gamepad = 40,
                Movimentar_Cursor = 41,
                Atirar_Jogador = 42,
                Verificar_Afundou_Jogador = 43,
                
                // Jogo - Turno CPU
                CPU_Gera_Coordenada = 50,
                CPU_Verifica_Validade = 51,
                Atirar_CPU = 52,
                Verificar_Afundou_CPU = 53,
                
                Fim_de_Jogo = 99;

    reg [6:0] estado_atual, estado_futuro; 
    reg FlagTerminoTransmissao;

    // --- MEMÓRIAS (5 Bits) ---
    // Bit 4: Tiro (16), Bits 3-0: ID (1-11)
    reg [4:0] MapaOponente [0:63]; 
    reg [4:0] MapaJogador  [0:63]; 

    // --- VIDAS E PLACAR ---
    reg [7:0] PlacarJogador;
    reg [7:0] PlacarCPU;
    
    // Vidas Oponente (Navios que você ataca)
    reg [2:0] Vida_Op_PortaAvioes, Vida_Op_Encouracado, Vida_Op_Hidro1, Vida_Op_Hidro2, Vida_Op_Cruz1, Vida_Op_Cruz2;
    // Vidas Jogador (Navios que a CPU ataca)
    reg [2:0] Vida_Jog_PortaAvioes, Vida_Jog_Encouracado, Vida_Jog_Hidro1, Vida_Jog_Hidro2, Vida_Jog_Cruz1, Vida_Jog_Cruz2;

    reg [3:0] ID_Atingido; 
    
    // --- GERAÇÃO ALEATÓRIA (LFSR) ---
    reg [5:0] lfsr; 
    reg [5:0] Alvo_CPU; 

    // Renderização
    reg [4:0] Valor_Bruto; 
    reg [7:0] ASCII_Dezena, ASCII_Unidade;
    integer i, k; 
    reg [7:0] Indice; 
    reg signed [4:0] Linha, Coluna; 
    reg [9:0] Addr;   

    // --- SEQUENCIAL ---
    always @ (posedge clock)
    begin
        if (reset)
        begin
            estado_atual <= Zera_Timer;
            Linha <= 0; Coluna <= 0;
            PlacarJogador <= 0; PlacarCPU <= 0;
            i <= 0;
            lfsr <= 6'b101010; // Seed inicial
        end
        else
        begin
            estado_atual <= estado_futuro;

            // Roda LFSR
            lfsr <= {lfsr[4:0], lfsr[5] ^ lfsr[4]};

            // --- INICIALIZAÇÃO ---
            if (estado_futuro == Carrega_Mapas)
            begin
                // Limpa
                for (k=0; k<64; k=k+1) begin MapaOponente[k]<=0; MapaJogador[k]<=0; end
                
                // Reinicia Vidas
                Vida_Op_PortaAvioes<=5; Vida_Op_Encouracado<=4; Vida_Op_Hidro1<=3; Vida_Op_Hidro2<=3; Vida_Op_Cruz1<=2; Vida_Op_Cruz2<=2;
                Vida_Jog_PortaAvioes<=5; Vida_Jog_Encouracado<=4; Vida_Jog_Hidro1<=3; Vida_Jog_Hidro2<=3; Vida_Jog_Cruz1<=2; Vida_Jog_Cruz2<=2;

                // --- POSICIONA INIMIGOS (GABARITO) ---
                // Porta-Aviões (ID 1)
                MapaOponente[0]<=1; MapaOponente[1]<=1; MapaOponente[2]<=1; MapaOponente[3]<=1; MapaOponente[4]<=1; 
                // Encouraçado (ID 2)
                MapaOponente[16]<=2; MapaOponente[24]<=2; MapaOponente[32]<=2; MapaOponente[40]<=2; 
                // Hidroaviões (ID 3 e 4)
                MapaOponente[56]<=3; MapaOponente[57]<=3; MapaOponente[58]<=3; 
                MapaOponente[61]<=4; MapaOponente[62]<=4; MapaOponente[63]<=4; 
                // Cruzadores (ID 5 e 6)
                MapaOponente[6]<=5; MapaOponente[7]<=5; 
                MapaOponente[14]<=6; MapaOponente[15]<=6; 
                // Submarinos (ID 7 a 11)
                MapaOponente[13]<=7; MapaOponente[21]<=8; MapaOponente[29]<=9; MapaOponente[37]<=10; MapaOponente[45]<=11; 

                // --- POSICIONA JOGADOR (Exemplo) ---
                // Para teste, colocamos um Porta Aviões e um Submarino
                MapaJogador[8]<=1; MapaJogador[9]<=1; MapaJogador[10]<=1; MapaJogador[11]<=1; MapaJogador[12]<=1;
                MapaJogador[63]<=11; 
            end

            // --- TURNO JOGADOR ---
            if (estado_futuro == Atirar_Jogador) begin
                ID_Atingido <= 0;
                if (MapaOponente[Linha*8 + Coluna] < 16) begin 
                    MapaOponente[Linha*8 + Coluna] <= MapaOponente[Linha*8 + Coluna] + 16;
                    ID_Atingido <= MapaOponente[Linha*8 + Coluna][3:0];
                end
            end
            
            if (estado_futuro == Verificar_Afundou_Jogador) begin
                if (ID_Atingido != 0) begin
                    case (ID_Atingido)
                        1: begin if(Vida_Op_PortaAvioes>0) Vida_Op_PortaAvioes<=Vida_Op_PortaAvioes-1; if(Vida_Op_PortaAvioes==1) PlacarJogador<=PlacarJogador+5; end
                        2: begin if(Vida_Op_Encouracado>0) Vida_Op_Encouracado<=Vida_Op_Encouracado-1; if(Vida_Op_Encouracado==1) PlacarJogador<=PlacarJogador+4; end
                        3: begin if(Vida_Op_Hidro1>0) Vida_Op_Hidro1<=Vida_Op_Hidro1-1; if(Vida_Op_Hidro1==1) PlacarJogador<=PlacarJogador+3; end
                        4: begin if(Vida_Op_Hidro2>0) Vida_Op_Hidro2<=Vida_Op_Hidro2-1; if(Vida_Op_Hidro2==1) PlacarJogador<=PlacarJogador+3; end
                        5: begin if(Vida_Op_Cruz1>0) Vida_Op_Cruz1<=Vida_Op_Cruz1-1; if(Vida_Op_Cruz1==1) PlacarJogador<=PlacarJogador+2; end
                        6: begin if(Vida_Op_Cruz2>0) Vida_Op_Cruz2<=Vida_Op_Cruz2-1; if(Vida_Op_Cruz2==1) PlacarJogador<=PlacarJogador+2; end
                        7,8,9,10,11: PlacarJogador <= PlacarJogador + 1;
                    endcase
                end
            end

            // --- TURNO CPU ---
            if (estado_futuro == CPU_Gera_Coordenada) begin
                Alvo_CPU <= lfsr;
            end

            if (estado_futuro == Atirar_CPU) begin
                ID_Atingido <= 0;
                MapaJogador[Alvo_CPU] <= MapaJogador[Alvo_CPU] + 16;
                ID_Atingido <= MapaJogador[Alvo_CPU][3:0];
            end

            if (estado_futuro == Verificar_Afundou_CPU) begin
                if (ID_Atingido != 0) begin 
                    case (ID_Atingido)
                        1: begin if(Vida_Jog_PortaAvioes>0) Vida_Jog_PortaAvioes<=Vida_Jog_PortaAvioes-1; if(Vida_Jog_PortaAvioes==1) PlacarCPU<=PlacarCPU+5; end
                        11: PlacarCPU <= PlacarCPU + 1;
                        default: PlacarCPU <= PlacarCPU + 1; // Simplificado para teste
                    endcase
                end
            end

            // --- RENDERIZAÇÃO ---
            if (estado_futuro == Inicializa_Ponteiros_MemoTX) begin Addr <= 0; Indice <= 0; end
            
            if (estado_futuro == Carrega_Dado_Atual) begin
                if (Indice < 64) begin
                    if (MapaOponente[Indice] < 16) Valor_Bruto <= 0; // Esconde se nao atingido
                    else Valor_Bruto <= MapaOponente[Indice]; 
                end else begin
                    Valor_Bruto <= MapaJogador[Indice-64]; // Mostra tudo
                end
            end
            
            // Converte Valor (0-27) para ASCII 2 Digitos
            if (estado_futuro == Calcula_Dezena_Unidade) begin
                if (Valor_Bruto >= 30) begin ASCII_Dezena <= "3"; ASCII_Unidade <= (Valor_Bruto - 30) + 48; end
                else if (Valor_Bruto >= 20) begin ASCII_Dezena <= "2"; ASCII_Unidade <= (Valor_Bruto - 20) + 48; end
                else if (Valor_Bruto >= 10) begin ASCII_Dezena <= "1"; ASCII_Unidade <= (Valor_Bruto - 10) + 48; end
                else begin ASCII_Dezena <= "0"; ASCII_Unidade <= Valor_Bruto + 48; end
            end

            // Incrementa
            if (estado_futuro == Atualiza_Loop) if (Indice < 128) Indice <= Indice + 1;
            
            // Endereçamento RAM Buffer
            if (estado_futuro == Escreve_Dezena || estado_futuro == Escreve_Unidade || estado_futuro == Escreve_Virgula || estado_futuro == Escreve_Separador_Mapas || estado_futuro == Escreve_Separador_Final || estado_futuro == Escreve_Placar || estado_futuro == Escreve_Cursor || estado_futuro == Escreve_New_Line) 
                Addr <= Addr + 1;

            // UART
            if (estado_futuro == TX_Inicio) i <= 0;
            if (estado_futuro == TX_Inc) i <= i + 1;
            if (i == 600) FlagTerminoTransmissao <= 1; else FlagTerminoTransmissao <= 0;

            // Cursor Gamepad
            if (estado_futuro == Movimentar_Cursor) begin
                if (Gamepad[0] && Linha > 0) Linha <= Linha - 1;
                else if (Gamepad[1] && Linha < 7) Linha <= Linha + 1;
                else if (Gamepad[2] && Coluna > 0) Coluna <= Coluna - 1;
                else if (Gamepad[3] && Coluna < 7) Coluna <= Coluna + 1;
            end
        end
    end

    // --- FSM (TRANSIÇÕES) ---
    always @ (*)
    begin
        case (estado_atual)
            Zera_Timer: estado_futuro = Aguarda_Start;
            Aguarda_Start: if (Start) estado_futuro = Aguarda_Start; else estado_futuro = Carrega_Mapas;
            Carrega_Mapas: estado_futuro = Posiciona_Cursor_Default;
            Posiciona_Cursor_Default: estado_futuro = Inicializa_Ponteiros_MemoTX;
            
            // Loop Renderização
            Inicializa_Ponteiros_MemoTX: estado_futuro = Carrega_Dado_Atual;
            Carrega_Dado_Atual: estado_futuro = Calcula_Dezena_Unidade;
            Calcula_Dezena_Unidade: estado_futuro = Escreve_Dezena;
            Escreve_Dezena: estado_futuro = Escreve_Unidade;
            Escreve_Unidade: estado_futuro = Escreve_Virgula;
            Escreve_Virgula: if (Indice == 63) estado_futuro = Escreve_Separador_Mapas; else if (Indice == 127) estado_futuro = Escreve_Separador_Final; else estado_futuro = Atualiza_Loop;
            Atualiza_Loop: estado_futuro = Carrega_Dado_Atual;
            Escreve_Separador_Mapas: estado_futuro = Atualiza_Loop; 
            Escreve_Separador_Final: estado_futuro = Escreve_Placar;
            Escreve_Placar: estado_futuro = Escreve_Cursor;
            Escreve_Cursor: estado_futuro = Escreve_New_Line;
            Escreve_New_Line: estado_futuro = TX_Inicio;

            // UART
            TX_Inicio: estado_futuro = TX_Config;
            TX_Config: estado_futuro = TX_Ler;
            TX_Ler: estado_futuro = TX_Transmite;
            TX_Transmite: estado_futuro = TX_Inc;
            TX_Inc: estado_futuro = TX_Wait;
            TX_Wait: if (tx_busy) estado_futuro = TX_Wait;
                     else if (FlagTerminoTransmissao) estado_futuro = Aguardar_Gamepad;
                     else estado_futuro = TX_Config;
            
            // Turnos
            Aguardar_Gamepad:
                if (Gamepad == 0) estado_futuro = Aguardar_Gamepad;
                else if (Gamepad[6]) estado_futuro = Atirar_Jogador; 
                else estado_futuro = Movimentar_Cursor; 
            
            Movimentar_Cursor: estado_futuro = Inicializa_Ponteiros_MemoTX;

            Atirar_Jogador: estado_futuro = Verificar_Afundou_Jogador;
            Verificar_Afundou_Jogador: estado_futuro = CPU_Gera_Coordenada; 

            CPU_Gera_Coordenada: estado_futuro = CPU_Verifica_Validade;
            CPU_Verifica_Validade: 
                if (MapaJogador[Alvo_CPU] >= 16) estado_futuro = CPU_Gera_Coordenada; 
                else estado_futuro = Atirar_CPU;
            
            Atirar_CPU: estado_futuro = Verificar_Afundou_CPU;
            Verificar_Afundou_CPU: estado_futuro = Inicializa_Ponteiros_MemoTX; 

            default: estado_futuro = Zera_Timer;
        endcase
    end

    // --- SAIDAS ---
    always @ (*)
    begin
        clkMemoTX = 0; WEnableTX = 0; tx_start = 0; AddrMemoTX = 0; DataMemoTX = 0;
        case (estado_atual)
            Escreve_Dezena: begin AddrMemoTX = Addr; DataMemoTX = ASCII_Dezena; clkMemoTX = 1; WEnableTX = 1; end
            Escreve_Unidade: begin AddrMemoTX = Addr; DataMemoTX = ASCII_Unidade; clkMemoTX = 1; WEnableTX = 1; end
            Escreve_Virgula: begin AddrMemoTX = Addr; DataMemoTX = ","; clkMemoTX = 1; WEnableTX = 1; end
            Escreve_Separador_Mapas: begin AddrMemoTX = Addr; DataMemoTX = "|"; clkMemoTX = 1; WEnableTX = 1; end
            Escreve_Separador_Final: begin AddrMemoTX = Addr; DataMemoTX = "|"; clkMemoTX = 1; WEnableTX = 1; end
            Escreve_Placar: begin AddrMemoTX = Addr+1; DataMemoTX = "0"; clkMemoTX = 1; WEnableTX = 1; end 
            Escreve_Cursor: begin AddrMemoTX = Addr+2; DataMemoTX = ","; clkMemoTX = 1; WEnableTX = 1; end
            Escreve_New_Line: begin AddrMemoTX = Addr+4; DataMemoTX = 8'd10; clkMemoTX = 1; WEnableTX = 1; end
            TX_Config: AddrMemoTX = i;
            TX_Ler: begin AddrMemoTX = i; clkMemoTX = 1; end
            TX_Transmite: begin AddrMemoTX = i; tx_start = 1; end
        endcase
    end
endmodule