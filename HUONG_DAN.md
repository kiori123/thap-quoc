# Thập Quốc · Bản thử nghiệm · Chương Mở Đầu

Demo 2.5D (sprite pixel trong thế giới 3D, kiểu HD-2D), Godot 4.7.2.
Nội dung truyện trong demo dựa trên các đề xuất ở `docs/` (chưa phải canon chốt).

## Chạy game
Nhấp đúp `chay_game.bat`.
(Hoặc mở Godot 4.7.2 → Import → chọn `project.godot` → Run.)

## Phím
| Việc | Bàn phím | Tay cầm |
|---|---|---|
| Di chuyển | WASD / phím mũi tên | D-pad / cần trái |
| Chạy | Shift (giữ) | RB |
| Tương tác / xác nhận / bấm nhịp | Space, Enter, E, J | A |
| Quay lại | Backspace, K | B |
| Tạm dừng | Esc, P | Start |
| Toàn màn hình | F11 | |

## Có gì trong demo
1. **Buổi sáng** ở thung lũng Vô Danh Cốc: bổ củi, quét sân, gánh nước (mini-game bấm nhịp), đi dạo nói chuyện với dân làng.
2. **Biến cố**: tin dữ ở đèo, "Đừng ra quá cột mốc.", trận đầu có hướng dẫn (3 Mảnh Sành), thoáng thấy (Duyên) lần đầu, các mảnh sứ cuộn về Trắng Tay, bức tường vô hình ở cột mốc.
3. **Đêm**: băng bó, bữa tối (có lựa chọn), hiên nhà, cây xà.
4. **Lên đường**: thanh kiếm, nắm cơm, "Đi đi. Ông chờ."
5. **Bạch Sơn (bản thử)**, mở riêng từ màn hình tựa: lên núi, trại ngoài cổng, trận đêm, đoàn xe trắng, Thử Tro ở Cổng Trắng (ba đường: im lặng, nói thật, đổ cho người khác), Tầng Rửa, rồi **phần C: bốn ngày trong thành** (mỗi ngày sáng, chiều, tối; tự chọn đi đâu; Tab mở Sổ ghi; thanh Nghi ở góc phải), rồi **phần D: Bạch Điện** (gặp bà Tâm; nhận hay từ chối lời đề nghị của bà). Chừng 30 đến 45 phút (ước, chưa đo). Chi tiết ở `docs/N_bach_son.md` mục 16.

Thời lượng ước chừng 15 đến 20 phút; con số này chưa được đo bằng người chơi thật.

## Chỉ đường
- Mũi tên vàng nhấp nhô trên chỗ cần tới. Chỗ đó khuất thì có mũi tên ở mép màn hình chỉ hướng. Đường xa (ra cửa đèo) thì có mũi tên nằm dọc đường đất.
- Lần đầu làm một việc mới (chẻ củi, quét lá, gánh nước) có bảng hướng dẫn từng bước và một lần làm mẫu ("XEM MẪU").
- Làm hỏng thì được làm lại: khúc củi chưa tách còn trên gốc, ông nói vì sao hỏng rồi cho chẻ lại; đống lá chưa sạch vẫn có mũi tên để quét lại; đổ gần hết nước thì gánh lại chuyến nữa.

## Chiến đấu (theo lượt)
- **Hình** = máu. **Chấp** = các mảnh khiên (biểu tượng trên đầu địch). Đánh đúng điểm yếu sẽ vỡ một mảnh; vỡ hết thì địch **mất lượt** và chịu **×2 sát thương**.
- **Bổ**: một nhát mạnh vào một địch. **Quét**: đánh tất cả. **Thủ**: thủ thế, đỡ chuẩn thì phản đòn. **Thấu**: lộ điểm yếu và vạch dừng. **Thuốc**: hồi Hình.
- **Bổ là một nét:** giữ Space cho nét dài ra, thả đúng ở **vạch dừng** là *DỨT!*. Thả sớm là *NON TAY*. Quá vạch là *QUÁ ĐÀ*: Nghiệt nuốt nhát chém, hồi máu và mạnh lên (ngọn lửa đỏ trên thanh máu).
- **Nối nét:** chém *DỨT!* xong, dải giấy của nét sau hiện sẵn vạch dừng mới; nhấn và giữ Space trước khi vạch thời gian cháy hết để chém tiếp. Nét sau mạnh hơn, nhanh hơn một chút; tối đa ba nét. Để yên là **dừng tay**: tâm thêm một giọt **Tịnh**. Quá đà giữa chuỗi thì Nghiệt nuốt cả chuỗi.
- Đủ 3 **Tịnh** (chém dứt rồi dừng tay, hoặc đỡ chuẩn) thì mở **Nhất Nét**: phá hết Chấp, cắt sạch Xâm. Một lần quá đà là mất hết Tịnh.
- Khi địch tấn công, bấm Space đúng lúc vòng tròn khớp để **đỡ**.
- **Nối thế (việc trước gây ra việc sau):**
  - **Đỡ chuẩn** thì địch **HỞ** tới hết lượt sau của mình: **Bổ** vào nó thì vạch dừng hiện rõ, đòn ×1,5 và tính như trúng điểm yếu.
  - **Bổ trúng** để lại vết **RẠN**: **Quét** qua thì bung ra, đòn quét lên con đó ×2 và tính như trúng điểm yếu.
  - **Quét trúng** thì địch **CHAO**: lượt sau đòn nó tới chậm, dễ đỡ chuẩn, mà đỡ chuẩn thì nó lại HỞ.
  - Quá đà thì vết rạn và chỗ hở liền lại. Thế hiện trên thanh của địch và trong bảng lệnh ("Bổ · hở", "Quét · rạn").
- **Trận ở đèo (Trắng Tay): chắn đường cho Lúa.** Nó không nhìn, không nghe mình; tay nó quờ về phía Lúa. Đứng chắn trước Lúa mà đỡ: đỡ chuẩn thì tay bật ra, đang **Thủ** thì đỡ tạm cũng chặn được. Tay lọt qua thì men leo lên người Lúa; ba lớp là thua. Giữ 6 vòng cho tới khi Lúa qua cột mốc. Mất một phần tư Hình hoặc vỡ Chấp thì nó rụt tay một lượt.
- **Trắng Tay** đánh khác quái nhỏ:
  - **Nghìn Tay:** nó dang tay một lượt rồi lượt sau quờ liền năm đòn. Lúc nó đang dang tay, chém *DỨT!* một nét để bẻ thế. Đỡ chuẩn hết thì nó hụt tay, mất lượt.
  - Vỡ hết Chấp thì mặt trên vương miện rơi xuống thành Mảnh Sành.
- **Men sứ:** bị Trắng Tay chạm trúng, hoặc quá đà gần nó, thì men leo một bậc: tới chân, tới tay (đòn yếu đi), tới mắt (**Bịt Mắt** 2 lượt: màn hình trắng xóa, không thấy gì). Khi bịt mắt, mỗi lần cần bấm có **hai tiếng gõ** rồi im một nhịp: **nhịp thứ tư** thì đỡ, hoặc thả Space (với Bổ và Quét, đếm từ lúc nhấn giữ). Không nối nét được khi bịt mắt. Dừng tay đúng lúc thì men nứt một lớp. Thuốc rửa được, Nhất Nét cắt sạch.
- Thua thì được đứng dậy đánh lại.
- Thấy khó bấm nhịp: vào **Thiết lập** → bật *Hỗ trợ bấm nhịp*.

## Font
- Be Vietnam Pro (chữ nổi trên cảnh), Noto Serif (chữ trên giấy: thoại, bảng, menu), Sedgwick Ave Display (tên boss, tên game). Cả ba giấy phép SIL Open Font License, bản giấy phép nằm cạnh file font trong `assets/fonts/`.

## Cài đặt & lưu
- Máy yếu bị giật: vào **Thiết lập** → tắt *Đồ họa cao* (tắt sương thể tích và đổ bóng môi trường).
- Thiết lập (âm lượng, tốc độ chữ, hỗ trợ bấm nhịp, đồ họa) lưu ở `%APPDATA%\Godot\app_userdata\Thập Tự - Đoạn Nghiệt\thapquoc.cfg` (tên thư mục theo tên game; trước 2026-10-13 là `Thập Quốc · Mở đầu`).
- Game có checkpoint theo từng đoạn.

## Kiểm thử tự động (cho dev)
- Trận chắn đường cho Lúa: `bash tools/run_autotest.sh duel <thư mục> mixed --foes=nghiet_tinh --escort`. Mỗi lần Lúa bị chạm ghi một dòng `lua_touched`.
- Lá cây không che máy quay: `bash tools/run_autotest.sh canopy <thư mục>` chụp ba chỗ có cây chắn, mỗi chỗ hai ảnh (`c*_on` có thưa lá, `c*_off` không).
- Nối thế: `bash tools/run_autotest.sh duel <thư mục> perfect --foes=manh_tinh,manh_tinh,manh_tinh --cmds=bo,quet --teach`. Ghi `mark_ho`, `mark_ran`, `mark_chao`, `the_bo_into_ho`, `the_quet_bursts_ran`, `chao_slow`; `--teach` hiện các bảng hướng dẫn và chụp `b_lesson_*`, `b_menu_lead`.
- Trận bịt mắt từ đầu tới cuối: `bash tools/run_autotest.sh duel <thư mục> perfect --foes=nghiet_tinh --blind`. Mỗi nút bấm ghi một dòng `check blind_...`: nhịp đủ chậm để theo, bấm đúng nhịp thứ tư là chuẩn.
```
bash tools/run_autotest.sh full     qa/shots/run  perfect   # cả chương, tự chơi
bash tools/run_autotest.sh incident qa/shots/inc  mixed     # có thua → đánh lại
bash tools/run_autotest.sh controls qa/shots/ctl            # đi, chạy, va chạm, tương tác, menu tạm dừng
bash tools/run_autotest.sh title    qa/shots/title
bash tools/run_autotest.sh manual   qa/shots/man              # bấm phím thật từ màn hình tựa tới bổ củi
bash tools/run_autotest.sh gallery  qa/shots/gal              # chụp nhanh các góc cố định + đo FPS (so đồ họa)
# Xem game tự chơi ở tốc độ đọc được (cửa sổ hiện, có tiếng): mở Godot với  -- --autotest=bachson --timing=perfect --watch
# Camera: mặc định lùi xa kiểu Octopath; thêm --cam=1 để xem camera gần cũ, --cam=2 để xa hơn nữa
bash tools/run_autotest.sh bachson qa/shots/bs               # Bạch Sơn bản thử, tự chơi (thêm `perfect --beat=night` để bắt đầu từ đêm; `--beat=gate --gate=can|truth|blame` để thử từng đường ở cổng; `--beat=city` để vào thẳng phần C, thêm `--city-plan=porter,yvien,camp,nharua,report,cart --city-report --city-retest` để thử đường báo Ty, xe trắng, thử tro lại; `--beat=palace` để vào thẳng phần D, thêm `--deal=accept` cho biến thể nhận lời, `--khe` cho lựa chọn kể phiến đá)
```
Script báo lỗi (exit 1) nếu có bất kỳ SCRIPT ERROR nào, câu chuyện không chạy hết, hoặc có mục kiểm tra điều khiển FAIL. Ảnh chụp và `report.json` (FPS, mốc truyện) nằm trong thư mục ảnh đã chọn.

Vẽ lại art / âm thanh: `python tools/gen_art.py`, `python tools/gen_audio.py`.
