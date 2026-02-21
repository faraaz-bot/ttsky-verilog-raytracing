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
    
    // Point along ray (simplified - just use screen position projected)
    wire signed [15:0] px = ray_dx;
    wire signed [15:0] py = ray_dy;
    wire signed [15:0] pz = 16'h0000;  // At origin
    
    // Combinatorial SDF evaluation
    wire hit_comb;
    wire signed [15:0] light_comb;
    
    // Select SDF based on scene
    generate
        if (1) begin : gen_torus
            sdf_torus_comb torus (
                .px(px),
                .py(py),
                .pz(pz),
                .lx(light_x),
                .ly(light_y),
                .lz(light_z),
                .hit(hit_comb),
                .light(light_comb)
            );
        end
    endgenerate
    
    // Pipeline registers - delay by 3 cycles to match pixel timing
    reg hit_pipe1, hit_pipe2, hit_pipe3;
    reg [5:0] luma_pipe1, luma_pipe2, luma_pipe3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit_pipe1 <= 1'b0;
            hit_pipe2 <= 1'b0;
            hit_pipe3 <= 1'b0;
            luma_pipe1 <= 6'b0;
            luma_pipe2 <= 6'b0;
            luma_pipe3 <= 6'b0;
            hit <= 1'b0;
            luma <= 6'b0;
        end else begin
            // Pipeline stage 1
            hit_pipe1 <= hit_comb;
            luma_pipe1 <= light_comb[13:8];  // Convert to 6-bit
            
            // Pipeline stage 2
            hit_pipe2 <= hit_pipe1;
            luma_pipe2 <= luma_pipe1;
            
            // Pipeline stage 3
            hit_pipe3 <= hit_pipe2;
            luma_pipe3 <= luma_pipe2;
            
            // Output (3 cycles delayed)
            hit <= hit_pipe3;
            luma <= luma_pipe3;
        end
    end

endmodule

`default_nettype wire
