/*
 * VGA Controller - 640x480 @ 60Hz
 * 
 * Generates VGA timing signals and manages pixel coordinates
 * Pixel clock: ~21.67 MHz (from 65MHz/3)
 * 
 * Standard VGA 640x480@60Hz timing:
 * Horizontal: 640 visible + 16 front porch + 96 sync + 48 back porch = 800 total
 * Vertical: 480 visible + 10 front porch + 2 sync + 33 back porch = 525 total
 * 
 * Outputs 3-3-2 RGB color encoding (256 colors)
 */

`default_nettype none

module vga_controller (
    input  wire       clk,          // System clock (65 MHz)
    input  wire       rst_n,        // Active-low reset
    input  wire       clk_en,       // Pixel clock enable (~21.67 MHz)
    
    // Color input from rendering pipeline
    input  wire [2:0] pixel_r,      // Red channel (3 bits)
    input  wire [2:0] pixel_g,      // Green channel (3 bits)
    input  wire [1:0] pixel_b,      // Blue channel (2 bits)
    
    // VGA outputs
    output reg        hsync,        // Horizontal sync
    output reg        vsync,        // Vertical sync
    output reg  [2:0] vga_r,        // Red output
    output reg  [2:0] vga_g,        // Green output
    output reg  [1:0] vga_b,        // Blue output
    
    // Pixel coordinates for rendering
    output reg  [9:0] pixel_x,      // Current X coordinate (0-639)
    output reg  [9:0] pixel_y,      // Current Y coordinate (0-479)
    output reg        video_active, // High during visible area
    output reg        frame_sync    // Pulse at start of each frame
);

    // VGA timing constants for 640x480@60Hz
    localparam H_VISIBLE    = 10'd640;
    localparam H_FRONT      = 10'd16;
    localparam H_SYNC       = 10'd96;
    localparam H_BACK       = 10'd48;
    localparam H_TOTAL      = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800
    
    localparam V_VISIBLE    = 10'd480;
    localparam V_FRONT      = 10'd10;
    localparam V_SYNC       = 10'd2;
    localparam V_BACK       = 10'd33;
    localparam V_TOTAL      = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525
    
    // Horizontal and vertical counters
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    // Sync pulse boundaries
    wire h_sync_start = (h_count == (H_VISIBLE + H_FRONT));
    wire h_sync_end   = (h_count == (H_VISIBLE + H_FRONT + H_SYNC));
    wire v_sync_start = (v_count == (V_VISIBLE + V_FRONT));
    wire v_sync_end   = (v_count == (V_VISIBLE + V_FRONT + V_SYNC));
    
    // Visible area detection
    wire h_visible = (h_count < H_VISIBLE);
    wire v_visible = (v_count < V_VISIBLE);
    
    // Horizontal counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
        end else if (clk_en) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end
    
    // Vertical counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_count <= 10'd0;
        end else if (clk_en) begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end
        end
    end
    
    // Generate sync signals (negative polarity for VGA)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else if (clk_en) begin
            // Horizontal sync
            if (h_sync_start) begin
                hsync <= 1'b0;
            end else if (h_sync_end) begin
                hsync <= 1'b1;
            end
            
            // Vertical sync
            if (v_sync_start) begin
                vsync <= 1'b0;
            end else if (v_sync_end) begin
                vsync <= 1'b1;
            end
        end
    end
    
    // Generate pixel coordinates and video_active signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
            video_active <= 1'b0;
        end else if (clk_en) begin
            pixel_x <= h_count;
            pixel_y <= v_count;
            video_active <= h_visible && v_visible;
        end
    end
    
    // Generate frame sync pulse (at start of visible area)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_sync <= 1'b0;
        end else if (clk_en) begin
            frame_sync <= (h_count == 10'd0) && (v_count == 10'd0);
        end
    end
    
    // Output RGB values (blanked during non-visible periods)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vga_r <= 3'b000;
            vga_g <= 3'b000;
            vga_b <= 2'b00;
        end else if (clk_en) begin
            if (video_active) begin
                vga_r <= pixel_r;
                vga_g <= pixel_g;
                vga_b <= pixel_b;
            end else begin
                // Blank during sync/porch periods
                vga_r <= 3'b000;
                vga_g <= 3'b000;
                vga_b <= 2'b00;
            end
        end
    end

endmodule

`default_nettype wire
