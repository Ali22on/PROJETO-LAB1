module Gamepad (Clock50, Reset, Pino1, Pino2, Pino3, Pino4, Pino6, Pino9, Saidas, Select);

input Clock50, Reset, Pino1, Pino2, Pino3, Pino4, Pino6, Pino9;
output reg [11:0] Saidas;
output reg Select;

// Saidas[11] = Saida_Mode
// Saidas[10] = Saida_Start
// Saidas[9] = Saida_Z
// Saidas[8] = Saida_Y
// Saidas[7] = Saida_X
// Saidas[6] = Saida_C
// Saidas[5] = Saida_B
// Saidas[4] = Saida_A
// Saidas[3] = Saida_Right
// Saidas[2] = Saida_Left
// Saidas[1] = Saida_Down
// Saidas[0] = Saida_Up


parameter	AGUARDAR_ATIVACAO = 0,
				ESTADO_0 = 1,
				ESTADO_1 = 2,
				ESTADO_2 = 3,
				ESTADO_3 = 4,
				ESTADO_4 = 5,
				ESTADO_5 = 6,
				ESTADO_6 = 7,
				ESTADO_7 = 8;
				
reg [3:0] EstadoAtual, EstadoFuturo;

reg [12:0] Contador;

reg [32:0] ContadorFlag;

wire Flag;

always @(negedge Clock50)
begin
	if (Reset)
	begin
		ContadorFlag <= 0;
	end
	else
	begin
		ContadorFlag <= ContadorFlag + 1;
		if (ContadorFlag > 1666666)
		begin
			ContadorFlag <= 0;
		end
	end
end

assign Flag = (ContadorFlag > 1666660) ? 1 : 0;

always @(posedge Clock50)
begin
	if (Reset)
	begin
		EstadoAtual <= AGUARDAR_ATIVACAO;
		Contador <= 0;
	end
	else
	begin
		EstadoAtual <= EstadoFuturo;
	end
	
	if (EstadoFuturo == AGUARDAR_ATIVACAO)
	begin
		Contador <= 0;
	end
	else
	begin
		Contador <= Contador + 1;
	end
	
	if (EstadoFuturo == ESTADO_1)
	begin
		Saidas[4] <= !Pino6; // Saida_A
		Saidas[10] <= !Pino9; // Saida_Start
	end
	
	if (EstadoFuturo == ESTADO_2)
	begin
		Saidas[0] <= !Pino1; // Saida_Up
		Saidas[1] <= !Pino2; // Saida_Down
		Saidas[2] <= !Pino3; // Saida_Left
		Saidas[3] <= !Pino4; // Saida_Right
	end
	
	if (EstadoFuturo == ESTADO_4)
	begin
		Saidas[5] <= !Pino6; // Saida_B
		Saidas[6] <= !Pino9; // Saida_C
	end
	
	if (EstadoFuturo == ESTADO_6)
	begin
		Saidas[7] <= !Pino3; // Saida_X
		Saidas[8] <= !Pino2; // Saida_Y
		Saidas[9] <= !Pino1; // Saida_Z
		Saidas[11] <= !Pino4; // Saida_Mode
	end
end

// Decodificador de Proximo Estado
always @(*)
begin
	case (EstadoAtual)
		AGUARDAR_ATIVACAO:	if (Flag)
										EstadoFuturo = ESTADO_0;
									else
										EstadoFuturo = AGUARDAR_ATIVACAO;
		ESTADO_0:	if (Contador < 1000)
							EstadoFuturo = ESTADO_0;
						else
							EstadoFuturo = ESTADO_1;
		ESTADO_1:	if (Contador < 2000)
							EstadoFuturo = ESTADO_1;
						else
							EstadoFuturo = ESTADO_2;
		ESTADO_2:	if (Contador < 3000)
							EstadoFuturo = ESTADO_2;
						else
							EstadoFuturo = ESTADO_3;
		ESTADO_3:	if (Contador < 4000)
							EstadoFuturo = ESTADO_3;
						else
							EstadoFuturo = ESTADO_4;
		ESTADO_4:	if (Contador < 5000)
							EstadoFuturo = ESTADO_4;
						else
							EstadoFuturo = ESTADO_5;
		ESTADO_5: 	if (Contador < 6000)
							EstadoFuturo = ESTADO_5;
						else
							EstadoFuturo = ESTADO_6;
		ESTADO_6:	if (Contador < 7000)
							EstadoFuturo = ESTADO_6;
						else
							EstadoFuturo = ESTADO_7;
		ESTADO_7:	if (Contador < 8000)
							EstadoFuturo = ESTADO_7;
						else
							EstadoFuturo = AGUARDAR_ATIVACAO;
		default:		EstadoFuturo = AGUARDAR_ATIVACAO;
	endcase 
end

// Decodificador de Saida
always @(*)
begin
	Select = 1;
	case (EstadoAtual)
		ESTADO_1: Select = 0;
		ESTADO_3: Select = 0;
		ESTADO_5: Select = 0;
		ESTADO_7: Select = 0;
		default: Select = 1;
	endcase	
end

endmodule