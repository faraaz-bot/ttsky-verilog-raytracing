/*
 * Combinatorial SDF Evaluator
 * Based on a1k0n's approach - purely combinatorial, no registers
 * 
 * Evaluates torus SDF in a single clock cycle using combinatorial CORDIC
 */

`default_nettype none

module sdf_torus_comb (
    input signed [15:0] px,      // Point position
    input signed [15:0] py,
    input signed [15:0] pz,
    input signed [15:0] lx,      // Light direction
    input signed [15:0] ly,
    input signed [15:0] lz,
    output wire hit,             // Hit flag
    output wire signed [15:0] light  // Light intensity
);

    // Torus parameters (Q8.8 format)
    parameter R1 = 16'h0100;  // Major radius: 1.0
    parameter R2 = 16'h0200;  // Minor radius: 2.0
    
    // Step 1: Distance to center ring in XZ plane (3-step CORDIC)
    wire [15:0] t0;
    wire signed [15:0] step1_lx;
    
    cordic3step cordic_xy (
        .xin(px),
        .yin(pz),
        .x2in(lx),
        .y2in(lz),
        .length(t0),
        .x2out(step1_lx)
    );
    
    // Distance from center ring
    wire signed [15:0] t1 = t0 - R2;
    
    // Step 2: Distance in cross-section (2-step CORDIC)
    wire [15:0] t2;
    wire signed [15:0] step2_lz;
    
    cordic2step cordic_xz (
        .xin(py),
        .yin(t1),
        .x2in(ly),
        .y2in(step1_lx),
        .length(t2),
        .x2out(step2_lz)
    );
    
    // Final distance
    wire signed [15:0] d = t2 - R1;
    
    // Hit test (distance < threshold)
    assign hit = (d < 16'h0080);  // Threshold: 0.5
    
    // Light intensity (from CORDIC auxiliary vector)
    // Clamp to positive values
    assign light = step2_lz[15] ? 16'h0000 : step2_lz;

endmodule

// Simplified sphere SDF (combinatorial)
module sdf_sphere_comb (
    input signed [15:0] px,
    input signed [15:0] py,
    input signed [15:0] pz,
    input signed [15:0] lx,
    input signed [15:0] ly,
    input signed [15:0] lz,
    output wire hit,
    output wire signed [15:0] light
);

    parameter RADIUS = 16'h0200;  // 2.0
    
    // Distance from origin using 3-step CORDIC
    wire [15:0] dist_xy;
    wire signed [15:0] light_xy;
    
    cordic3step cordic1 (
        .xin(px),
        .yin(py),
        .x2in(lx),
        .y2in(ly),
        .length(dist_xy),
        .x2out(light_xy)
    );
    
    // Final distance including Z
    wire [15:0] dist_total;
    wire signed [15:0] light_total;
    
    cordic2step cordic2 (
        .xin(pz),
        .yin(dist_xy),
        .x2in(lz),
        .y2in(light_xy),
        .length(dist_total),
        .x2out(light_total)
    );
    
    wire signed [15:0] d = dist_total - RADIUS;
    
    assign hit = (d < 16'h0080);
    assign light = light_total[15] ? 16'h0000 : light_total;

endmodule

`default_nettype wire
