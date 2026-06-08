`timescale 1ns / 1ps

module baud_gen #(
    parameter CLK_FREQ = 100000000, 
    parameter BAUD_RATE = 9600      
)(
    input clk,
    input rst,
    output reg tick
);
    
    localparam MAX_COUNT = CLK_FREQ / (BAUD_RATE * 16);
    reg [$clog2(MAX_COUNT)-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick <= 0;
        end else begin
            if (counter == MAX_COUNT - 1) begin
                counter <= 0;
                tick <= 1; 
            end else begin
                counter <= counter + 1;
                tick <= 0;
            end
        end
    end
endmodule
