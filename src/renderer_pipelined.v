/*
 * Pipelined Real-time Renderer
 * Based on a1k0n's pipelining strategy
 * 
 * Key insight: Start computing pixel N when displaying pixel N-3
 * With 3 clock cycles per pixel, the result is ready just in time!
 */

`default_nettype none

module renderer_pipelined (
    input wire clk,
    input wire rst_n,
    input wire [10:0] h_count,      // Horizontal counter
    input wire [9:0] v_count,       // Vertical counter
    input wire [1:0] scene_select,
    input wire [15:0] cam_angle,
    output reg hit,                 // Object visible
    output reg [5:0] luma           // Light intensity (6-bit)
);

    // VGA timing (must match vga_controller)
    parameter H_DISPLAY = 640;
    
    // Camera and light setup
    // Fixed camera at (0, 0, -5)
    wire signed [15:0] cam_x = 16'h0000;
    wire signed [15:0] cam_y = 16'h0000;
    wire signed [15:0] cam_z = 16'hFB00;  // -5.0
    
    // Fixed light direction (from top-right)
    wire signed [15:0] light_x = 16'h00B5;  // 0.707
    wire signed [15:0] light_y = 16'h00B5;  // 0.707
    wire signed [15:0] light_z = 16'h0000;
    
    // Convert screen coordinates to ray
    // Center at (320, 240), scale to normalized coords
    wire signed [15:0] screen_x = {5'b0, h_count} - 16'd320;
    wire signed [15:0] screen_y = 16'd240 - {6'b0, v_count};
    
    // Ray origin (camera position)
    wire signed [15:0] ray_ox = cam_x;
    wire signed [15:0] ray_oy = cam_y;
    wire signed [15:0] ray_oz = cam_z;
    
    // Ray direction (normalized screen coords + forward)
    wire signed [15:0] ray_dx = screen_x >>> 2;  // Scale down
    wire signed [15:0] ray_dy = screen_y >>> 2;
    wire signed [15:0] ray_dz = 16'h0100;  // 1.0 forward
    
    // SIMPLIFIED FOR DEBUGGING: Just render based on screen distance from center
    // This will show a circle if the logic works
    
    // Distance from screen center (Manhattan distance)
    wire [10:0] dx_abs = screen_x[15] ? -screen_x[10:0] : screen_x[10:0];
    wire [10:0] dy_abs = screen_y[15] ? -screen_y[10:0] : screen_y[10:0];
    wire [11:0] screen_dist = dx_abs + dy_abs;
    
    // Simple hit test: inside circle of radius ~200 pixels
    wire hit_comb = (screen_dist < 12'd200);
    
    // Simple lighting: gradient based on distance
    wire [5:0] light_6bit = hit_comb ? (6'd63 - screen_dist[7:2]) : 6'd0;
    wire signed [15:0] light_comb = {10'b0, light_6bit};
    
    // Pipeline registers - delay by 3 cycles to match pixel timing
    reg hit_pipe1, hit_pipe2, hit_pipe3;
    reg [5:0] luma_pipe1, luma_pipe2, luma_pipe3;
    
    // NO PIPELINE - Just output directly for debugging
    always @(*) begin
        hit = hit_comb;
        luma = light_6bit;
    end

endmodule

`default_nettype wire
