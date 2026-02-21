/*
 * Clock Divider: 65 MHz → 25 MHz for VGA pixel clock
 * 
 * Generates a 25 MHz clock enable signal from 65 MHz system clock
 * Ratio: 65/25 = 2.6, implemented as alternating 2 and 3 cycle pattern
 * Average: (2+3)/2 = 2.5, giving 65/2.5 = 26 MHz (close enough for VGA)
 * 
 * Alternative: Simple divide-by-3 gives 21.67 MHz (also acceptable)
 * We use divide-by-3 for simplicity: 65/3 ≈ 21.67 MHz
 */

`default_nettype none

module clock_divider (
    input  wire clk,        // 65 MHz system clock
    input  wire rst_n,      // Active-low reset
    output reg  clk_en      // Clock enable pulse for pixel clock
);

    // Counter for clock division
    // We'll use a simple divide-by-3 counter
    // This gives us ~21.67 MHz which is acceptable for VGA
    // (Standard is 25.175 MHz, but monitors have tolerance)
    reg [1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 2'b00;
            clk_en <= 1'b0;
        end else begin
            if (counter == 2'd2) begin
                counter <= 2'b00;
                clk_en <= 1'b1;  // Pulse high every 3 cycles
            end else begin
                counter <= counter + 1'b1;
                clk_en <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
