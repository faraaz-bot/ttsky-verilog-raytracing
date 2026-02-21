# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""
Image Capture Test for Ray Marching VGA Renderer
Captures full VGA frames and saves them as PPM images.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import os


class VGAFrameCapture:
    """Captures VGA output and saves as PPM image"""
    
    def __init__(self, width=640, height=480):
        self.width = width
        self.height = height
        self.pixels = []
        
    def add_pixel(self, r, g, b):
        """Add a pixel to the frame"""
        r8 = (r * 255) // 7  # 3-bit to 8-bit
        g8 = (g * 255) // 7
        b8 = (b * 255) // 3  # 2-bit to 8-bit
        self.pixels.append((r8, g8, b8))
        
    def save_ppm(self, filename):
        """Save captured frame as PPM image"""
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        with open(filename, 'w') as f:
            f.write('P3\n')
            f.write(f'{self.width} {self.height}\n')
            f.write('255\n')
            
            for i, (r, g, b) in enumerate(self.pixels):
                f.write(f'{r} {g} {b} ')
                if (i + 1) % self.width == 0:
                    f.write('\n')
        
        print(f"✓ Saved {len(self.pixels)} pixels to {filename}")


async def capture_frame(dut, mode, scene, frame_capture):
    """Capture a single VGA frame"""
    dut.ui_in.value = (scene << 2) | mode
    await ClockCycles(dut.clk, 100)
    
    # Wait for frame sync
    timeout = 0
    while dut.uo_out.value[1] == 1 and timeout < 100000:
        await RisingEdge(dut.clk)
        timeout += 1
    
    while dut.uo_out.value[1] == 0 and timeout < 100000:
        await RisingEdge(dut.clk)
        timeout += 1
    
    dut._log.info("Capturing frame...")
    
    # Capture pixels
    for _ in range(500000):
        await RisingEdge(dut.clk)
        
        hsync = int(dut.uo_out.value[0])
        vsync = int(dut.uo_out.value[1])
        r = (int(dut.uo_out.value) >> 2) & 0x7
        g = (int(dut.uo_out.value) >> 5) & 0x7
        b = int(dut.uio_out.value) & 0x3
        
        if hsync == 1 and vsync == 1:
            frame_capture.add_pixel(r, g, b)
        
        if len(frame_capture.pixels) >= 640 * 480:
            break
    
    while len(frame_capture.pixels) < 640 * 480:
        frame_capture.pixels.append((0, 0, 0))
    
    frame_capture.pixels = frame_capture.pixels[:640 * 480]


@cocotb.test()
async def capture_test_pattern(dut):
    """Capture test pattern"""
    dut._log.info("Capturing test pattern...")
    clock = Clock(dut.clk, 15.38, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    
    frame = VGAFrameCapture()
    await capture_frame(dut, mode=0, scene=0, frame_capture=frame)
    frame.save_ppm("output/test_pattern.ppm")


@cocotb.test()
async def capture_sphere(dut):
    """Capture sphere"""
    dut._log.info("Capturing sphere...")
    clock = Clock(dut.clk, 15.38, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    
    frame = VGAFrameCapture()
    await capture_frame(dut, mode=1, scene=0, frame_capture=frame)
    frame.save_ppm("output/sphere.ppm")


@cocotb.test()
async def capture_torus(dut):
    """Capture torus"""
    dut._log.info("Capturing torus...")
    clock = Clock(dut.clk, 15.38, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    
    frame = VGAFrameCapture()
    await capture_frame(dut, mode=1, scene=1, frame_capture=frame)
    frame.save_ppm("output/torus.ppm")


@cocotb.test()
async def capture_kirby(dut):
    """Capture Kirby"""
    dut._log.info("Capturing Kirby...")
    clock = Clock(dut.clk, 15.38, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    
    frame = VGAFrameCapture()
    await capture_frame(dut, mode=1, scene=2, frame_capture=frame)
    frame.save_ppm("output/kirby.ppm")


@cocotb.test()
async def capture_pokemon(dut):
    """Capture Pokemon"""
    dut._log.info("Capturing Pokemon...")
    clock = Clock(dut.clk, 15.38, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    
    frame = VGAFrameCapture()
    await capture_frame(dut, mode=1, scene=3, frame_capture=frame)
    frame.save_ppm("output/pokemon.ppm")
