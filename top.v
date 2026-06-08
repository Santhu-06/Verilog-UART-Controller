`timescale 1ns / 1ps

module top(
    input clk,
    input rst,
    
    // Transmitter External Interface
    input tx_start,
    input [7:0] tx_data,
    output tx,
    output tx_done,
    
    // Receiver External Interface
    input rx,
    output rx_done,
    output [7:0] rx_data
);

    wire tick; // Connects internal baud_gen clock tick to rx/tx engines

    // 1. Instantiate Baud Rate Generator (100MHz clock down to 9600 Baud)
    baud_gen #(
        .CLK_FREQ(100000000), 
        .BAUD_RATE(9600)
    ) conversion_timer (
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );

    // 2. Instantiate UART Receiver
    uart_rx receiver (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tick(tick),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    // 3. Instantiate UART Transmitter
    uart_tx transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tick(tick),
        .tx_data(tx_data),
        .tx(tx),
        .tx_done(tx_done)
    );

endmodule