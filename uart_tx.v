`timescale 1ns / 1ps

module uart_tx(
    input clk,
    input rst,
    input tx_start,
    input tick,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_done
);
    // State Encodings
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state, next_state;
    reg [3:0] tick_count, next_tick_count; // Counts 16 ticks per bit width
    reg [2:0] bit_count, next_bit_count;   // Tracks which of the 8 bits is active
    reg [7:0] tx_reg, next_tx_reg;         // Holds the parallel data shifted out
    reg tx_next, tx_done_next;

    // FSM State Registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            tick_count <= 0;
            bit_count  <= 0;
            tx_reg     <= 0;
            tx         <= 1'b1; // UART idle state line voltage is high (1)
            tx_done    <= 1'b0;
        end else begin
            state      <= next_state;
            tick_count <= next_tick_count;
            bit_count  <= next_bit_count;
            tx_reg     <= next_tx_reg;
            tx         <= tx_next;
            tx_done    <= tx_done_next;
        end
    end

    // FSM Next-State Logic
    always @* begin
        next_state      = state;
        next_tick_count = tick_count;
        next_bit_count  = bit_count;
        next_tx_reg     = tx_reg;
        tx_next         = tx;
        tx_done_next    = 1'b0;

        case (state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    next_state      = START;
                    next_tick_count = 0;
                    next_tx_reg     = tx_data;
                end
            end

            START: begin
                tx_next = 1'b0; // Start bit is always low (0)
                if (tick) begin
                    if (tick_count == 15) begin
                        next_state      = DATA;
                        next_tick_count = 0;
                        next_bit_count  = 0;
                    end else begin
                        next_tick_count = tick_count + 1;
                    end
                end
            end

            DATA: begin
                tx_next = tx_reg[0]; // Send the Least Significant Bit first
                if (tick) begin
                    if (tick_count == 15) begin
                        next_tick_count = 0;
                        next_tx_reg     = tx_reg >> 1; // Shift out the bit
                        if (bit_count == 7) begin
                            next_state = STOP;
                        end else begin
                            next_bit_count = bit_count + 1;
                        end
                    end else begin
                        next_tick_count = tick_count + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1; // Stop bit is always high (1)
                if (tick) begin
                    if (tick_count == 15) begin
                        next_state   = IDLE;
                        tx_done_next = 1'b1; // Signal that byte is sent
                    end else begin
                        next_tick_count = tick_count + 1;
                    end
                end
            end
        endcase
    end
endmodule