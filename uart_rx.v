`timescale 1ns / 1ps

module uart_rx(
    input clk,
    input rst,
    input rx,
    input tick,
    output reg rx_done,
    output reg [7:0] rx_data
);
    // State Encodings
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state, next_state;
    reg [3:0] tick_count, next_tick_count; // Counts up to 16 ticks per bit width
    reg [2:0] bit_count, next_bit_count;   // Tracks the 8 incoming bits
    reg [7:0] rx_reg, next_rx_reg;         // Assembles the bits into a byte
    reg rx_done_next;

    // FSM State Registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            tick_count <= 0;
            bit_count  <= 0;
            rx_reg     <= 0;
            rx_done    <= 0;
            rx_data    <= 0;
        end else begin
            state      <= next_state;
            tick_count <= next_tick_count;
            bit_count  <= next_bit_count;
            rx_reg     <= next_rx_reg;
            rx_done    <= rx_done_next;
            if (rx_done_next) begin
                rx_data <= next_rx_reg; // Save valid data out
            end
        end
    end

    // FSM Next-State Logic
    always @* begin
        next_state      = state;
        next_tick_count = tick_count;
        next_bit_count  = bit_count;
        next_rx_reg     = rx_reg;
        rx_done_next    = 1'b0;

        case (state)
            IDLE: begin
                if (~rx) begin // Start bit detected (line transitions low)
                    next_state      = START;
                    next_tick_count = 0;
                end
            end

            START: begin
                if (tick) begin
                    if (tick_count == 7) begin // Sample at the middle of the start bit (tick 7 of 15)
                        next_state      = DATA;
                        next_tick_count = 0;
                        next_bit_count  = 0;
                    end else begin
                        next_tick_count = tick_count + 1;
                    end
                end
            end

            DATA: begin
                if (tick) begin
                    if (tick_count == 15) begin // Sample in the middle of each data bit width
                        next_tick_count = 0;
                        next_rx_reg     = {rx, rx_reg[7:1]}; // Shift right (UART sends LSB first)
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
                if (tick) begin
                    if (tick_count == 15) begin // Sample middle of the stop bit
                        next_state   = IDLE;
                        rx_done_next = 1'b1; // Trigger complete pulse
                    end else begin
                        next_tick_count = tick_count + 1;
                    end
                end
            end
        endcase
    end
endmodule