"""Bạch Sơn's text, out of the game and back in.

  python tools/text/bs_text.py export   -> docs/xuat/bach_son_viet_lai/ (the brief and every line for ChatGPT to rewrite,
                                           and ban_goc.json, what each code stands for and where it is)
  python tools/text/bs_text.py import <file>   -> puts the rewritten lines (a "Mã<TAB>Câu mới" block, as ChatGPT returns
                                           it) back into the scripts, each where it was; prints what it changed and what
                                           it could not place

Every string a player sees is taken straight from the scripts (not from the docs, which can lag): who says it, what
kind of text it is (a line, a choice, a card, an objective, a note in the Sổ ghi...), the scene it is in (the function
and its ## comment), and, where the dialogue doc has it, its BS code.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'docs', 'xuat', 'bach_son_viet_lai')
FILES = ['scripts/story/bach_son_story.gd', 'scripts/story/bach_son_city.gd', 'scripts/story/bach_son_palace.gd',
         'scripts/ui/journal.gd', 'scripts/ui/ash_test.gd', 'scripts/ui/bs_status.gd']
DOC = os.path.join(ROOT, 'docs', 'xuat', 'loi_thoai_va_chu_trong_game.md')
VN = re.compile('[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]', re.I)
STR = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
# calls whose strings are never shown to the player
TECH = {'shot', 'note', 'sfx', 'tex', 'shader', 'wav', 'preload', 'load', 'get', 'has', 'actor', 'npc', 'spawn', 'despawn',
        'set_time', '_go_level', 'play_music', 'get_meta', 'set_meta', 'has_meta', 'erase', 'append_flag', 'flag',
        'print', 'push_error', 'push_warning', 'find', 'begins_with', 'set_gate', 'see_through_wall', 'remove_interact',
        'move_to', 'face', 'face_point', 'set_pose', 'act', 'set_shader_parameter', 'tween_property', 'add_theme_color_override',
        'add_theme_font_size_override', 'add_theme_constant_override', 'add_theme_stylebox_override', 'set_markers',
        'card_texture', 'open_image', 'connect', 'emit_signal', 'call', 'has_node', 'get_node', 'go_trigger_id'}
KIND = {'say': 'thoại', 'card': 'thẻ chương / thời gian', 'name_card': 'thẻ tên', 'objective': 'việc cần làm',
        'toast': 'thông báo', 'choose': 'lựa chọn', 'add_interact': 'nút tương tác', 'go_interact': 'nút tương tác / việc cần làm',
        'go_trigger': 'việc cần làm', 'add_note': 'Sổ ghi', '_line': 'Sổ ghi (giao diện)', 'emote': 'chữ nổi trên đầu',
        'show_hints': 'gợi ý phím', 'message': 'dòng trận đánh', 'open': 'tiêu đề thẻ tranh', 'swap': 'tiêu đề thẻ tranh',
        'stamp': 'dấu đóng (Thử Tro)', 'note': 'chú thích thẻ tranh', 'set_text': 'chữ giao diện', 'append': 'lựa chọn'}


def _strings(src):
    out = []
    for m in STR.finditer(src):
        # skip strings inside comments
        ls = src.rfind('\n', 0, m.start()) + 1
        head = src[ls:m.start()]
        if '#' in head and head.count('"') % 2 == 0:
            continue
        out.append(m)
    return out


def _enclosing(src, pos):
    """The bracket that opens round pos, and its position."""
    depth = 0
    i = pos - 1
    in_str = False
    while i >= 0:
        c = src[i]
        if c == '"' and src[i - 1] != '\\':
            in_str = not in_str
        elif not in_str:
            if c in ')]}':
                depth += 1
            elif c in '([{':
                if depth == 0:
                    return c, i
                depth -= 1
        i -= 1
    return '', -1


def _args_before(src, open_pos, pos):
    """The top-level arguments between an opening bracket and pos (their source)."""
    args, depth, cur, in_str = [], 0, '', False
    for c in src[open_pos + 1:pos]:
        if c == '"':
            in_str = not in_str
        if not in_str:
            if c in '([{':
                depth += 1
            elif c in ')]}':
                depth -= 1
            elif c == ',' and depth == 0:
                args.append(cur)
                cur = ''
                continue
        cur += c
    args.append(cur)
    return args


def _call_name(src, open_pos):
    m = re.search(r'([A-Za-z_][A-Za-z_0-9]*)\s*$', src[:open_pos])
    return m.group(1) if m else ''


def _scene(lines, n):
    """The function line n is in, and its ## comment."""
    for k in range(n - 1, -1, -1):
        m = re.match(r'func ([A-Za-z_0-9]+)', lines[k])
        if m:
            doc = []
            j = k + 1
            while j < len(lines) and lines[j].strip().startswith('##'):
                doc.append(lines[j].strip()[2:].strip())
                j += 1
            return m.group(1), ' '.join(doc)
    return '', ''


def _shown(s):
    if not s.strip() or s.startswith('res://') or s.startswith('user://') or s.startswith('--'):
        return False
    if VN.search(s):
        return True
    if re.fullmatch(r'[a-z_0-9]+', s) or re.fullmatch(r'[A-Za-z_]+[0-9]*', s) and not re.fullmatch(r'[A-Z][a-z]+', s):
        return False
    return bool(re.search(r'[A-Za-z]{2,}', s))


def extract():
    consts = {}
    for f in FILES:
        for line in open(os.path.join(ROOT, f), encoding='utf-8'):
            m = re.match(r'const ([A-Z_]+) := "([^"]+)"', line)
            if m and not m.group(2).startswith('res://'):
                consts[m.group(1)] = m.group(2)
    entries = []
    for f in FILES:
        src = open(os.path.join(ROOT, f), encoding='utf-8').read()
        lines = src.split('\n')
        speakers_here = set(consts.values())
        for m in _strings(src):
            s = m.group(1)
            n = src.count('\n', 0, m.start()) + 1
            line = lines[n - 1]
            if re.match(r'\s*const [A-Z_]+ := "', line):
                continue
            if not _shown(s):
                continue
            br, op = _enclosing(src, m.start())
            call = _call_name(src, op) if br == '(' else ''
            if call in TECH:
                continue
            kind, spk = '', ''
            # a line of dialogue: say(speaker, text) or say(speaker, [alternatives]) or story.say
            target_call, target_open = call, op
            if br == '[':   # a list handed to a call: the call says what it is
                b2, o2 = _enclosing(src, op)
                if b2 == '(':
                    target_call, target_open = _call_name(src, o2), o2
                    if target_call in TECH:
                        continue
            if target_call == 'say':
                args = _args_before(src, target_open, m.start())
                if len(args) == 1 and target_open == op:
                    continue   # (the speaker's name itself)
                a0 = args[0].strip()
                if a0 in ('P()', 'story.P()'):
                    spk = '[Tên]'
                elif a0.startswith('"'):
                    ms = re.match(r'"([^"]*)"', a0)
                    spk = ms.group(1) or '(lời kể)'
                    if ' if ' in a0:
                        spk += ' (hoặc lời kể)'
                else:
                    spk = consts.get(a0.split('.')[-1], a0)
                kind = 'thoại'
            elif br == '[':
                # a [speaker, line] pair in a table of talk
                inner = src[op + 1:]
                pair = re.match(r'\s*"([^"]+)"\s*,\s*"', inner)
                if pair and pair.group(1) in speakers_here | {'Cỏ', 'Diệu', 'Mẹ Mạnh'} and len(pair.group(1)) < 20:
                    if m.start() == op + 1 + inner.index('"'):
                        speakers_here.add(s)
                        continue
                    spk, kind = pair.group(1), 'thoại'
            if not kind:
                c = target_call or call
                kind = KIND.get(c, '')
            if not kind:   # what a few tables of words are
                if re.search(r'const PARTS', line):
                    kind = 'buổi trong ngày (ghép vào thẻ "Ngày N · buổi")'
                elif re.search(r'const NUM', line):
                    kind = 'số đếm (ghép vào câu "%s đêm chui qua Cửa Cống...")'
                elif re.search(r'd\["[a-z_0-9]+"\] = \[', line):
                    kind = 'nút tương tác (trong thành)'
                elif re.search(r'\["[a-z_]+", "', line) and 'PAIRS' in src[:m.start()].rsplit('const ', 1)[-1][:10]:
                    kind = 'Sổ ghi: nhận ra'
                elif '"intro"' in line:
                    kind = 'dòng mở trận đánh'
                elif 'pendulum(' in src[max(0, m.start() - 200):m.start()]:
                    kind = 'chữ giao diện (Thử Tro: giữ tay yên)'
                elif 'opts' in line:
                    kind = 'lựa chọn'
                elif re.search(r'\.text = "', line):
                    kind = 'chữ giao diện'
                elif 'func open(caption' in line:
                    kind = 'tiêu đề thẻ tranh'
                elif 'Dinh Ty' in s and 'd[' in line:
                    kind = 'nút tương tác (trong thành)'
            if not kind and br == '{':
                vm = re.search(r'([A-Za-z_]+)\s*:?=\s*$', src[:op].rstrip())
                kind = {'LOOKS': 'xem đồ vật', 'NOTES': 'Sổ ghi: điều thấy', 'FINDINGS': 'Sổ ghi: điều thấy'}.get(vm.group(1) if vm else '', 'bảng chữ')
            if not kind:
                kind = 'chữ khác'
            fn, doc = _scene(lines, n)
            entries.append({'file': f, 'line': n, 'func': fn, 'scene': doc, 'speaker': spk, 'kind': kind, 'text': s,
                            'code': line.strip()[:200]})
    return entries


def _doc_codes():
    """BS codes from the dialogue doc: text -> code."""
    codes = {}
    for line in open(DOC, encoding='utf-8'):
        m = re.match(r'\| (BS-\d+[a-z]?) \| ([^|]*) \| (.*) \|\s*$', line)
        if m:
            t = m.group(3).strip()
            for part in [t] + [p.strip() for p in t.split(' / ') if len(p.strip()) > 12]:
                codes.setdefault(part.replace('\\"', '"'), m.group(1))
    return codes


def export():
    entries = extract()
    codes = _doc_codes()
    seen = {}
    items = []
    k = 0
    for e in entries:
        key = (e['speaker'], e['text'])
        if key in seen:
            seen[key]['where'].append('%s:%d' % (e['file'], e['line']))
            continue
        plain = e['text'].replace('\\"', '"')
        code = codes.get(plain)
        if code is None or any(it['code'] == code for it in items):
            k += 1
            code = 'BX-%03d' % k
        it = dict(e, code=code, where=['%s:%d' % (e['file'], e['line'])])
        seen[key] = it
        items.append(it)
    os.makedirs(OUT, exist_ok=True)
    json.dump(items, open(os.path.join(OUT, 'ban_goc.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import datetime
    import bs_brief
    print('viết', bs_brief.write(items, OUT, datetime.date.today().isoformat()))
    return items


def import_(*paths):
    items = {it['code']: it for it in json.load(open(os.path.join(OUT, 'ban_goc.json'), encoding='utf-8'))}
    new = {}
    for line in [l for path in paths for l in open(path, encoding='utf-8')]:
        m = re.match(r'\s*(B[SX]-\d+[a-z]?)[\t ]+(.*)$', line.rstrip('\n'))
        if m:
            new[m.group(1)] = m.group(2).strip()   # (a later line for the same code wins)
    changed, missing = 0, []
    texts = {}
    for code, t in new.items():
        it = items.get(code)
        if not it:
            missing.append(code + ' (không có mã này)')
            continue
        if it['text'].endswith(' ') and not t.endswith(' '):   # (a fragment joined to the next: its space kept)
            t += ' '
        if t == it['text'].replace('\\"', '"'):
            continue
        t = t.replace('"', '\\"')
        for w in it['where']:
            f, n = w.rsplit(':', 1)
            texts.setdefault(f, open(os.path.join(ROOT, f), encoding='utf-8').read().split('\n'))
            old = '"%s"' % it['text']
            idx = int(n) - 1
            if old not in texts[f][idx]:   # (the script moved since the export: find the line again)
                found = [i for i, l in enumerate(texts[f]) if old in l]
                if len(found) != 1:
                    missing.append('%s (%s: không tìm thấy câu cũ)' % (code, w))
                    continue
                idx = found[0]
            texts[f][idx] = texts[f][idx].replace(old, '"%s"' % t)
            changed += 1
    for f, ls in texts.items():
        open(os.path.join(ROOT, f), 'w', encoding='utf-8').write('\n'.join(ls))
    print('đã thay', changed, 'chỗ;', len(new), 'mã nhận được')
    for x in missing:
        print('  không thay được:', x)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'import':
        import_(*sys.argv[2:])
    else:
        its = export()
        from collections import Counter
        print(len(its), 'mục', Counter(i['kind'] for i in its))
