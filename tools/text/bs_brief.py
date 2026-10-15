"""The file handed to ChatGPT to rewrite Bạch Sơn's text (docs/xuat/bach_son_viet_lai/gui_chatgpt.md): the brief, the
world and the people in a page, how everyone speaks to whom, the rules, the return format, and every line, scene by
scene, as it is in the game now. Written by tools/text/bs_text.py export."""
import os
import re

SCENES = {
    ('bach_son_story.gd', '_arrive'): 'Phần A. Lên núi: Mạnh dẫn đường qua Bãi Tro (những người hóa sứ), thấy Bạch Sơn',
    ('bach_son_story.gd', '_either'): 'Phần A. Xem đồ vật, nơi chốn quanh trại (lời kể khi người chơi bấm Xem)',
    ('bach_son_story.gd', '_look'): 'Phần A. Nói chuyện với người trong trại (Cỏ, Diệu, mẹ Mạnh)',
    ('bach_son_story.gd', '_camp'): 'Phần A. Trại Ngoài Cổng: bà Lành đón Mạnh, hỏi nhân vật chính lên đây làm gì',
    ('bach_son_story.gd', '_free_roam'): 'Phần A. Tự đi quanh trại, nói chuyện với người trong trại; tối ngồi bếp với bà Lành',
    ('bach_son_story.gd', '_night'): 'Phần A. Đêm đầu ở trại: Mảnh Sành bò ra từ Rãnh Sứ, trận đánh, thua thì đứng dậy đánh lại',
    ('bach_son_story.gd', '_caravan'): 'Phần A. Sáng hôm sau: đoàn thầy thuốc của bà Sương nghỉ chân ở trại; nhân vật chính xin gánh hòm thuốc để được vào thành',
    ('bach_son_story.gd', '_gate'): 'Phần B. Sân Tro trước Cổng Trắng: Thử Tro. Tay nhân vật chính có men rạn thật (bị Trắng Tay chạm ở cửa đèo Vô Danh Cốc), nên tro ra xám',
    ('bach_son_story.gd', '_gate_can'): 'Phần B. Cách qua cổng 1: im lặng; lão Cẩn (lính cổng) làm ướt tro rồi cho thử lại. Lão sẽ bị phạt vì việc này',
    ('bach_son_story.gd', '_gate_truth'): 'Phần B. Cách qua cổng 2: nói thật mình bị Nghiệt chạm; bị giữ một đêm ở Sân Tro, sáng ra Chánh Ty Ngọc Khiết tự xuống xem',
    ('bach_son_story.gd', '_gate_blame'): 'Phần B. Cách qua cổng 3: đổ cho anh Vững (người khiêng hòm cùng đoàn). Tay anh nứt vì gánh nên tro ra xám; anh bị giữ lại rồi bị đuổi',
    ('bach_son_story.gd', '_inside'): 'Phần B. Qua cổng, vào Tầng Rửa; vợ anh Vững (nếu đã đổ cho anh) hỏi chồng đâu',
    ('bach_son_story.gd', '_palace'): 'Chuyển sang Phần D',
    ('bach_son_story.gd', '_end_card'): 'Thẻ kết thúc bản thử',
    ('bach_son_city.gd', ''): 'Phần C. Các bảng chữ: buổi trong ngày; Sổ ghi (Điều thấy là dữ kiện thấy được, Nhận ra là kết luận ghép từ các Điều thấy)',
    ('bach_son_city.gd', 'add_note'): 'Phần C. Thông báo khi Sổ ghi có dòng mới',
    ('bach_son_city.gd', 'add_nghi'): 'Phần C. Thông báo khi thanh Nghi (Ty nghi ngờ mình) tăng',
    ('bach_son_city.gd', '_begin_part'): 'Phần C. Thẻ đầu mỗi buổi, đếm ngày tới Lễ Quét Vôi',
    ('bach_son_city.gd', '_interacts'): 'Phần C. Nút tương tác trong thành (hiện khi đứng gần)',
    ('bach_son_city.gd', '_part_loop'): 'Phần C. Việc cần làm trong thành',
    ('bach_son_city.gd', '_do'): 'Phần C. Những việc nhỏ (ngồi đợi qua buổi, cổng tầng đóng...)',
    ('bach_son_city.gd', '_wash'): 'Phần C. Rửa tay ở bể (người trong thành rửa tay suốt ngày)',
    ('bach_son_city.gd', '_maty'): 'Phần C. Mắt Ty: người áo lam gạ nhân vật chính báo người khác cho Ty',
    ('bach_son_city.gd', '_porter'): 'Phần C. Gánh hòm cho bà Sương; lên Dinh Ty, Sổ Tro để mở trên bàn khi thư lại đi vắng',
    ('bach_son_city.gd', '_y_vien'): 'Phần C. Y Viện: bà Mẫn (thầy thuốc già, thầy của Lúa) và cái chén men rạn',
    ('bach_son_city.gd', '_den_thay'): 'Phần C. Đền Thầy: người coi đền, tranh thờ nhát chém tách người sạch khỏi người bẩn',
    ('bach_son_city.gd', '_nha_rua'): 'Phần C. Nhà Rửa (xưởng giặt liệm): chị Gấm, ông Sẹo được Bà rửa men hồi bảy tuổi',
    ('bach_son_city.gd', '_cart'): 'Phần C. Tối, sau Dinh Ty: xe trắng chở người bị đuổi đi, bà Sương trả tiền',
    ('bach_son_city.gd', '_camp_night'): 'Phần C. Đêm, chui qua Cửa Cống xuống trại: bà Lành, cái nong thẻ tro, tay Trắng Tay quờ vào lều',
    ('bach_son_city.gd', '_retest'): 'Phần C. Nghi đầy: khám sư và người của Ty chặn ở quảng trường, thử lại',
    ('bach_son_palace.gd', ''): 'Phần D. Số đếm ghép vào câu',
    ('bach_son_palace.gd', '_arrest'): 'Phần D. Sáng sau buổi cuối: Chánh Ty Ngọc Khiết tới bắt, đưa lên Điện',
    ('bach_son_palace.gd', '_up'): 'Phần D. Lên Bạch Điện; người hầu câm, bát cơm không ai ăn ở bậc cửa',
    ('bach_son_palace.gd', '_hall'): 'Phần D. Trong điện: Băng Tâm quay lưng rửa tay. "Ngọc Khiết, ở ngoài." "Cho ta xem tay."',
    ('bach_son_palace.gd', '_findings'): 'Phần D. Nhân vật chính nói thẳng với Tâm những điều đã nhận ra; Tâm đáp được chỗ nào thì đáp, chỗ không đáp được thì im',
    ('bach_son_palace.gd', '_offer'): 'Phần D. Lời đề nghị của Tâm (thu Thử Tro lại, lặng lẽ cho người mới bị đuổi về, nhưng không thừa nhận gì; đổi lại nhân vật chính không nói với ai), và lựa chọn',
    ('bach_son_palace.gd', '_leave'): 'Phần D. Từ chối: rời điện; thẻ Lễ Quét Vôi',
    ('bach_son_palace.gd', '_variant_b'): 'Phần D. Nhận lời (biến thể b): tờ giấy của Tâm',
    ('journal.gd', '_ready'): 'Giao diện: Sổ ghi (mở bằng Tab)',
    ('journal.gd', '_fill'): 'Giao diện: Sổ ghi, các mục',
    ('ash_test.gd', 'open'): 'Giao diện: thẻ Thử Tro',
    ('bs_status.gd', '_ready'): 'Giao diện: thanh Nghi và ngày giờ ở góc màn hình',
}

HEAD = '''# Bạch Sơn: viết lại toàn bộ lời thoại và chữ trong game

*File này để gửi ChatGPT. Sinh tự động từ code game ngày {date} bằng `tools/text/bs_text.py export`: {n} dòng, đúng như trong game lúc này.*

**Cách dùng:** gửi nguyên file cho ChatGPT (đính kèm hoặc dán vào). Nó trả về các khối `Mã<TAB>Câu mới`. Gom hết các khối vào một file `.txt`, đưa lại cho Claude để nạp vào game (`python tools/text/bs_text.py import <file>`; công cụ thay từng câu đúng chỗ của nó trong code và báo câu nào không thay được).

---

## 1. Việc của bạn

Bạn là người viết lời thoại tiếng Việt cho một game nhập vai. Hãy viết lại **từng dòng** ở mục 7 cho hay, tự nhiên, có hồn hơn. Tác giả chê bản hiện tại là "lỏ": câu cứng, nghe như dịch, nhiều câu giải thích, các nhân vật nói na ná nhau, có câu nghe như văn máy.

Bạn được đổi cách nói, độ dài, nhịp câu, từ ngữ. Bạn **không** được đổi:

- **Sự việc trong câu.** Ai làm gì, ai biết gì, con số, năm (PK ...), tên nơi, tên người, đồ vật. Người chơi ghép các dòng "Điều thấy" thành "Nhận ra", nên mỗi dòng Sổ ghi phải giữ đủ dữ kiện của nó.
- **Ai nói câu nào, và thứ tự.** Một mã là một câu. Không gộp hai mã, không tách một mã thành hai câu thoại, không thêm câu, không bỏ câu.
- **Chỗ giữ chỗ:** `%s`, `%d`, `[Tên]` giữ nguyên, đúng số lượng và thứ tự. Mảnh ghép (ví dụ "Ngồi đợi tới " rồi "chiều") phải ghép lại vẫn đọc trơn, giữ cả khoảng trắng cuối nếu có.
- **Tên riêng và thuật ngữ** ở mục 4.
- **Các câu khóa** ở mục 5, giữ y nguyên từng chữ.

Nếu thấy một câu sai với bối cảnh hay mâu thuẫn với câu khác, **đừng tự sửa sự việc**; giữ sự việc và ghi lại ở phần "Ghi chú" (mục 6).

## 2. Bối cảnh trong một trang

Thế giới có mười nước, mỗi nước do một **vị Tự** cai trị. Vị Tự là đệ tử cũ của một ông thầy, mỗi người giữ một **chữ**; lý tưởng của họ thành tuyệt đối nên họ không già đi, và lý tưởng ấy méo dần qua mấy trăm năm. Cảm xúc dồn nén của cả một nước mang hình thành **Nghiệt**, quái vật có thật.

**Nhân vật chính** lớn lên ở **Vô Danh Cốc**, một thung lũng không thuộc nước nào, với ông (người thầy, không ai biết ông là ai). Người chơi tự đặt tên nhân vật chính (`[Tên]`, mặc định "Bến"). **Nhân vật chính không có giới tính xác định**: không ai được gọi nhân vật chính bằng từ chỉ giới (anh, chị, cô, cậu, chú, thằng, con bé...). Trong Mở Đầu, một đoàn người bị đuổi khỏi Bạch Sơn chạy tới Vô Danh Cốc; **Trắng Tay** (Nghiệt của Bạch Sơn) đuổi theo tới cửa đèo; nhân vật chính và **Mạnh** đưa cô bé **Lúa** (học trò thầy thuốc, bị hóa sứ ở chân) về được. Tay Trắng Tay đã chạm vào nhân vật chính ở cửa đèo, để lại men rạn thật trên lòng bàn tay.

**Bạch Sơn** là thành vôi trắng xây bậc thang trên núi đá vôi. Lý tưởng: hoàn hảo, thanh lọc; méo thành: khác biệt là ô uế, phải loại bỏ. Nước sạch chảy từ đỉnh xuống từng tầng; tầng dưới dùng nước tầng trên đã rửa; ngoài **Cổng Trắng** là **Trại Ngoài Cổng** của người bị đuổi, sống bằng nước cả thành đã rửa xong. Ba trăm năm trong thành không có Nghiệt; người Bạch Sơn biết ơn cái cổng thật lòng.

Ai qua cổng cũng phải **Thử Tro**: xoa tro lên lòng bàn tay rồi dội nước. Tro không thấy Nghiệt, tro chui vào **vết rạn**: da bị Nghiệt chạm có lớp men rạn nên ra xám, nhưng tay nứt vì vôi, vì nước thuốc, vì gánh cũng ra xám. Kết quả đóng dấu **TRẮNG**, **XÁM** hay đen. Xám thì bị đuổi. Ngày xưa "xám thì giữ lại ở Nhà Rửa, đợi Bà" (Bà tự tay **Rửa** men cho người ta); ba mươi lăm năm nay Bà không xuống nữa, xám là ra cổng. Ngoài cổng, **Trắng Tay** (nghìn tay sứ trắng, mắt bịt) đi săn đúng những người bị đuổi; người chạm phải hóa sứ dần. Trong thành gọi nó là **Sứ Giả Thanh Khiết** và thờ nó. Nó sinh ra từ chính nỗi sợ của những người sau ô cửa trong thành. Nhà nào cũng đặt một chén sứ trên bậc cửa.

**Ty Thanh Tịnh** (gọi tắt "Ty") giữ cổng, giữ **Sổ Tro** (sổ ghi kết quả thử của từng người, cột Trắng, Xám, Đen) và soạn các **sắc** (lệnh). Đứng đầu là **Chánh Ty Ngọc Khiết**. Người của Ty mặc áo lam. **Mắt Ty** là người báo tin cho Ty. Vị Tự của Bạch Sơn là **Băng Tâm**; trong thành gọi bà là **Bà** (viết hoa). Bà ở trong **Bạch Điện** ba mươi lăm năm không ra, ký sắc mà không nhìn.

**Chương này:** nhân vật chính lên Bạch Sơn vì tin vị Tự là quái vật và tin rằng phơi sự thật ra là đủ. **Phần A:** Mạnh dẫn lên trại; đêm đầu Mảnh Sành (những mảnh gương mặt gãy khỏi vương miện của Trắng Tay) bò vào trại. **Phần B:** trà trộn vào đoàn thầy thuốc của **bà Sương** (từ Vạn Thư lên dự Hội Y) bằng cách gánh hòm thuốc; Thử Tro ở cổng ra xám, và người chơi chọn ai trả giá để được qua cổng. **Phần C:** bốn ngày trong thành trước **Lễ Quét Vôi**, mỗi ngày sáng, chiều, tối; đi Y Viện, Dinh Ty (Sổ Tro), Đền Thầy, Nhà Rửa, xe trắng, đêm chui **Cửa Cống** xuống trại. Thanh **Nghi** là mức Ty nghi ngờ mình. **Phần D:** Chánh Ty tới bắt, đưa lên Điện; Băng Tâm hỏi "Cho ta xem tay.", nghe những điều nhân vật chính nhận ra, rồi đưa ra một thỏa thuận riêng.

Không khí: lạnh, trắng, sạch tới mức im lặng; nỗi sợ thật, có lý do, từng cứu người, mà vẫn gây ra tội ác. Không ai là ác nhân một mặt. Ở trại thì ấm hơn: bếp chung, giọng to, đùa cợt, nghèo.

## 3. Nhân vật và cách xưng hô

| Nhân vật | Là ai | Cách nói | Xưng hô (giữ như dưới) |
|---|---|---|---|
| **[Tên]** (nhân vật chính) | Từ Vô Danh Cốc lên, đang ở bước "chắc chắn mình đúng" | Thẳng, ngắn, hơi bướng, còn trẻ; nói với người lớn thì lễ phép kiểu nhà quê ("ạ", "vâng") | Xưng **cháu** với người lớn tuổi; gọi họ **bà, ông, bác**; với Tâm xưng **cháu**, gọi **Bà**. Với ông ở Vô Danh Cốc thì là "ông cháu" |
| **Mạnh** | Chàng trai dìu Lúa trong Mở Đầu; mẹ còn ở trại | Ít nói, cộc, mệt | Với bà Lành xưng **con**; với nhân vật chính không xưng gọi |
| **Bà Lành** | Đứng đầu trại, giữ bếp chung và cái nong thẻ tro | Giọng to, hay đùa, chửi yêu, không tin ai trong thành | Gọi Mạnh **mày**, tự xưng **bà**; gọi nhân vật chính **cháu** hoặc không gọi |
| **Mẹ Mạnh** | Bị đuổi theo sắc họ hàng | Mệt, biết ơn | Gọi nhân vật chính **cháu**, xưng **bác** |
| **Cỏ** | Đứa trẻ sinh ở trại, chừng tám tuổi | Trẻ con, hồn nhiên | Xưng **em**, gọi bà Lành **bà** |
| **Diệu** | Con gái lão Cẩn, bị đuổi lúc chín tuổi, làm thuốc lá rừng | Cộc, không ngẩng lên | Xưng **tôi**, nói về bố là **ông ấy** |
| **Lão Cẩn** | Lính cổng hai mươi năm; tối nào cũng đứng trên tường nhìn xuống trại | Ít lời, khô | Không gọi giới; gọi nhân vật chính **cháu** hoặc không gọi |
| **Bà Sương** | Đứng đầu đoàn thầy thuốc Vạn Thư; thật ra mua người bị đuổi cho Vạn Thư mổ xẻ | Gọn, thực dụng, sai việc | Xưng **tôi**; không gọi giới nhân vật chính |
| **Anh Vững** | Người khiêng hòm của bà Sương, tay nứt vì gánh, có vợ ở Tầng Rửa | Hiền, ít nói | Xưng **tôi**, gọi **bà** Sương |
| **Khám sư** | Người làm Thử Tro ở Sân Tro | Đều giọng, theo lệ | Gọi nhân vật chính **cháu** hoặc không gọi |
| **Người áo lam** | Người của Ty | Lạnh, đe dọa nhẹ | Gọi nhân vật chính là **người này** hoặc không gọi |
| **Thư lại** | Thư lại ở Dinh Ty | Cáu, ngắn | Không gọi |
| **Bà Mẫn** | Thầy thuốc già ở Y Viện, thầy của Lúa; chữa lén cho người trong trại; Lúa bị đuổi thay bà | Cáu ngoài mặt, thương bên trong; giải thích bằng việc làm | Tự xưng **bà**; gọi nhân vật chính **cháu** hoặc không gọi |
| **Người coi đền** | Coi Đền Thầy | Mộ đạo, tin chắc | Gọi nhân vật chính **cháu** |
| **Chị Gấm** | Làm ở Nhà Rửa | Mệt, che chở ông Sẹo | Gọi ông Sẹo **ông** |
| **Ông Sẹo** | Người Rửa già; bảy tuổi được Bà rửa men, còn sẹo hình cánh mai | Kể chậm, thương Bà | Xưng **tôi**; gọi Băng Tâm **Bà** |
| **Chánh Ty** (Ngọc Khiết) | Đứng đầu Ty; chín tuổi từng bị giữ một đêm ở Sân Tro | Ân cần, rành mạch, hay dẫn số | Xưng **tôi**; **không bao giờ gọi thẳng** nhân vật chính, chỉ nói **người này** |
| **Bà Tâm** (Băng Tâm) | Vị Tự của Bạch Sơn; da như sứ, tay đỏ nứt; không cho ai lại gần quá một sải tay | Ít lời, lễ độ, chính xác; câu ngắn | Xưng **ta**, gọi nhân vật chính **con**; gọi Ngọc Khiết bằng tên |
| **Trong điện** | Giọng Tâm vọng ra trước khi thấy người | Như Tâm | |
| **(lời kể)** | Lời dẫn khi xem đồ vật, khi không ai nói | Tả ngắn, cụ thể, không bình luận | |

## 4. Tên riêng và thuật ngữ (không đổi, không dịch)

Bạch Sơn, Vô Danh Cốc, Cổng Trắng, Trại Ngoài Cổng, Bãi Tro, Rãnh Sứ, Sân Tro, Tầng Rửa, Tầng Giữa, Tầng Đền, Y Viện, Dinh Ty, Đền Thầy, Nhà Rửa, Cửa Cống, Bạch Điện, Vạn Thư, Xích Hoang; Ty, Ty Thanh Tịnh, Chánh Ty, Mắt Ty, khám sư, thư lại, người áo lam; Thử Tro, Sổ Tro, thẻ tro, sắc, Luật Cả Nhà, Rửa, Hội Y, Lễ Quét Vôi, xe trắng; Nghiệt, Trắng Tay, Mảnh Sành, Sứ Giả (Thanh Khiết), men, men rạn, hóa sứ; Bà (viết hoa, chỉ Băng Tâm); Nghi, Sổ ghi, Điều thấy, Nhận ra; TRẮNG, XÁM; năm PK; tên người: Băng Tâm, Ngọc Khiết, Lành, Mạnh, Cỏ, Diệu, Cẩn, Sương, Vững, Mẫn, Gấm, Sẹo, Lúa, Khê, Thục, Bảy.

## 4b. Quy tắc cập nhật canon (bắt buộc)

- Tên địa danh "Lũng Giữa" đã được đổi thành "Vô Danh Cốc".
- Tên "Điện Tịnh" đã được đổi thành "Bạch Điện" (ấn đọc "BẠCH ĐIỆN"); gọi tắt "Điện" vẫn dùng như cũ.
- Dùng "Vô Danh Cốc" thay cho "Lũng Giữa" trong toàn bộ lời thoại, lời kể, chữ giao diện và nội dung liên quan.
- Không giữ lại tên cũ ở bất kỳ dòng nào.
- Giữ nguyên mã dòng, thứ tự, biến giữ chỗ và các dữ kiện khác khi thay tên.
- Nếu gặp tên "Lũng Giữa" trong bối cảnh hoặc hướng dẫn của brief, cũng hiểu đó là địa danh nay mang tên "Vô Danh Cốc". (Game đã đổi sang tên mới; nếu còn sót tên cũ ở đâu, thay bằng "Vô Danh Cốc".)

## 5. Câu khóa (giữ y nguyên từng chữ)

- "Cho ta xem tay." (câu đầu tiên Tâm nói với người lạ)

## 6. Quy tắc viết

1. **Lời nói đời thường.** Câu ngắn. Người ta nói chuyện cụ thể (cái chén, cái hòm, cái cổng), có tiểu từ (à, ạ, đấy, nhé, thôi, mà, chứ, kìa), có khi bỏ chủ ngữ, có khi trả lời lệch. Không ai nói như viết văn.
2. **Không "giọng máy".** Không châm ngôn, không câu triết lý, không câu "chốt" đắt giá cuối đoạn, không kiểu "không phải X mà là Y", không liệt kê ba vế cho kêu, không ẩn dụ chồng ẩn dụ, không nhân vật tự giải thích cảm xúc của mình. Ý nặng nhất để người chơi tự thấy.
3. **Mỗi người một giọng** theo cột "Cách nói" ở mục 3. Đọc lời của bà Lành và lời của Chánh Ty phải biết ngay ai nói mà không cần nhìn tên.
4. **Lời kể** (xem đồ vật, chú thích thẻ tranh, Sổ ghi) tả ngắn như ghi chép, không bình luận đạo lý.
5. **Không dùng gạch ngang dài (—)**. Dùng dấu phẩy, dấu chấm, hai chấm.
6. **Độ dài tối đa:** thoại 150 ký tự; lựa chọn 55; nút tương tác 24; việc cần làm 60; thẻ chương 40; thông báo 80. Chữ giao diện (Sổ ghi, Nghi, Tab...) giữ ngắn như cũ.
7. **Viết hoa:** chỉ đầu câu và tên riêng. Dấu đóng Thử Tro (TRẮNG, XÁM) và thẻ tên (BĂNG TÂM) viết hoa toàn bộ.

## 7. Định dạng trả về

Trả về **mọi mã**, theo đúng thứ tự, mỗi mã một dòng: mã, một dấu TAB, câu mới. Dòng nào thấy không cần đổi thì chép lại y nguyên. Không thêm gì khác vào trong khối. Mỗi khối nằm trong một khung code:

```
BS-02	Qua bãi này là tới trại.
BS-03	...
```

File dài, nên chia làm **4 lần trả lời**: lần 1 là Phần A và B; lần 2 là nửa đầu Phần C (tới hết "Gánh hòm cho bà Sương"); lần 3 là phần còn lại của Phần C; lần 4 là Phần D và Giao diện. Hết mỗi lần, ghi "Hết lần N/4" và chờ người dùng gõ "tiếp".

Sau khối code của mỗi lần, thêm mục **Ghi chú** (không bắt buộc, tối đa 10 dòng): những chỗ bạn thấy sự việc có vẻ sai hoặc mâu thuẫn, những chỗ bạn buộc phải đổi nghĩa một chút. Ghi theo mã.

## 8. Toàn bộ chữ trong Bạch Sơn, theo cảnh

Cột "Ai nói / loại": tên người nói nếu là thoại; trong ngoặc là loại chữ nếu không phải thoại. "(lời kể)" là lời dẫn không có người nói. Cùng một câu dùng ở nhiều chỗ thì chỉ có một mã.
'''

IMAGES = '''
## 9. Chữ vẽ sẵn trong ảnh (tham khảo, không nằm trong khối trả về)

Mấy tấm thẻ tranh trong Phần C và D có chữ vẽ thẳng vào ảnh (trang Sổ Tro, sắc, quyển sổ bán tên, tờ giấy của Tâm). Nếu muốn đổi chữ ở đây, ghi ở phần Ghi chú, Claude sẽ vẽ lại ảnh.

- Trang Sổ Tro: tiêu đề "Tầng Rửa, tập PK 409", "Tầng Rửa, tập PK 410", "Tập đầu, năm PK 21", "Tầng Rửa, tập PK 395"; cột "Trắng", "Xám", "Đen".
- Sắc: "Thầy thuốc nào đã chữa cho người nhiễm, từ nay coi như nhiễm." / "Khám sư các cổng thử lại ngay, không đợi năm." (Năm PK 409); "Họ hàng của người đã bị đuổi phải ra khỏi cổng trước Lễ Quét Vôi." / "Không xét từng người." (Năm PK 412); dòng ký "Chánh Ty Ngọc Khiết soạn."; ấn "BẠCH ĐIỆN".
- Quyển sổ bán tên: "Giao, mùa thu", "Cộng, đủ số. Đã nhận.", ấn "VĂN LỤC · VẠN THƯ".
- Tập đầu: "Lệ của Ty Khám:", "Người bị Nghiệt chạm không vào.", "Người bị Nghiệt đuổi không vào.", "Đêm không mở cổng.", "Xám thì giữ lại ở Nhà Rửa, đợi Bà.", ghi chú "giữ lại ở Nhà Rửa.", "giữ lại. Bà đã rửa."
- Tập PK 395: "Nhà ... Luật Cả Nhà. Năm người.", "không thử", "Chồng, thợ muối", "Vợ, giặt liệm", "Mẹ chồng", "Con trai, mười hai tuổi", "Trẻ nhỏ, chưa tên."
- Tờ giấy của Tâm: "Rửa.", "Rắc tro cho kẽ hiện ra.", "Kẽ men thẳng, gãy góc, trên nền trắng.", "Kẽ da cong theo chỉ tay. Đừng nhầm.", "Lần theo kẽ men. Tới mép thì dừng.", "Cắt phần đã thối, không cắt người." (câu cuối là câu khóa của Tâm, giữ nguyên).
'''


def write(items, out_dir, date):
    rows = []
    cur = None
    for it in items:
        key = (it['file'].split('/')[-1], it['func'])
        if key != cur:
            cur = key
            rows.append('\n### %s\n\n| Mã | Ai nói / loại | Câu hiện tại |\n|---|---|---|' % SCENES.get(key, '%s %s' % key))
        who = it['speaker'] if it['kind'] == 'thoại' else '(%s)' % it['kind']
        t = it['text'].replace('\\"', '"').replace('|', '\\|')
        rows.append('| %s | %s | %s |' % (it['code'], who, t))
    body = HEAD.format(date=date, n=len(items)) + '\n'.join(rows) + '\n' + IMAGES
    body = body.replace('—', ',')
    path = os.path.join(out_dir, 'gui_chatgpt.md')
    open(path, 'w', encoding='utf-8').write(body)
    return path
