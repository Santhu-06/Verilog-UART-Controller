`timescale 1ns / 1ps

module tb_uart();

    // Inputs to the top module (declared as reg)
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;
    
    // Outputs from the top module (declared as wire)
    wire tx;
    wire tx_done;
    wire rx_done;
    wire [7:0] rx_data;

    // Loopback connection: Wire the Transmitter pin straight to the Receiver pin!
    wire loopback;
    assign loopback = tx; 

    // Instantiate the Top Module (Unit Under Test)
    top uut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_done(tx_done),
        .rx(loopback), // Fed from transmitter output
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    // Generate Clock: 100 MHz (10ns total period, toggles every 5ns)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        tx_start = 0;
        tx_data = 8'h0;

        // Hold reset active for 100ns, then release it
        #100;
        rst = 0;
        #50;

        // Transmit the character 'A' (Hex value: 8'h41)
        $display("[TB] Sending character 'A' (8'h41) over UART...");
        tx_data = 8'h41; 
        tx_start = 1;   // Pulse tx_start high
        #10;
        tx_start = 0;   // Pull it back down

        // Wait here until the receiver finishes processing the incoming serial data
        @ (posedge rx_done);
        #100;
        
        // Verification Check
        if (rx_data == 8'h41)
            $display("[SUCCESS] Received data matches perfectly! UART working.");
        else
            $display("[ERROR] Data mismatch! Sent: 41, Received: %h", rx_data);

        $finish; // End simulation cleanly
    end
      
endmodule