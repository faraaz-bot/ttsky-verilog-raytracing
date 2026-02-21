/*
 * TinyTapeout Ray Marching VGA Renderer
 * 
 * Top-level module integrating:
 * - VGA controller (640x480@60Hz, 3-3-2 RGB)
 * - Ray marching engine with SDF evaluation
 * - CORDIC-based math (shifts and adds only)
 * - Camera rotation using Minsky circle algorithm
 * - Real-time 3D rendering to VGA display
 * 
 * Inspired by a1k0n's Tiny Tapeout donut project
 */

`default_nettype none

module tt_um_raymarcher (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Always 1 when the design is powered
    input  wire       clk,      // 65 MHz clock
    input  wire       rst_n     // Active-low reset
);

    // ========================================
    // Input Mapping
    // ========================================
    wire [1:0] mode_select = ui_in[1:0];      // Display mode
    wire [1:0] scene_select = ui_in[3:2];     // Scene selection
    wire animation_enable = ui_in[4];         // Enable camera rotation
    
    // ========================================
    // Output Mapping (3-3-2 RGB VGA)
    // ========================================
    wire hsync, vsync;
    wire [2:0] vga_r, vga_g;
    wire [1:0] vga_b;
    
    assign uo_out[0] = hsync;
    assign uo_out[1] = vsync;
    assign uo_out[4:2] = vga_r;  // R[2:0]
    assign uo_out[7:5] = vga_g;  // G[2:0]
    
    assign uio_out[1:0] = vga_b;  // B[1:0]
    assign uio_out[2] = frame_sync;  // Debug: frame sync
    assign uio_out[3] = video_active; // Debug: pixel valid
    assign uio_out[7:4] = 4'b0000;    // Unused
    
    // Set bidirectional pins as outputs for VGA blue channel
    assign uio_oe = 8'b00001111;
    
    // ========================================
    // Clock Division
    // ========================================
    wire clk_en;  // Pixel clock enable (~21.67 MHz)
    
    clock_divider clk_div (
        .clk(clk),
        .rst_n(rst_n),
        .clk_en(clk_en)
    );
    
    // ========================================
    // VGA Controller
    // ========================================
    wire [9:0] pixel_x, pixel_y;
    wire video_active, frame_sync;
    wire [2:0] render_r, render_g;
    wire [1:0] render_b;
    
    vga_controller vga (
        .clk(clk),
        .rst_n(rst_n),
        .clk_en(clk_en),
        .pixel_r(render_r),
        .pixel_g(render_g),
        .pixel_b(render_b),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .frame_sync(frame_sync)
    );
    
    // ========================================
    // Camera Rotation (Minsky Circle Algorithm - HAKMEM 149)
    // ========================================
    reg [15:0] cam_cos, cam_sin;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cam_cos <= 16'h0100;  // 1.0
            cam_sin <= 16'h0000;  // 0.0
        end else if (frame_sync && animation_enable) begin
            // HAKMEM 149: x -= y>>s; y += x>>s
            cam_cos <= cam_cos - (cam_sin >>> 6);
            cam_sin <= cam_sin + (cam_cos >>> 6);
        end
    end
    
    // Camera position: orbit around origin
    // cam_x = 5.0 * cos(angle)
    // cam_z = 5.0 * sin(angle)
    // cam_y = 0.0 (fixed height)
    wire signed [31:0] cam_x_temp = $signed(cam_cos) * $signed(16'h0500);  // 5.0
    wire signed [31:0] cam_z_temp = $signed(cam_sin) * $signed(16'h0500);
    
    wire [15:0] cam_pos_x = cam_x_temp[23:8];  // Q8.8
    wire [15:0] cam_pos_y = 16'h0000;          // 0.0
    wire [15:0] cam_pos_z = cam_z_temp[23:8];  // Q8.8
    
    // ========================================
    // Rendering Mode Selection
    // ========================================
    reg [2:0] final_r, final_g;
    reg [1:0] final_b;
    
    // Mode 0: Test pattern (color gradient)
    // Mode 1: Ray marched scene
    // Mode 2: Wireframe/debug
    // Mode 3: Reserved
    
    wire [2:0] test_pattern_r = pixel_x[9:7];
    wire [2:0] test_pattern_g = pixel_y[8:6];
    wire [1:0] test_pattern_b = pixel_x[6:5];
    
    // Pipelined renderer output
    wire renderer_hit;
    wire [5:0] renderer_luma;
    
    renderer_pipelined renderer (
        .clk(clk),
        .rst_n(rst_n),
        .h_count({1'b0, pixel_x}),
        .v_count(pixel_y),
        .scene_select(scene_select),
        .cam_angle(16'h0000),
        .hit(renderer_hit),
        .luma(renderer_luma)
    );
    
    // Convert luma to RGB
    wire [2:0] raymarched_r = renderer_hit ? {renderer_luma[5:4], renderer_luma[5]} : 3'b001;
    wire [2:0] raymarched_g = renderer_hit ? {renderer_luma[5:4], renderer_luma[5]} : 3'b010;
    wire [1:0] raymarched_b = renderer_hit ? renderer_luma[5:4] : 2'b10;
    
    // Output multiplexer
    always @(*) begin
        case (mode_select)
            2'b00: begin  // Test pattern mode
                final_r = test_pattern_r;
                final_g = test_pattern_g;
                final_b = test_pattern_b;
            end
            
            2'b01: begin  // Ray marched scene (pipelined CORDIC)
                final_r = raymarched_r;
                final_g = raymarched_g;
                final_b = raymarched_b;
            end
            
            2'b10: begin  // Debug mode - show camera position
                final_r = cam_cos[10:8];
                final_g = cam_sin[10:8];
                final_b = 2'b11;
            end
            
            2'b11: begin  // Solid color test
                final_r = 3'b111;
                final_g = 3'b011;
                final_b = 2'b11;
            end
        endcase
    end
    
    assign render_r = final_r;
    assign render_g = final_g;
    assign render_b = final_b;
    
    // ========================================
    // Unused Input Handling
    // ========================================
    wire _unused = &{ena, ui_in[7:5], uio_in, 1'b0};

endmodule

`default_nettype wire
