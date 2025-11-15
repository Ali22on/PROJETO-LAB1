// uart_simple.v - UART RX/TX 

module uart_simple(
    input clk,
    input rst,
    input rx,             // serial in
    output tx,            // serial out
    output reg cmd_ready,

    
    // --- PORTAS ADICIONADAS PARA O TESTE INVERSO ---
    input [7:0] tx_data_in,     // O byte que queremos enviar
    input tx_start_in,          // O pulso para começar a enviar
    output tx_busy_out           // Um sinal para dizer "estou ocupado enviando"
);

// --- Parameters ---
parameter CLK_FREQ = 50000000;
parameter BAUD = 115200;
localparam BAUD_DIV = CLK_FREQ / BAUD;

// --- Simple UART RX (byte oriented) ---
reg rx_sync0, rx_sync1;
wire rx_f;

always @(posedge clk) begin
    rx_sync0 <= rx;
    rx_sync1 <= rx_sync0;
end
assign rx_f = rx_sync1;

reg [15:0] baud_cnt_rx;
reg [3:0] bit_cnt_rx;
reg [7:0] rx_shift;
reg [7:0] rx_byte;
reg rx_byte_ready;

// Definições da Máquina de Estados (FSM) do Receptor
localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START = 1;
localparam RX_STATE_DATA = 2;
localparam RX_STATE_STOP = 3;

reg [2:0] rx_state;

always @(posedge clk) begin
    if (rst) begin
        rx_state <= RX_STATE_IDLE;
        rx_byte_ready <= 1'b0;
        baud_cnt_rx <= 16'd0;
        bit_cnt_rx <= 4'd0;
    end else begin
        
        rx_byte_ready <= 1'b0; // Valor padrão (auto-limpa)
        
        case (rx_state)
            
            RX_STATE_IDLE: begin
                if (rx_f == 0) begin // Start bit detectado (borda de descida)
                    rx_state <= RX_STATE_START;
                    // Espera metade de um bit para aterrar no *meio* do start bit
                    baud_cnt_rx <= BAUD_DIV / 2; 
                end
            end
            
            RX_STATE_START: begin
                if (baud_cnt_rx == 0) begin
                    // Estamos no meio do start bit.
                    // Agora, carrega o contador para um *bit inteiro*
                    // para aterrar no meio do primeiro bit de dados (D0)
                    baud_cnt_rx <= BAUD_DIV - 1;
                    rx_state <= RX_STATE_DATA;
                    bit_cnt_rx <= 4'd0; // Começa a contar do bit 0
                    rx_shift <= 8'd0;
                end else begin
                    baud_cnt_rx <= baud_cnt_rx - 1;
                end
            end
            
            RX_STATE_DATA: begin
                if (baud_cnt_rx == 0) begin
                    //no meio de um bit de dados. Amostrar!
                    baud_cnt_rx <= BAUD_DIV - 1; // Recarrega para o próximo bit
                    rx_shift <= {rx_f, rx_shift[7:1]}; // Armazena o bit (LSB first)
                    
                    if (bit_cnt_rx == 7) begin // Este foi o último bit (bit 7)?
                        rx_state <= RX_STATE_STOP; // Se sim, vai para o stop bit
                    end else begin
                        bit_cnt_rx <= bit_cnt_rx + 1; // Se não, incrementa o contador de bits
                    end
                end else begin
                    baud_cnt_rx <= baud_cnt_rx - 1;
                end
            end
            
            RX_STATE_STOP: begin
                if (baud_cnt_rx == 0) begin
                    //no meio do stop bit. O byte está completo.
                    rx_byte <= rx_shift; // O byte está pronto
                    rx_byte_ready <= 1'b1; // Sinaliza ao Parser
                    rx_state <= RX_STATE_IDLE; // Volta ao estado ocioso
                end else begin
                    baud_cnt_rx <= baud_cnt_rx - 1;
                end
            end
            
            default: rx_state <= RX_STATE_IDLE;
            
        endcase
    end
end
// --- Simple UART TX (send single byte) ---
reg [15:0] baud_cnt_tx;
reg [3:0] bit_cnt_tx;
reg [9:0] tx_shift; // start + 8 data + stop
reg tx_busy;
reg tx_out;

assign tx = tx_out;
assign tx_busy_out = tx_busy; // Expõe o sinal 'busy' para fora

// --- Bloco 'always' ÚNICO para todo o Transmissor (TX) ---
always @(posedge clk) begin
    if (rst) begin
        baud_cnt_tx <= 16'd0;
        bit_cnt_tx <= 4'd0;
        tx_busy <= 1'b0;
        tx_out <= 1'b1;
        tx_shift <= 10'h3FF;
    end else begin
        
        if (!tx_busy) begin
            // ESTADO: OCIOSO (IDLE)
            tx_out <= 1'b1; // Mantém a linha em alta
            
            // Verifica se um envio foi solicitado (pela porta tx_start_in)
            if (tx_start_in) begin
                tx_busy <= 1'b1;
                // Carrega o pacote: start(0), dados[7:0], stop(1)
                // usa o dado da porta tx_data_in
                tx_shift <= {1'b1, tx_data_in, 1'b0}; 
                baud_cnt_tx <= BAUD_DIV - 1;
                bit_cnt_tx <= 4'd0;
            end
            
        end else begin
            // ESTADO: OCUPADO (BUSY) - Transmitindo
            if (baud_cnt_tx == 0) begin
                baud_cnt_tx <= BAUD_DIV - 1;
                tx_out <= tx_shift[0];
                tx_shift <= {1'b1, tx_shift[9:1]}; // Desloca para o próximo bit
                
                if (bit_cnt_tx == 9) begin // 10 bits enviados (1 start + 8 data + 1 stop)
                    tx_busy <= 1'b0; // Volta para OCIOSO
                    bit_cnt_tx <= 4'd0;
                end else begin
                    bit_cnt_tx <= bit_cnt_tx + 1;
                end
            end else begin
                baud_cnt_tx <= baud_cnt_tx - 1;
            end
        end
    end
end


// --- Parser para ASCII "P"
// maquina de estado coleta bytes
reg [3:0] parse_state; 

always @(posedge clk) begin
    if (rst) begin
        parse_state <= 0;
        cmd_ready <= 0;
    end else begin
        cmd_ready <= 0; // Auto-limpa o pulso
        
        if (rx_byte_ready) begin
            // A máquina de estados agora só tem um trabalho: procurar por 'P'
            case (parse_state) // (parse_state é sempre 0)
                0: begin
                    if (rx_byte == "P") begin
                        cmd_ready <= 1'b1; // Encontrou 'P', pisca o LED!
                        // Não muda de estado, fica em 0
                        // para procurar o próximo 'P'
                    end
                end
                default: parse_state <= 0;
            endcase
        end
    end
end

endmodule

