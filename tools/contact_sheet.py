"""Tile screenshots into one image for quick review: python tools/contact_sheet.py out.png a.png b.png ..."""
import sys
from PIL import Image
out, files = sys.argv[1], sys.argv[2:]
w, h = 640, 360
cols = 2
rows = (len(files) + cols - 1) // cols
sheet = Image.new('RGB', (w * cols, h * rows), (20, 20, 20))
for i, f in enumerate(files):
    sheet.paste(Image.open(f).convert('RGB').resize((w, h), Image.LANCZOS), ((i % cols) * w, (i // cols) * h))
sheet.save(out)
