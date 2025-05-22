module avalon (
    input wire clk,       // clock do sistema
    input wire resetn,    // reset assíncrono ativo em nível alto (note que é posedge resetn no código)
    output reg valid,     // sinal que indica que os dados na saída são válidos
    input wire ready,     // sinal de entrada que indica que o consumidor está pronto para receber dados
    output reg [7:0] data // dados a serem transmitidos (8 bits)
);

    // Definição dos estados da máquina usando parâmetros (para facilitar leitura)
    parameter wait_fsm = 3'd0,       // estado inicial: espera o ready ficar ativo
              delay_cycle = 3'd1,    // estado que implementa o atraso de 1 ciclo entre ready subir e valid subir
              send4 = 3'd2,          // estado para enviar o dado 4
              send5 = 3'd3,          // estado para enviar o dado 5
              send6 = 3'd4,          // estado para enviar o dado 6
              finished = 3'd5;       // estado final, máquina para aqui

    reg [2:0] state, next_state;     // registradores para armazenar o estado atual e o próximo estado

    // Atualização do estado no clock ou reset
    // Note que o reset é ativo em nível alto (posedge resetn)
    always @(posedge clk or posedge resetn) begin
        if (resetn)
            state <= wait_fsm;      // se reset ativo, volta para estado inicial (esperando ready)
        else
            state <= next_state;    // caso contrário, atualiza para o próximo estado
    end

    // Lógica combinacional para determinar o próximo estado
    always @(*) begin
        case (state)
            wait_fsm: 
                next_state = (ready ? delay_cycle : wait_fsm);  // se ready ativo, passa para delay_cycle, senão fica esperando
            delay_cycle: 
                next_state = send4;                              // após o atraso, vai para enviar o 4
            send4: 
                next_state = (ready ? send5 : send4);            // enquanto ready ativo, avança para enviar 5; senão espera aqui
            send5: 
                next_state = (ready ? send6 : send5);            // enquanto ready ativo, avança para enviar 6; senão espera aqui
            send6: 
                next_state = (ready ? finished : send6);         // enquanto ready ativo, avança para estado final; senão espera aqui
            finished: 
                next_state = finished;                            // estado final, permanece aqui
            default: 
                next_state = wait_fsm;                            // default volta ao estado inicial
        endcase
    end

    // Controle das saídas (valid e data) conforme o estado atual, sempre no clock ou reset
    always @(posedge clk or posedge resetn) begin
        if (resetn) begin
            valid <= 1'b0;      // no reset, valid fica baixo
            data  <= 8'd0;      // no reset, data zera
        end else begin
            case (state)
                send4: begin 
                    valid <= 1'b1;  // valid alto para indicar dado válido
                    data <= 8'd4;   // transmite o dado 4
                end
                send5: begin 
                    valid <= 1'b1;  // valid alto para indicar dado válido
                    data <= 8'd5;   // transmite o dado 5
                end
                send6: begin 
                    valid <= 1'b1;  // valid alto para indicar dado válido
                    data <= 8'd6;   // transmite o dado 6
                end
                default: begin
                    valid <= 1'b0;  // fora dos estados de envio, valid fica baixo
                    data <= 8'd0;   // data não é relevante (pode ser zero)
                end
            endcase
        end
    end
endmodule
