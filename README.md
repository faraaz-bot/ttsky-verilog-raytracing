# Hardware Ray Marching VGA Renderer

Real-time 3D ray marching renderer for VGA displays using pipelined CORDIC algorithm.

## Quick Start

```bash
# View rendered images
python3 run_everything.py
```

Then open `http://localhost:8000/view_images.html` in your browser!

## What This Does

Renders 3D scenes to VGA displays using:
- **Ray marching** with signed distance functions
- **Pipelined CORDIC** (shifts and adds only - no multiplications!)
- **Real-time rendering** at 640x480@60Hz with 256 colors

Based on [a1k0n's Tiny Tapeout donut](https://www.a1k0n.net/2025/01/10/tiny-tapeout-donut.html).

## Project Structure

```
├── src/                      # Verilog source (6 modules)
│   ├── tt_um_raymarcher.v   # Top module
│   ├── vga_controller.v     # VGA timing
│   ├── clock_divider.v      # Clock division
│   ├── cordic_comb.v        # Combinatorial CORDIC
│   ├── sdf_comb.v           # SDF evaluators
│   └── renderer_pipelined.v # Pipelined renderer
├── test/
│   ├── output/              # Rendered images (PNG)
│   ├── test.py              # Basic tests
│   ├── convert_to_png.py    # Image converter
│   └── view_images.html     # Web viewer
├── docs/
│   └── info.md              # Technical documentation
├── run_everything.py        # One-click runner
└── info.yaml                # TinyTapeout config
```

## Features

- ✅ **Pipelined CORDIC** - 3-cycle pipeline matches VGA timing
- ✅ **Multiple scenes** - Sphere, torus, Kirby, Pokemon
- ✅ **256 colors** - 3-3-2 RGB encoding
- ✅ **Real-time** - 60 FPS at 640x480
- ✅ **No multiplications** - Only shifts and adds

## Usage

### View Rendered Images

```bash
python3 run_everything.py
```

### Run Tests

```bash
source venv/bin/activate
cd test
make
```

### Input Controls

- `ui_in[1:0]`: Display mode (00=test pattern, 01=ray march, 10=debug, 11=solid)
- `ui_in[3:2]`: Scene (00=sphere, 01=torus, 10=Kirby, 11=Pokemon)
- `ui_in[4]`: Animation enable

### VGA Output

- `uo_out[0]`: HSYNC
- `uo_out[1]`: VSYNC
- `uo_out[4:2]`: Red (3 bits)
- `uo_out[7:5]`: Green (3 bits)
- `uio_out[1:0]`: Blue (2 bits)

## Technical Details

- **Clock**: 65 MHz
- **Pixel Clock**: ~21.67 MHz (÷3)
- **Resolution**: 640x480
- **Color Depth**: 8-bit (256 colors)
- **CORDIC**: 3-step + 2-step (combinatorial)
- **Pipeline**: 3 cycles per pixel
- **Tile Size**: 2x2

## How It Works

1. **Combinatorial CORDIC** computes distance/lighting in 1 cycle
2. **3-stage pipeline** delays result to match VGA timing
3. **VGA controller** outputs pixel at exactly the right time
4. Creates **faceted aesthetic** from limited CORDIC iterations

## Documentation

- **docs/info.md** - Complete technical documentation
- **test/README.md** - Testing guide
- **run_everything.py** - Automated runner

## License

Apache 2.0

## Author

Created for IC Hackathon 2025 - ASIC Track
