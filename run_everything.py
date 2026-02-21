#!/usr/bin/env python3
"""
One-Click Ray Marching VGA Renderer
Runs simulation, captures images, converts to PNG, and opens viewer

Usage: python3 run_everything.py
"""

import subprocess
import sys
import os
from pathlib import Path

def run_command(cmd, description):
    """Run a command and show progress"""
    print(f"\n{'='*60}")
    print(f"  {description}")
    print(f"{'='*60}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Failed: {description}")
        print(result.stderr[-500:] if len(result.stderr) > 500 else result.stderr)
        return False
    print(f"✓ {description} complete")
    return True

def main():
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║  Hardware Ray Marching VGA Renderer                      ║
    ║  Pipelined CORDIC Ray Marching                           ║
    ╚══════════════════════════════════════════════════════════╝
    """)
    
    # Activate virtual environment if not already active
    if not os.environ.get('VIRTUAL_ENV'):
        venv_activate = Path(__file__).parent / 'venv' / 'bin' / 'activate'
        if venv_activate.exists():
            print("⚠ Virtual environment not activated")
            print("Please run: source venv/bin/activate")
            print("Then run this script again\n")
            return 1
    
    # Change to test directory
    test_dir = Path(__file__).parent / 'test'
    os.chdir(test_dir)
    
    print(f"Working directory: {os.getcwd()}\n")
    
    # Check if images already exist
    output_dir = Path('output')
    png_files = list(output_dir.glob('*.png')) if output_dir.exists() else []
    
    if len(png_files) >= 5:
        print(f"✓ Found {len(png_files)} existing PNG images\n")
        print("Options:")
        print("  1. View existing images (fast)")
        print("  2. Regenerate from scratch (takes ~3 minutes)")
        print()
        choice = input("Enter choice (1 or 2): ").strip()
        
        if choice == '2':
            print("\n🔄 Regenerating images from scratch...")
            # Delete old images
            for f in output_dir.glob('*.png'):
                f.unlink()
            for f in output_dir.glob('*.ppm'):
                f.unlink()
            regenerate = True
        else:
            print("\n✓ Using existing images")
            regenerate = False
    else:
        print("No existing images found. Will generate new ones.\n")
        regenerate = True
    
    if regenerate:
        # Run simulation
        print("\n⏳ Running Verilog simulation...")
        print("   This will take approximately 3 minutes")
        print("   Capturing 5 scenes with pipelined CORDIC renderer\n")
        
        if not run_command(
            "COCOTB_TEST_MODULES=capture_images make",
            "Simulating VGA output and capturing frames"
        ):
            print("\n❌ Simulation failed")
            print("Make sure you're in the virtual environment:")
            print("   source venv/bin/activate")
            return 1
        
        # Convert to PNG
        if not run_command(
            "python3 convert_to_png.py",
            "Converting PPM to PNG"
        ):
            return 1
    
    # List generated images
    print(f"\n{'='*60}")
    print("  Your Rendered Images")
    print(f"{'='*60}")
    
    png_files = sorted(output_dir.glob('*.png'))
    for png in png_files:
        size = png.stat().st_size / 1024
        print(f"  ✓ {png.name:20s} ({size:6.1f} KB)")
    
    # Start web server
    print(f"\n{'='*60}")
    print("  Starting Web Server")
    print(f"{'='*60}\n")
    
    import socket
    hostname = socket.gethostname()
    
    print("🌐 View your rendered images at:")
    print(f"   → http://localhost:8000/view_images.html")
    print(f"   → http://{hostname}:8000/view_images.html")
    print()
    print("📥 Or download to your local machine:")
    print(f"   scp {os.getenv('USER')}@{hostname}:{output_dir.absolute()}/*.png .")
    print()
    print("Press Ctrl+C to stop the server\n")
    
    try:
        subprocess.run(["python3", "-m", "http.server", "8000"])
    except KeyboardInterrupt:
        print("\n\n✓ Server stopped")
        print(f"Your images are in: {output_dir.absolute()}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
