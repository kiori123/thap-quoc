"""Contact sheets from tools/video_qc.py thumbnails: t_*.png in time order, 6 x 5 to a sheet, each stamped with its time.

  python tools/video_sheets.py <qc_dir> [prefix]
"""
import glob
import os
import sys

from PIL import Image, ImageDraw


def main():
    d = sys.argv[1]
    pre = sys.argv[2] if len(sys.argv) > 2 else 't_'
    fs = sorted(glob.glob(os.path.join(d, 'thumbs', pre + '*.png')))
    cols, rows = 6, 5
    w, h = 320, 180
    for s in range(0, len(fs), cols * rows):
        sheet = Image.new('RGB', (cols * w, rows * h), (0, 0, 0))
        dr = ImageDraw.Draw(sheet)
        for k, f in enumerate(fs[s:s + cols * rows]):
            im = Image.open(f).convert('RGB').resize((w, h))
            x, y = (k % cols) * w, (k // cols) * h
            sheet.paste(im, (x, y))
            dr.rectangle((x, y, x + 74, y + 13), fill=(0, 0, 0))
            dr.text((x + 3, y + 1), os.path.basename(f)[len(pre):-4], fill=(255, 220, 80))
        out = os.path.join(d, 'sheet_%s%02d.png' % (pre, s // (cols * rows)))
        sheet.save(out)
        print(out)


if __name__ == '__main__':
    main()
