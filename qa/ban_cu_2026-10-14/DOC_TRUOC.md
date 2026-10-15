# Bản cũ trước lượt làm lại âm thanh và nhân vật (2026-10-14)

Để quay lại bản cũ nếu bản mới không ổn.

- `am_thanh/sfx`, `am_thanh/music`: chép đè vào `assets/audio/sfx`, `assets/audio/music`. `am_thanh/audio.gd` là `scripts/autoload/audio.gd` cũ (chưa có MUSIC_GAIN và bộ chặn đỉnh).
- `nhan_vat/chars`: thư mục `assets/sprites/chars` cũ (chưa có các file `_n.png`). Nếu chép lại, xoá các file `*_n.png` trong `assets/sprites/chars` để game dùng cách chiếu sáng cũ.
- `nhan_vat/pix.py`, `nhan_vat/chars.py`: `tools/art/` cũ. `nhan_vat/sprite_lit.gdshader`: `shaders/` cũ. `nhan_vat/actor.gd`: `scripts/world/` cũ.

Thư mục `qa` có `.gdignore`, nên Godot không nạp các file ở đây.
