"""After an import: carry the rewritten Bạch Sơn lines into the dialogue doc (§I) and the Codex standard, by code.

  python tools/text/bs_sync_docs.py <note for the standard> <file> [<file>...]

A row "| BS-xx | who | text |" gets its text cell replaced when the old line is in it; in the standard the cell is
tagged *[sửa]*. Rows that do not hold the old line as it was are listed for a look by hand. Line endings are kept.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'docs', 'xuat', 'bach_son_viet_lai')
DOC = os.path.join(ROOT, 'docs', 'xuat', 'loi_thoai_va_chu_trong_game.md')
CX = r'C:\Users\LAPTOP 5\Documents\Codex\2026-10-12\x\outputs\Thap_Quoc_ban_chuan_viet_hoa.md'


def changes(files):
    items = {it['code']: it for it in json.load(open(os.path.join(OUT, 'ban_goc.json'), encoding='utf-8'))}
    new = {}
    for f in files:
        for line in open(f, encoding='utf-8'):
            m = re.match(r'\s*(B[SX]-\d+[a-z]?)[\t ]+(.*)$', line.rstrip('\n'))
            if m and m.group(1) in items:
                new[m.group(1)] = m.group(2).strip()
    out = {}
    for c, t in new.items():
        old = items[c]['text'].replace('\\"', '"')
        if old.endswith(' ') and not t.endswith(' '):
            t += ' '
        if t != old:
            out[c] = (old, t)
    return out


def sync(path, ch, tag):
    raw = open(path, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in raw else '\n'
    lines = raw.split(nl)
    done, odd = [], []
    for i, line in enumerate(lines):
        m = re.match(r'\| (B[SX]-\d+[a-z]?)( \*\[[^\]]*\]\*)? \|', line)
        if not m or m.group(1) not in ch:
            continue
        old, new = ch[m.group(1)]
        cells = line.split('|')
        last = len(cells) - 2   # the text cell (the line ends with |)
        cell = cells[last]
        plain = re.sub(r'\*\[[^\]]*\]\*', '', cell).replace('*', '').strip()
        if old.strip() != plain and old.strip() not in plain:
            odd.append('%s: tài liệu ghi "%s", game cũ "%s"' % (m.group(1), plain[:70], old[:70]))
            continue
        cells[last] = ' ' + (tag + ' ' if tag else '') + new.strip() + ' '
        lines[i] = '|'.join(cells)
        done.append(m.group(1))
    open(path, 'w', encoding='utf-8', newline='').write(nl.join(lines))
    return done, odd


def main():
    note = sys.argv[1]
    ch = changes(sys.argv[2:])
    print(len(ch), 'câu đổi')
    d1, o1 = sync(DOC, ch, '')
    print('tài liệu thoại: thay', len(d1))
    for x in o1:
        print('  ?', x)
    d2, o2 = sync(CX, ch, '*[sửa]*')
    print('bản chuẩn: thay', len(d2))
    for x in o2:
        print('  ?', x)
    if note:
        raw = open(CX, encoding='utf-8', newline='').read()
        nl = '\r\n' if '\r\n' in raw else '\n'
        anchor = '**Cập nhật 2026-10-14, lần 14'
        assert raw.count(anchor) == 1
        raw = raw.replace(anchor, note + nl + nl + anchor, 1)
        open(CX, 'w', encoding='utf-8', newline='').write(raw)
    missing = sorted(c for c in ch if c not in d1 and c.startswith('BS-'))
    print('mã BS đổi mà tài liệu thoại không có dòng riêng:', missing)


if __name__ == '__main__':
    main()
