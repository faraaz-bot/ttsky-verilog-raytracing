/*
 * Combinatorial CORDIC Modules
 * Based on a1k0n's tt08-vga-donut implementation
 * 
 * Purely combinatorial (no registers) - completes in 1 clock cycle
 * Creates faceted aesthetic with limited iterations
 */

`default_nettype none

// 3-step CORDIC for first distance calculation (r1)
module cordic3step (
    input signed [15:0] xin,
    input signed [15:0] yin,
    input signed [15:0] x2in,   // Auxiliary vector for lighting
    input signed [15:0] y2in,
    output [15:0] length,
    output signed [15:0] x2out
);

    // Compute sums early for muxing
    wire signed [15:0] xplusy = xin + yin;
    wire signed [15:0] yminusx = yin - xin;
    wire signed [15:0] x2plusy2 = x2in + y2in;
    wire signed [15:0] y2minusx2 = y2in - x2in;
    
    // Track x inversion separately
    wire xinvert = yin[15];
    wire parity_in = xin[15] ^ yin[15];
    
    // Step 1
    wire signed [15:0] step1x  = parity_in ? yminusx   : xplusy;
    wire signed [15:0] step1y  = parity_in ? xplusy    : yminusx;
    wire signed [15:0] step1x2 = parity_in ? y2minusx2 : x2plusy2;
    wire signed [15:0] step1y2 = parity_in ? x2plusy2  : y2minusx2;
    
    // Step 2
    wire signed [15:0] step2x  = (xinvert ? ~step1x : step1x) + (step1y[15] ? ~step1y>>>1 : step1y>>>1);
    wire signed [15:0] step2y  = step1y + (step1y[15]^xinvert ? step1x>>>1 : ~step1x>>>1);
    wire signed [15:0] step2x2 = (xinvert ? ~step1x2 : step1x2) + (step1y[15] ? ~step1y2>>>1 : step1y2>>>1);
    wire signed [15:0] step2y2 = step1y2 + (step1y[15]^xinvert ? step1x2>>>1 : ~step1x2>>>1);
    
    // Step 3
    wire signed [15:0] step3x  = step2x  + (step2y[15] ? ~step2y>>>2  : step2y>>>2);
    wire signed [15:0] step3x2 = step2x2 + (step2y[15] ? ~step2y2>>>2 : step2y2>>>2);
    
    // Scale output (compensate for CORDIC gain ~0.607)
    assign length = (step3x >>> 1) + (step3x >>> 3);  // Multiply by 0.625
    assign x2out = (step3x2 >>> 1) + (step3x2 >>> 3);

endmodule

// 2-step CORDIC for second distance calculation (r2)
module cordic2step (
    input signed [15:0] xin,
    input signed [15:0] yin,
    input signed [15:0] x2in,
    input signed [15:0] y2in,
    output [15:0] length,
    output signed [15:0] x2out
);

    wire signed [15:0] xplusy = xin + yin;
    wire signed [15:0] yminusx = yin - xin;
    wire signed [15:0] x2plusy2 = x2in + y2in;
    wire signed [15:0] y2minusx2 = y2in - x2in;
    
    wire xinvert = yin[15];
    wire parity_in = xin[15] ^ yin[15];
    
    // Step 1
    wire signed [15:0] step1x  = parity_in ? yminusx   : xplusy;
    wire signed [15:0] step1y  = parity_in ? xplusy    : yminusx;
    wire signed [15:0] step1x2 = parity_in ? y2minusx2 : x2plusy2;
    wire signed [15:0] step1y2 = parity_in ? x2plusy2  : y2minusx2;
    
    // Step 2
    wire signed [15:0] step2x  = (xinvert ? ~step1x : step1x) + (step1y[15] ? ~step1y>>>1 : step1y>>>1);
    wire signed [15:0] step2x2 = (xinvert ? ~step1x2 : step1x2) + (step1y[15] ? ~step1y2>>>1 : step1y2>>>1);
    
    // Scale output
    assign length = (step2x >>> 1) + (step2x >>> 3);
    assign x2out = (step2x2 >>> 1) + (step2x2 >>> 3);

endmodule

`default_nettype wire
