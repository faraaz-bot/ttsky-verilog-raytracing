#!/usr/bin/env python3
"""
Convert PPM images to PNG using Python PIL/Pillow
No need for ImageMagick!
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow not installed!")
    print("Install with: pip install pillow")
    sys.exit(1)

def convert_ppm_to_png(ppm_file, png_file):
    """Convert a PPM file to PNG"""
    try:
        img = Image.open(ppm_file)
        img.save(png_file, 'PNG')
        print(f"✓ Converted {ppm_file} -> {png_file}")
        return True
    except Exception as e:
        print(f"✗ Error converting {ppm_file}: {e}")
        return False

def main():
    output_dir = Path(__file__).parent / 'output'
    
    if not output_dir.exists():
        print(f"Error: {output_dir} does not exist!")
        sys.exit(1)
    
    # Find all PPM files
    ppm_files = list(output_dir.glob('*.ppm'))
    
    if not ppm_files:
        print("No PPM files found in output/")
        sys.exit(1)
    
    print(f"Found {len(ppm_files)} PPM files")
    print("Converting to PNG...\n")
    
    converted = 0
    for ppm_file in sorted(ppm_files):
        png_file = ppm_file.with_suffix('.png')
        if convert_ppm_to_png(ppm_file, png_file):
            converted += 1
    
    print(f"\n✓ Converted {converted}/{len(ppm_files)} images to PNG")
    print(f"\nOutput files in {output_dir}:")
    
    # List PNG files
    for png_file in sorted(output_dir.glob('*.png')):
        size = png_file.stat().st_size / 1024
        print(f"  {png_file.name} ({size:.1f} KB)")
    
    print("\nTo view:")
    print("  cd test/output")
    print("  eog *.png")
    print("\nOr download to your local machine:")
    print(f"  scp user@server:{output_dir.absolute()}/*.png .")

if __name__ == '__main__':
    main()
