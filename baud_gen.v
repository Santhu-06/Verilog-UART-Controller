`timescale 1ns / 1ps

module baud_gen #(
    parameter CLK_FREQ = 100000000, // 100 MHz default system clock
    parameter BAUD_RATE = 9600      // 9600 Baud Rate
)(
    input clk,
    input rst,
    output reg tick
);
    // For 16x oversampling at 9600 Baud:
    // Max counter value = CLK_FREQ / (BAUD_RATE * 16)
    localparam MAX_COUNT = CLK_FREQ / (BAUD_RATE * 16);
    reg [$clog2(MAX_COUNT)-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick <= 0;
        end else begin
            if (counter == MAX_COUNT - 1) begin
                counter <= 0;
                tick <= 1; // Generates a high pulse for exactly 1 clock cycle
            end else begin
                counter <= counter + 1;
                tick <= 0;
            end
        end
    end
endmodule