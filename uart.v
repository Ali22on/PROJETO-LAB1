
// Módulo UART  - apenas serializa e desserializa byte

module uart_simple(
    input clk,
    input rst,
    input rx,             // serial in
    output tx,            // serial out
    
    // --- Saídas de Recepção (RX) ---
    output reg rx_byte_ready, // Pulsa quando um byte é recebido
    output reg [7:0] rx_byte, // O byte recebido
    
    // --- Entradas de Transmissão (TX) ---
    input [7:0] tx_data_in,
    input tx_start_in,
    output tx_busy_out
);

// --- Parâmetros ---
parameter CLK_FREQ = 50000000;
parameter BAUD = 115200;
localparam BAUD_DIV = CLK_FREQ / BAUD; // Aprox. 434

// --- Lógica de Recepção (RX) com FSM  ---
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
                if (rx_f == 0) begin // Start bit detectado
                    rx_state <= RX_STATE_START;
                    baud_cnt_rx <= BAUD_DIV / 2; // Espera metade do bit
                end
            end
            
            RX_STATE_START: begin
                if (baud_cnt_rx == 0) begin
                    // No meio do start bit
                    baud_cnt_rx <= BAUD_DIV - 1; // Recarrega para um bit inteiro
                    rx_state <= RX_STATE_DATA;
                    bit_cnt_rx <= 4'd0; 
                    rx_shift <= 8'd0;
                end else begin
                    baud_cnt_rx <= baud_cnt_rx - 1;
                end
            end
            
            RX_STATE_DATA: begin
                if (baud_cnt_rx == 0) begin
                    // No meio de um bit de dados
                    baud_cnt_rx <= BAUD_DIV - 1; 
                    rx_shift <= {rx_f, rx_shift[7:1]}; // Armazena o bit
                    
                    if (bit_cnt_rx == 7) begin // Se for o último bit
                        rx_state <= RX_STATE_STOP; 
                    end else begin
                        bit_cnt_rx <= bit_cnt_rx + 1;
                    end
                end else begin
                    baud_cnt_rx <= baud_cnt_rx - 1;
                end
            end
            
            RX_STATE_STOP: begin
                if (baud_cnt_rx == 0) begin
                    // No meio do stop bit
                    rx_byte <= rx_shift; // O byte está pronto
                    rx_byte_ready <= 1'b1; // Sinaliza à FSM principal
                    rx_state <= RX_STATE_IDLE; 
                end else begin
                    baud_cnt_rx <= baud_cnt_rx - 1;
                end
            end
            
            default: rx_state <= RX_STATE_IDLE;
            
        endcase
    end
end
// --- Fim da secção UART RX ---


// --- Lógica de Transmissão (TX) ---
reg [15:0] baud_cnt_tx;
reg [3:0] bit_cnt_tx;
reg [9:0] tx_shift; // start + 8 data + stop
reg tx_busy;
reg tx_out;

assign tx = tx_out;
assign tx_busy_out = tx_busy;

always @(posedge clk) begin
    if (rst) begin
        baud_cnt_tx <= 16'd0;
        bit_cnt_tx <= 4'd0;
        tx_busy <= 1'b0;
        tx_out <= 1'b1;
        tx_shift <= 10'h3FF;
    end else begin
        
        if (!tx_busy) begin
            // ESTADO: OCIOSO
            tx_out <= 1'b1;
            
            if (tx_start_in) begin
                tx_busy <= 1'b1;
                // Carrega o pacote: start(0), dados[7:0], stop(1)
                tx_shift <= {1'b1, tx_data_in, 1'b0}; 
                baud_cnt_tx <= BAUD_DIV - 1;
                bit_cnt_tx <= 4'd0;
            end
            
        end else begin
            // ESTADO: OCUPADO
            if (baud_cnt_tx == 0) begin
                baud_cnt_tx <= BAUD_DIV - 1;
                tx_out <= tx_shift[0];
                tx_shift <= {1'b1, tx_shift[9:1]}; // Desloca
                
                if (bit_cnt_tx == 9) begin // 10 bits enviados
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
// --- Fim da secção UART TX ---

endmodule
