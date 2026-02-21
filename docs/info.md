<!---
Hardware Ray Marching VGA Renderer - TinyTapeout Project
-->

## How it works

This project implements a real-time 3D ray marching renderer that outputs to a VGA display. It renders animated 3D scenes using signed distance functions (SDFs) and displays them at 640x480 resolution with 256 colors (3-3-2 RGB encoding).

### Key Features

- **Ray Marching Engine**: Implements sphere tracing algorithm to render 3D scenes
- **CORDIC-Based Math**: Uses only shifts and adds (no multiplications!) inspired by [a1k0n's Tiny Tapeout donut](https://www.a1k0n.net/2025/01/10/tiny-tapeout-donut.html)
- **Multiple Scenes**: Sphere, torus (donut), Kirby-like character, and Pokemon-style character
- **Animated Camera**: Slowly rotating camera using Minsky circle algorithm (HAKMEM 149)
- **Real-time Lighting**: Lambertian diffuse shading with ambient occlusion
- **VGA Output**: 640x480@60Hz with 3-3-2 RGB color (256 colors)

### Architecture

The design consists of several key modules:

1. **VGA Controller** (`vga_controller.v`): Generates VGA timing signals for 640x480@60Hz
2. **Clock Divider** (`clock_divider.v`): Divides 65MHz system clock to ~21.67MHz pixel clock
3. **Fixed-Point Math** (`fixed_point_math.v`): Q8.8 arithmetic using CORDIC algorithm
4. **SDF Evaluator** (`sdf_evaluator.v`): Evaluates signed distance functions for 3D primitives
5. **Ray Marcher** (`ray_marcher.v`): Main rendering engine that marches rays through the scene
6. **Lighting** (`lighting.v`): Computes shading using CORDIC-based dot product
7. **Top Module** (`tt_um_raymarcher.v`): Integrates all components with camera rotation

### Technical Details

**Fixed-Point Format**: Q8.8 (8 integer bits, 8 fractional bits)
- Range: -128.0 to +127.996
- Precision: 1/256 ≈ 0.0039

**CORDIC Algorithm**: 
- Vectoring mode computes vector length AND dot product simultaneously
- Uses only shifts and adds - no multiplications needed
- 3-4 iterations provide sufficient accuracy while meeting timing constraints

**Ray Marching**:
- Maximum 16 steps per ray
- Hit threshold: 0.0625 units
- Maximum distance: 10.0 units

**Camera Animation**:
- Minsky circle algorithm rotates camera position
- Orbits at radius 5.0 around scene center
- Smooth rotation without trigonometric functions

### Rendering Pipeline

```
Pixel Coordinates → Ray Generation → Ray Marching Loop → SDF Evaluation → 
Lighting Calculation → 3-3-2 RGB Output → VGA Display
```

Each pixel is rendered in real-time as the VGA beam scans across the screen. The limited number of ray marching iterations creates a faceted, low-poly aesthetic similar to early 3D graphics.

## How to test

### Input Controls

The design uses the 8 dedicated input pins (`ui_in[7:0]`) for control:

- **ui_in[1:0]**: Display mode selection
  - `00`: Test pattern (color gradient)
  - `01`: Ray marched 3D scene
  - `10`: Debug mode (shows camera rotation)
  - `11`: Solid color test
  
- **ui_in[3:2]**: Scene selection (when in ray marching mode)
  - `00`: Simple sphere
  - `01`: Torus (donut)
  - `10`: Kirby-like character
  - `11`: Pokemon-style character (Pikachu)
  
- **ui_in[4]**: Animation enable
  - `0`: Camera static
  - `1`: Camera rotates around scene

- **ui_in[7:5]**: Reserved for future use

### VGA Output Pins

**Dedicated Outputs** (`uo_out[7:0]`):
- `uo_out[0]`: HSYNC (horizontal sync)
- `uo_out[1]`: VSYNC (vertical sync)
- `uo_out[4:2]`: Red channel (3 bits)
- `uo_out[7:5]`: Green channel (3 bits)

**Bidirectional I/O** (`uio_out[7:0]`):
- `uio_out[1:0]`: Blue channel (2 bits)
- `uio_out[2]`: Frame sync (debug)
- `uio_out[3]`: Video active (debug)
- `uio_out[7:4]`: Unused

### Testing Procedure

1. **Power on**: Set `rst_n` high, provide 65MHz clock
2. **Test pattern**: Set `ui_in[1:0] = 00` to verify VGA output with color gradient
3. **Static scene**: Set `ui_in[1:0] = 01`, `ui_in[4] = 0` to see a static 3D sphere
4. **Animated scene**: Set `ui_in[4] = 1` to enable camera rotation
5. **Scene selection**: Change `ui_in[3:2]` to switch between different 3D models
6. **Debug mode**: Set `ui_in[1:0] = 10` to visualize camera rotation values

### Expected Output

- **Test Pattern Mode**: Smooth color gradient across the screen
- **Ray Marching Mode**: 3D rendered object with shading, rotating slowly
- **Debug Mode**: Color changes as camera rotates (visualizes sin/cos values)

The rendering will have a faceted, low-polygon appearance due to the limited number of CORDIC iterations (3 for major radius, 2 for minor radius), creating an aesthetic similar to early 3D games.

## External hardware

### Required Hardware

- **VGA Monitor**: Standard VGA display (supports 640x480@60Hz)
- **VGA Connector**: DB15 connector or VGA PMOD
- **Resistor DAC**: For converting digital RGB to analog VGA levels

### VGA Connection

The design outputs 3-3-2 RGB digital signals that need to be converted to analog VGA levels (0-0.7V):

**Recommended Resistor DAC**:
- Red (3 bits): R-2R ladder or simple resistor divider (e.g., 470Ω, 1kΩ, 2.2kΩ)
- Green (3 bits): Same as red
- Blue (2 bits): R-2R ladder or resistor divider (e.g., 470Ω, 1kΩ)

**Pin Connections**:
```
TinyTapeout → VGA DB15
uo_out[0]   → Pin 13 (HSYNC)
uo_out[1]   → Pin 14 (VSYNC)
uo_out[4:2] → Pin 1  (Red) via DAC
uo_out[7:5] → Pin 2  (Green) via DAC
uio_out[1:0]→ Pin 3  (Blue) via DAC
GND         → Pin 5, 6, 7, 8, 10 (Ground)
```

### Alternative: VGA PMOD

A VGA PMOD board (like Digilent VGA PMOD) can be used directly, which includes the necessary resistor DAC circuitry.

### Power Requirements

- Supply voltage: 3.3V or 5V (depending on TinyTapeout configuration)
- Current: ~50mA typical
- Clock: 65MHz (provided by TinyTapeout)

### Performance Notes

- Pixel clock: ~21.67 MHz (65MHz ÷ 3)
- Frame rate: ~60 FPS
- Resolution: 640x480 pixels
- Color depth: 8 bits (256 colors)
- Rendering time: ~46ns per pixel (limited ray marching iterations)

The design prioritizes real-time performance over rendering quality, creating a unique retro aesthetic that showcases the capabilities of hardware-accelerated ray marching on a tiny ASIC.
