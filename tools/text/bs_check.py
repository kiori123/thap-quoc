"""Check rewritten Bạch Sơn lines (Mã<TAB>câu) against what the game has (ban_goc.json) before importing them.

  python tools/text/bs_check.py <file> [<file>...]

Flags: a code the game does not have; a code given twice; %s / %d placeholders changed; [Tên] changed; the old place
name; long dashes; over the length limit for its kind; a line that has little in common with the one it replaces (a
code mapped to the wrong line); a gendered word near the protagonist. Prints how many lines change.
"""
import difflib
import json
import os
import re
import sys

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'docs', 'xuat', 'bach_son_viet_lai')
LIMIT = {'thoại': 150, 'lựa chọn': 55, 'nút tương tác': 24, 'nút tương tác (trong thành)': 24, 'việc cần làm': 60,
         'thẻ chương / thời gian': 40, 'thông báo': 80}
GENDER = re.compile(r'\b(cậu ta|cô ta|anh ta|chị ta|thằng bé|con bé|cậu bé|cô bé)\b', re.I)


def load(files):
    rows = []
    for f in files:
        for line in open(f, encoding='utf-8'):
            m = re.match(r'\s*(B[SX]-\d+[a-z]?)\s(.*)$', line.rstrip('\n'))
            if m:
                rows.append((m.group(1), m.group(2).lstrip(' \t') if not m.group(2).startswith(' ') else m.group(2).lstrip('\t')))
    return rows


def main():
    items = {it['code']: it for it in json.load(open(os.path.join(OUT, 'ban_goc.json'), encoding='utf-8'))}
    rows = load(sys.argv[1:])
    seen = {}
    changed = 0
    problems = []
    for code, new in rows:
        it = items.get(code)
        if not it:
            problems.append('%s: không có mã này trong game' % code)
            continue
        if code in seen:
            problems.append('%s: có hai lần' % code)
        seen[code] = new
        old = it['text'].replace('\\"', '"')
        if new == old:
            continue
        changed += 1
        for ph in ('%s', '%d', '[Tên]'):
            if old.count(ph) != new.count(ph):
                problems.append('%s: chỗ giữ chỗ %s đổi (%d -> %d) | %s' % (code, ph, old.count(ph), new.count(ph), new))
        if old.endswith(' ') != new.endswith(' '):
            problems.append('%s: khoảng trắng cuối đổi | "%s"' % (code, new))
        if 'Lũng Giữa' in new:
            problems.append('%s: còn tên cũ' % code)
        if '—' in new or '–' in new:
            problems.append('%s: gạch ngang dài' % code)
        lim = LIMIT.get(it['kind'])
        if lim and len(new) > lim:
            problems.append('%s: dài %d > %d (%s)' % (code, len(new), lim, it['kind']))
        r = difflib.SequenceMatcher(None, old.lower(), new.lower()).ratio()
        if r < 0.35 and len(old) > 3:
            problems.append('%s: khác hẳn câu cũ (%.2f) | cũ: %s | mới: %s' % (code, r, old, new))
        if GENDER.search(new) and it['speaker'] != '[Tên]':
            problems.append('%s: có từ chỉ giới, xem có nói về nhân vật chính không | %s' % (code, new))
    print('nhận %d mã, đổi %d câu' % (len(rows), changed))
    for p in problems:
        print('  !', p)


if __name__ == '__main__':
    main()
