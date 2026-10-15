# Thập Quốc · Bản chuẩn Việt hóa lời thoại và chữ hiển thị (Chương Mở Đầu)

**Ngày trích:** 2026-10-12, từ code của bản demo (`scripts/story/prologue.gd`, `scripts/battle/*.gd`, `scripts/ui/*.gd`).
**Mục đích:** bản thoại chuẩn để đối chiếu với game. Các dòng đã được biên tập theo giọng nhân vật và thuật ngữ ở `khai_niem_the_gioi_va_game.md`.

**Cập nhật 2026-10-14:** tác giả đổi tên địa danh **Lũng Giữa** thành **Vô Danh Cốc** (A2 Q48). Mọi dòng thoại, lời kể, chữ giao diện trong game và trong tài liệu này đã đổi theo; không giữ tên cũ.

**Cập nhật 2026-10-15:** Mở Đầu nối thẳng sang Bạch Sơn (A2 Q50): bỏ thẻ LD-09; các thẻ cuối Bạch Sơn BS-79, BS-268, BS-374, BS-375, BS-376 viết lại (ĐỀ XUẤT, xem từng dòng). Lời thoại không đổi chữ; nhiều câu nay có thêm biểu cảm và cử chỉ của người nói (đối số thứ ba của say(), xem khai_niem 9.1).

**Cập nhật 2026-10-14:** tác giả đổi tên **Điện Tịnh** thành **Bạch Điện** (A2 Q49), cả ấn "BẠCH ĐIỆN" trên sắc và trên tờ giấy của Tâm. Gọi tắt "Điện" vẫn dùng như cũ.

**Cập nhật:** tên dân gian Mảnh Sành / Trắng Tay đã được tác giả duyệt. Nhát kiếm cuối tên **Thập Tự Thức – Chân**. Nhan đề dự án chưa chốt.

---

## A. Bối cảnh cho người xét

**Game:** RPG theo lượt 2.5D, dark fantasy phương Đông. Bản demo là ngày cuối cùng của nhân vật chính ở làng **Vô Danh Cốc** trước khi lên đường: buổi sáng làm việc nhà, buổi trưa có biến ở cửa đèo, buổi tối, rồi sáng hôm sau ra đi. Dài khoảng 15 đến 20 phút.

**Nhân vật trong demo:**

| Tên hiển thị | Là ai |
|---|---|
| **Ông** | Ông lão nuôi nhân vật chính. Không bao giờ cười. |
| **[Tên]** | Nhân vật chính. Người chơi tự đặt tên ở màn tiêu đề (mặc định "Bến"). **Không xác định giới tính**: đừng thêm "cậu", "cô", "anh", "chị" khi gọi nhân vật chính. |
| **Lúa** | Bạn cùng làng của nhân vật chính, đi học nghề y ở Bạch Sơn, bị đuổi về. |
| **Tí**, **Na** | Hai đứa trẻ trong làng. |
| **Bà Cả** | Người già nhất làng. |
| **Chú Năm** | Nông dân trong làng. |
| **Người bán muối** | Người buôn từ ngoài vào. |
| **Người tị nạn** | Một người trong đoàn bị đuổi khỏi Bạch Sơn. |

**Xưng hô:** ông lão và nhân vật chính xưng "ông" với "con". Nhân vật chính và Lúa gọi nhau "tao", "mày". Bà Cả gọi nhân vật chính là "cháu". Người bán muối tự xưng "chú". Lúa gọi ông lão là "bác".

**Giọng ông lão (quy ước của tác giả):** nói ít, câu ngắn, dùng chữ của người làm ruộng. Không giảng đạo lý. Hay hỏi lại. Khi bị hỏi khó thì lảng sang việc nhà ("Ăn cơm đi, nguội rồi.").

**Spoiler, chỉ để người xét hiểu:** ông lão chính là người thầy năm xưa của mười vị Tự đang cai trị mười nước. Một lời hẹn giữ ông sống và giữ ông trong thung lũng suốt bốn trăm năm; dân làng gặp ông rồi quên ông. Người chơi chỉ biết điều này ở cuối game. Vì vậy:

- nhiều câu trong demo là **manh mối cố ý**: mười cái móc áo cũ, cái bát úp thêm trên mâm, hũ tiền đồng không tiêu, thanh kiếm "của người khách bỏ quên", câu "Một nét...", câu "Đi đi. Ông chờ.";
- chúng phải đọc như chuyện bình thường ở lần chơi đầu.

**Thuật ngữ trong thế giới:**

| Thuật ngữ | Nghĩa |
|---|---|
| **Nghiệt** | Dục vọng thành tuyệt đối thì mang hình, thành quái. |
| **Tự** | Mười người cai trị mười nước; người thầy của họ cũng được gọi là Tự. |
| **Hình** | Thanh sinh lực của hình hài Nghiệt trên giao diện chiến đấu; về 0 thì hình hài tan. |
| **Chấp** | Những miếng khiên sứ biểu thị Nghiệt bám chặt vào dục vọng nuôi nó tới đâu. |
| **Tịnh** | Tên môn võ và tên tài nguyên chiến đấu. Trong HUD, mỗi giọt Tịnh dùng để mở Nhất Nét; “tâm đã tịnh” là cách nói thường. |
| **Xâm** | Luật khuếch đại dục vọng cùng loại ở gần Nghiệt; trong demo, lửa đỏ trên thanh máu báo phần Xâm do Nghiệt nuốt nhát chém quá đà. |
| **Mảnh Sành**, **Trắng Tay** | Tên dân gian đã duyệt. Đề xuất nhân quả: Trắng Tay là thân chính; Mảnh Sành là các mảnh tách ra từ nó, không phải Nghiệt độc lập. |
| **Thập Tự Thức – Chân** | Tên đã duyệt cho nhát kiếm cuối; không phải tên dự án. |

**Cách đọc ký hiệu:**

| Ký hiệu | Nghĩa |
|---|---|
| `(dẫn)` | Chữ dẫn, không có người nói. Hiện trong khung thoại không có bảng tên. |
| `(nhắc)` | Dòng nhắc thao tác hiện ngắn trên màn hình. |
| `(việc)` | Dòng "Việc cần làm" ở góc màn hình. |
| `(thẻ)` | Chữ lớn hiện giữa màn hình lúc chuyển cảnh. |
| `(bóng)` | Chữ nhỏ bật lên trên đầu nhân vật. |
| `(chọn)` | Lựa chọn của người chơi. |
| `(nút)` | Chữ trên nút tương tác khi đứng gần một vật. |
| `%s`, `%d` | Chỗ game điền tên hoặc số. |
| *[điều kiện]* | Dòng chỉ hiện trong trường hợp ấy. |

**Quy ước dùng bản chuẩn:**

1. Giữ lời thoại ngắn, tự nhiên và đúng giọng từng nhân vật.
2. Ông lão nói ít, bằng chữ đời thường; không giảng đạo lý.
3. Manh mối phải đọc như chuyện bình thường ở lần chơi đầu.
4. Hướng dẫn và giao diện dùng thuật ngữ nhất quán, chỉ dẫn rõ thao tác.
5. Không gán giới tính cho nhân vật chính. Câu thoáng thấy qua Duyên chỉ mô tả hình ảnh, không ghi lời nói hoặc lời giải thích.

---

## B. Màn hình tiêu đề

| Mã | Loại | Nội dung |
|---|---|---|
| TT-01 | Tên game | THẬP TỰ *(tên game: Thập Tự - Đoạn Nghiệt, tác giả chốt 2026-10-13)* |
| TT-02 | Phụ đề | Đoạn Nghiệt |
| TT-03 | Phụ đề nhỏ | Bản thử nghiệm · Chương Mở Đầu |
| TT-04 | Nút | Bắt đầu |
| TT-05 | Nút | Tiếp tục |
| TT-06 | Nút | Thiết lập |
| TT-07 | Nút | Thoát |
| TT-07b | Nút | Bạch Sơn (bản thử) *[mới, 2026-10-12]* |
| TT-08 | Hướng dẫn | ↑ ↓ chọn · Space xác nhận · F11 toàn màn hình |
| TT-09 | Câu hỏi đặt tên | Ông gọi con là gì? |
| TT-10 | Gợi ý trong ô nhập | Bến |
| TT-11 | Hướng dẫn | Gõ tên rồi nhấn Enter. Tên này có thể đổi ở lần chơi sau. |

---

## C. Buổi sáng

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| MO-01 | (thẻ) | **Vô Danh Cốc** / Thung lũng không thuộc nước nào |
| MO-02 | Ông *[sửa: bớt giọng văn]* | ~~Dậy rồi thì ra chẻ củi. Nồi cháo không tự sôi đâu.~~ Dậy rồi thì ra chẻ ít củi. Ông còn nấu cháo. |
| MO-03 | [Tên] | Dạ... |
| MO-03a | Ông *[mới; camera lia tới gốc chặt]* | Rìu cắm ở gốc chặt, cạnh đống củi. |
| MO-04 | (nút) | Chẻ củi |
| MO-05 | (việc) *[sửa: nói rõ chỗ]* | Ra gốc chặt cạnh đống củi |

**Chẻ củi**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| MO-06 | Ông | Cầm rìu cho chắc. Đừng bổ bằng tay, bổ bằng cả người. |
| MO-07 | Ông | Một nét. Bắt đầu từ chỗ mình đứng, đi tới chỗ mình chọn, rồi dừng. |
| MO-08 | [Tên] | Chẻ củi thôi mà ông, có phải đánh nhau đâu. |
| MO-09 | Ông | Ừ. Chẻ đi. |
| MO-10 | ~~(nhắc)~~ *[bỏ: thay bằng bảng hướng dẫn MO-10a và một lần làm mẫu]* | ~~Giữ Space để vung rìu. Thả đúng vạch vàng; quá tay là dập củi.~~ |
| MO-10a | (bảng hướng dẫn) *[mới]* | **Chẻ củi: một nét** / 1. Nhấn và GIỮ Space: rìu giơ lên, vệt mực chạy dài trên dải giấy ở dưới màn hình. / 2. THẢ Space đúng lúc vệt mực chạm vạch vàng. / 3. Thả sớm thì non tay. Giữ quá vạch thì dập củi. / [Space] Hiểu rồi |
| MO-10b | (làm mẫu) *[mới]* | XEM MẪU · Giữ Space... thả khi vệt mực chạm vạch vàng |
| MO-11 | (bóng) *[nhát quá tay]* | dập |
| MO-12 | (bóng) *[nhát non]* | non |
| MO-12a | Ông *[sửa: ông nói theo kiểu của ông, không nhắc tới "vạch"; phần giải thích chuyển xuống dòng nhắc MO-12e]* | Non tay. Lại. |
| MO-12e | (nhắc) *[mới; nhát non]* | Thả sớm quá, vệt mực chưa tới vạch vàng. |
| MO-12b | Ông *[sửa, như MO-12a; dòng nhắc MO-12f]* | Mạnh tay quá, dập rồi. Lại. |
| MO-12f | (nhắc) *[mới; nhát quá tay]* | Giữ quá vạch vàng nên dập củi. Thả sớm hơn một chút. |
| MO-12c | Ông *[mới; hỏng hai lần liền một khúc: ông làm mẫu lại một lần, XEM MẪU]* | Nhìn ông này. |
| MO-12d | Ông *[mới; hỏng ba lần một khúc: khúc ấy bỏ sang đống, lấy khúc mới]* | Khúc này xơ rồi. Để đấy, lấy khúc khác. |
| MO-13 | Ông *[sửa điều kiện: không khúc nào tách được, khúc nào cũng phải bỏ sang đống]* | Dập hết rồi. Mai chẻ lại. |
| MO-13a | Ông *[mới; tách đủ củi nhưng không nhát nào dứt; sửa chữ "dứt" thành chữ của người chẻ củi]* | Tách thì tách được. Chưa nhát nào ngọt. |
| MO-14 | [Tên] *[có ít nhất một nhát dứt: ông suýt cười rồi đưa tay lên hông]* | Ông đau à? |
| MO-15 | Ông *[như trên]* | Vết cũ. Trời sắp trở gió. |
| MO-16 | Ông *[sửa: bỏ câu đúc kết; ý biết dừng đã có ở MO-07]* | ~~Chẻ cho dứt khoát. Tay sẽ biết lúc nào nên dừng.~~ Được rồi. Bê vào chái bếp cho ông. |

**Quét sân**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| MO-17 | Ông | Quét cái sân đi. Lá đa bay sang cả đây rồi. |
| MO-17a | Ông *[mới; camera lia tới góc hiên]* | Chổi dựng ở góc hiên. |
| MO-18 | (nút) / (việc) *[sửa việc]* | Lấy chổi / Lấy chổi ở góc hiên |
| MO-19 | Ông *[sửa nhẹ]* | Quét một lượt thôi. Quét đi quét lại bụi nó bay vào mặt. |
| MO-20 | ~~(nhắc)~~ *[bỏ: thay bằng MO-20a]* | ~~Tới từng đống lá, nhấn Space để quét. Giữ Space, thả ra khi vệt vào vùng vàng.~~ |
| MO-20a | (bảng hướng dẫn) *[mới]* | **Quét lá** / 1. Đi tới từng đống lá (có mũi tên vàng), nhấn Space. / 2. GIỮ Space: vòng quét đầy dần. / 3. THẢ khi vòng chạy vào khúc vàng. Giữ quá tay thì bụi bay vào mặt. / [Space] Hiểu rồi |
| MO-20b | (làm mẫu, ở đống lá đầu tiên) *[mới]* | XEM MẪU · Giữ Space... thả khi vòng vào khúc vàng |
| MO-21 | (nút) | Quét |
| MO-21a | (nút) *[mới; đống lá còn sót]* | Quét lại |
| MO-22 | (việc) | Quét lá (%d/3) |
| MO-22a | (việc) *[mới; vừa quét hỏng một đống]* | Quét lá (%d/3): còn sót, quét lại |
| MO-23 | (bóng) *[quét quá tay, bụi bay vào mặt]* | khụ! |
| MO-23a | (nhắc) *[mới; thả sớm: đống lá nhỏ đi nhưng còn, vẫn có mũi tên vàng]* | Thả sớm quá, vòng quét chưa tới khúc vàng. Quét lại đống này. |
| MO-23b | (nhắc) *[mới; giữ quá tay]* | Giữ quá tay, lá bay tung mà vẫn còn sót. Quét lại đống này. |
| MO-23c | (nhắc) *[mới; hỏng ba lần một đống]* | Đống lá vơi hẳn. Gió cuốn nốt chỗ còn lại. |
| MO-24 | Ông *[sửa điều kiện: quét sạch từ 2 đống trở lên ngay lần đầu]* | Ừ. |
| MO-25 | Ông *[sửa: giờ sân luôn được quét hết, chỉ là phải quét lại]* | ~~Lá còn kìa. Thôi, gió nó quét nốt.~~ Sạch rồi. Lần sau quét một lượt thôi. |

**Gánh nước**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| MO-26 | Ông | Gánh nước đổ đầy chum. |
| MO-26a | Ông *[mới; camera lia tới giếng]* | Đòn gánh để cạnh giếng. |
| MO-27 | (nút) / (việc) *[sửa việc]* | Gánh nước / Ra giếng lấy đòn gánh |
| MO-28 | Ông *[sửa: bớt giọng văn]* | ~~Đòn gánh nó lắc thì đừng chống lại nó. Đợi nó tới, rồi đỡ.~~ Đòn gánh nó nhún thì kệ nó, đừng ghì. Thùng văng ra tới nơi rồi hẵng đỡ. |
| MO-29 | ~~(nhắc)~~ *[bỏ: thay bằng MO-29a]* | ~~Nhấn Space mỗi khi thùng nước văng ra tới mép.~~ |
| MO-29a | (bảng hướng dẫn) *[mới]* | **Gánh nước** / 1. Đòn gánh lắc qua lắc lại: chấm trắng chạy trên thanh phía trên đầu. / 2. Nhấn Space đúng lúc chấm trắng chạy tới khúc vàng ở một trong hai đầu. / 3. Bấm sớm, hay để lỡ một nhịp, thì nước sóng sánh đổ ra. / [Space] Hiểu rồi |
| MO-29b | (làm mẫu) *[mới]* | XEM MẪU |
| MO-30 | Ông *[giữ được 5 hoặc 6 nhịp]* | Đầy chum. |
| MO-31 | Ông *[3 hoặc 4 nhịp]* | Được nửa chum. Đủ nấu cơm. |
| MO-31a | (chọn) *[mới; sau MO-31]* | Gánh thêm chuyến nữa / Thôi, đủ rồi |
| MO-32 | Ông *[sửa: dưới 3 nhịp thì về giếng gánh lại]* | Đổ gần hết dọc đường rồi. ~~Thôi, chiều gánh lại.~~ Gánh lại chuyến nữa. |
| MO-32a | Ông *[mới; chuyến thứ ba vẫn chưa đầy]* | Thôi, thế là đủ nấu cơm rồi. |
| MO-33a | *[mới, cần đưa vào bản chuẩn] Người bán muối ghé sân, nói chuyện với ông; nhân vật chính nghe* | |
| MO-33b | Người bán muối *[chào ông như người lạ, dù năm nào cũng qua đây: người ngoài gặp ông nhưng khuất mắt là quên]* | Nhà có ai không? Bác có lấy muối không? Muối Bạch Sơn, trắng lắm. |
| MO-33c | Ông | Ừ. Để ngoài hiên. |
| MO-33d | Người bán muối | Trên đèo vắng hoe. Tôi đi một mình mà cứ phải ngoái lại. |
| MO-33e | Người bán muối *[sửa: giọng nói chuyện]* | Trên Bạch Sơn lại đuổi một đoàn ra ngoài cổng đấy bác. Nghe bảo có cả mấy người học thuốc. |
| MO-33f | Người bán muối *[sửa: giọng nói chuyện]* | Họ đang dạt về phía đèo này. Ai cũng bảo lũng nhà bác Nghiệt không vào được mà. |
| MO-33g | Ông *[nhìn về phía đèo một lúc]* | Ừ. |
| MO-33h | [Tên] | Lúa cũng đang học thuốc trên đó... |
| MO-33i | Người bán muối | Thế à. Mong là không phải đoàn ấy. |
| MO-33j | Ông | Vào ăn bát cháo đã rồi hẵng đi. |
| MO-33 | Ông *[sửa: thêm câu dặn quen miệng mỗi sáng, để trưa nói lại thì câu ấy mới nặng]* | Được rồi. Đi chơi đi. Trưa về ăn cơm. Đừng ra quá cột mốc. |
| MO-33k | [Tên] *[mới]* | Dạ, con biết rồi. |

**Đi dạo trong làng.** Người chơi đi tự do, nói chuyện với ai, xem gì, theo thứ tự nào cũng được.

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| MO-34 | (việc) | Đi dạo quanh làng. Về nhà gặp ông khi xong |
| MO-35 | (nút) | Nói chuyện / Xem / Về nhà ăn cơm |
| MO-36 | Bà Cả | Cháu ở cái nhà cuối xóm phải không? Lớn nhanh thật. |
| MO-37 | Bà Cả | Hồi bé ai nuôi cháu nhỉ... Bà già rồi, nhớ chẳng ra. Chắc cả làng nuôi. |
| MO-38 | Chú Năm *[sửa: "Lúa năm nay" dễ lẫn với tên Lúa]* | Năm nay được mùa đấy. Đất này lành, chưa thấy Nghiệt bén mảng bao giờ. |
| MO-39 | Chú Năm *[sửa]* | Ra khỏi lũng thì chú không dám chắc. Nghe đâu trên Bạch Sơn lại đuổi người ra khỏi cổng. |
| MO-40 | Na *[sửa nhẹ; giữ nguyên thành ngữ vì là manh mối đã định ở B, F]* | Mày hứa rồi đấy nhé! Lời thần trói thiên hạ, lời Tự trói mình! |
| MO-41 | Tí *[sửa]* | Mày học đâu cái câu dài ngoằng thế? |
| MO-42 | Na *[sửa: bà giảng nghĩa thường bằng lời thường]* | Bà tao nói suốt. Bà bảo hứa rồi thì phải giữ, chẳng ai bắt cũng phải giữ. |
| MO-43 | Người bán muối *[sửa: đã gặp nhau ở sân]* | Chú đi buôn mười năm, chưa thấy chỗ nào yên như lũng này. |
| MO-44 | Người bán muối *[sửa: giọng nói chuyện]* | Đi khắp mười nước, chỗ nào chú cũng gặp Nghiệt. Bên Thiên Mệnh cứ bảo nước họ sạch. Chú chẳng tin. |
| MO-45 | Người bán muối *[sửa: tin đã nghe ở sân]* | Chú ở lại vài hôm, đợi đường đèo yên đã. |
| MO-46 | (dẫn) móc áo | Mười cái móc gỗ cũ, mòn bóng. Cái thứ mười một mới hơn, ông đóng cho con hồi nhỏ. |
| MO-47 | (dẫn) hũ tiền | Hũ tiền đồng cũ. Ông bảo đó không phải tiền của ông, nên không bao giờ tiêu. |
| MO-48 | (dẫn) cây xà | Cây xà chính. Gỗ đen bóng, chắc còn cũ hơn cả ngôi nhà. |
| MO-49 | (dẫn) thanh kiếm | Thanh kiếm cùn treo trên vách. Ông bảo của một người khách bỏ quên. |
| MO-50 | (dẫn) bia đá | Bia đá ở cửa đèo. Mười con dấu, mỗi con một kiểu. Dòng chữ đã mờ: "Đất này không thuộc nước nào." |
| MO-51 | (dẫn) cột mốc | Cột mốc. Ông dặn không bao giờ được ra quá chỗ này. |
| MO-52 | (dẫn) miếu | Miếu thổ địa. Nhang vẫn còn ấm. |
| MO-53 | (dẫn) cây đa | Cây đa đầu làng. Người già bảo nó có trước cả làng. |
| MO-54 | (dẫn) giếng | Giếng nước. Sâu và mát. |
| MO-55 | Ông *[khi về nhà]* | Đi chơi đủ rồi à? |
| MO-56 | (chọn) | Về ăn cơm / Đi thêm chút nữa |

---

## D. Buổi trưa: biến ở cửa đèo

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BC-01 | (thẻ) | Trưa |
| BC-02 | Tí | %s ơi! Có người ở cửa đèo! Đông lắm... *(%s = tên người chơi)* |
| BC-03 | Tí | Có cả... cái gì trắng trắng đuổi theo sau! |
| BC-04 | (bóng) ông lão | ... |
| BC-05 | Ông | Đừng ra quá cột mốc. |
| BC-06 | (nhắc) | Cầm lấy cái rìu. |
| BC-07 | (việc) *[sửa: chỉ đường]* | Ra cửa đèo: theo đường đất qua đầu làng, lên phía đồi |
| BC-08 | Người tị nạn | Cứu... cứu với... |
| BC-09 | [Tên] | Lúa?! |
| BC-10 | Lúa | ...Đừng lại gần. Tao bị... Chạy đi. Nó tới. |
| BC-11 | (dòng mở trận 1) | Ba Mảnh Sành bò ra khỏi màn sương trắng! |
| BC-12 | (thoáng thấy, khi dùng Thấu lần đầu) | Cổng Trắng khép lại. |
| BC-13 | (thoáng thấy) | Sau cổng, những gương mặt nhìn ra. Một bàn tay khép then cửa. |
| BC-13a | (thoáng thấy, nhịp cuối) *[mới, cần đưa vào bản chuẩn]* | Rồi từ sau song cổng, những bàn tay trắng bò ra. |
| BC-14 | [Tên] *[sửa cảnh: những bàn tay mù quờ dọc mặt đường, hai bàn tay tìm thấy người mẹ và ông già, sứ leo từ cổ chân lên]* | Không! |
| BC-14a | (thẻ tên, khi Trắng Tay bước ra khỏi màn sương) *[mới]* | **TRẮNG TAY** / Nghiệt Bạch Sơn |
| BC-15 | (dòng mở trận 2) | Những mảnh sứ vỡ cuộn quanh nó. Trắng Tay vươn những cánh tay trắng. |
| BC-16 | [Tên] | Lúa, đi! |
| BC-17 | [Tên] *[con Nghiệt đâm vào bức tường vô hình ở cột mốc]* | ...Nó không vào được. |
| BC-18 | (dẫn) *[sửa: chỉ kể cái thấy, bỏ câu báo trước]* | ~~Trắng Tay rút đi. Hình hài nó tan, nhưng nó sẽ còn tụ lại.~~ Trắng Tay lùi vào trong sương, tan dần. Trên đường chỉ còn mấy mảnh sứ. |
| BC-19 | Lúa *[sửa: bỏ câu chốt]* | ~~Tao chữa cho người bị Bạch Sơn gọi là nhiễm... giờ thì tới lượt tao.~~ Chưa hết đâu... Nó còn quay lại. |
| BC-19a | Lúa *[mới; cái lạnh ở chân cho thấy men đang lan]* | Chân tao... lạnh quá. Không thấy gì nữa. |
| BC-20 | (dẫn) *[thua trận]* | Ngã xuống rồi. Đứng dậy lần nữa? |
| BC-21 | (chọn) *[thua trận]* | Thử lại |

---

## E. Trận đánh

**Lệnh** (tên và dòng mô tả hiện dưới bảng lệnh)

| Mã | Lệnh | Mô tả |
|---|---|---|
| TD-01 | Bổ | Một nhát mạnh vào một Nghiệt. |
| TD-02 | Quét | Quét ngang, trúng mọi Nghiệt. |
| TD-03 | Nhất Nét | Cần 3 Tịnh. Một nét chém dứt: phá hết Chấp, cắt sạch Xâm. |
| TD-04 | Thủ | Vào thế thủ. Đỡ đúng lúc sẽ phản đòn. |
| TD-05 | Thấu | Chạm vào Nghiệt, thấy nó từ đâu ra và điểm yếu. |
| TD-06 | Thuốc | Đắp lá thuốc, hồi 30 Hình. |

**Tên và lời giới thiệu Nghiệt** (hiện khi dùng Thấu)

| Mã | Tên | Lời giới thiệu |
|---|---|---|
| TD-07 | Mảnh Sành *(mảnh tách ra từ thân chính)* | Một gương mặt trên vương miện của Trắng Tay, gãy lìa ở cổ, còn đội nón, mắt còn bịt. Nó bò trên những ngón tay sứ. |
| TD-08 | Trắng Tay *(thân chính của Nghiệt Bạch Sơn)* | Mang hình đám người sau Cổng Trắng: những gương mặt bịt mắt dưới nón lá, dính lại thành một pho tượng sứ nghìn tay. Nó không nhìn ai, chỉ quờ tay. Chỗ bị chạm hóa sứ dần. Nó săn những người bị đuổi khỏi cổng. |
| TD-09 | Khung Thấu | **%s**. %s<br>Điểm yếu: **%s**. Vạch dừng của nó giờ đã rõ. *(tên, lời giới thiệu, điểm yếu)* |

**Bảng hướng dẫn** (hiện từng bảng, nhấn Space để qua). *[Sửa 2026-10-12]* Trận đầu chỉ dạy những gì việc nhà đã dạy: TD-13 Bổ (chẻ củi), TD-15 Quét (quét sân), TD-16 Đỡ (gánh nước). Trận đầu cũng chưa có nối nét. TD-10, TD-11, TD-12, TD-14, TD-17 dời sang trận Trắng Tay. Lần thoáng thấy đầu tiên không cần bấm Thấu: nó tự xảy ra khi lưỡi rìu chạm vào Nghiệt lần đầu (luật Duyên).

| Mã | Nội dung |
|---|---|
| TD-10 | Nghiệt có hai thứ cần để ý. Thanh đỏ là **Hình**, sức chịu đựng hình hài của nó; về 0 thì hình hài tan. Những miếng khiên sứ là **Chấp**, mức độ nó bám chặt vào dục vọng nuôi mình. |
| TD-11 | Đánh trúng **điểm yếu** thì vỡ một miếng Chấp. Vỡ hết, Nghiệt lảo đảo: mất lượt và chịu đòn gấp đôi. |
| TD-12 | *[sửa]* Chạm vào Nghiệt thì thoáng thấy nơi nó sinh ra. Làm việc đó có chủ ý là **Thấu**: lộ điểm yếu và vạch dừng của nhát chém. |
| TD-13 | *[sửa]* Như lúc chẻ củi: **Bổ** là một nét. Giữ Space cho nét đi tới, thả đúng ở **vạch dừng** là chém dứt. Thả sớm thì non tay. Quá vạch là **quá đà**: Nghiệt nuốt lấy nhát chém và lớn thêm. |
| TD-14 | *[sửa: vạch dừng của nét sau hiện sẵn]* Chém dứt rồi thì có thể **nối nét**. Vạch dừng của nét sau hiện sẵn trên dải giấy; nhấn và giữ Space trước khi vạch thời gian cháy hết thì chém tiếp, mạnh hơn và nhanh hơn một chút. Tối đa ba nét.<br>Để yên thì **dừng tay**: biết dừng thì tâm thêm một giọt Tịnh. Quá đà giữa chừng thì Nghiệt nuốt **cả chuỗi**. |
| TD-15 | **Quét**: giữ Space để vệt quét đi dần, thả ra khi nó vào vùng vàng. Y như quét sân. Trúng mọi Nghiệt. Giữ quá tay là **quá đà**: cả bầy cùng lớn. |
| TD-16 | *[sửa]* Như lúc gánh nước: nó tới nơi rồi hẵng đỡ. Nhấn **Space** đúng lúc vòng đỏ khép vào vòng trắng. |
| TD-17 | Mỗi lần chém dứt rồi dừng tay, hoặc đỡ chuẩn, tâm thêm một giọt **Tịnh**. Đủ ba giọt thì mở **Nhất Nét**: một nét chém dứt, phá hết Chấp và cắt sạch Xâm. Chỉ một lần quá đà là tâm loạn, mất hết Tịnh. |
| TD-18 | [Space] tiếp *(góc bảng hướng dẫn)* |

**Dòng thông báo trong trận** (hiện ở đầu màn hình)

| Mã | Khi nào | Nội dung |
|---|---|---|
| TD-19 | Mở trận, mặc định | Nghiệt lao tới! |
| TD-20 | Nghiệt tới lượt | %s tấn công! |
| TD-21 | ~~Đòn đặc biệt của Trắng Tay~~ *[bỏ: thay bằng Nghìn Tay, TD-62 đến TD-71]* | ~~%s vươn hết những cánh tay trắng ra!~~ |
| TD-22 | ~~Trúng đòn của Trắng Tay~~ *[bỏ: thay bằng men sứ, TD-72 đến TD-80]* | ~~Hóa Sứ: tay chân cứng lại. Đòn đánh yếu đi trong 2 lượt.~~ |
| TD-23 | Nghiệt mất lượt | %s đang lảo đảo. |
| TD-24 | Trắng Tay hết lảo đảo lần đầu, Chấp hồi lại | Trắng Tay đổi hình. Điểm yếu của nó đã khác. |
| TD-25 | Chọn Thủ | Vào thế thủ. Đỡ đúng lúc sẽ phản đòn. |
| TD-26 | Đỡ chuẩn khi đang Thủ | Phản đòn! |
| TD-27 | Bổ quá đà | Nhát chém quá đà. %s nuốt lấy nó. |
| TD-28 | Quá đà ở nét thứ 2 hoặc 3 | Nét thứ %d quá đà. %s nuốt cả chuỗi. |
| TD-29 | Quét quá đà | Quét quá tay. Cả bầy Nghiệt cùng lớn. |
| TD-30 | Dừng tay sau nhát dứt | Dừng tay. |
| TD-31 | Đủ 3 Tịnh | Tâm đã tịnh. Có thể dùng Nhất Nét. |
| TD-32 | Chọn Nhất Nét khi chưa đủ | Tâm chưa tịnh: cần đủ 3 Tịnh. |
| TD-33 | Dùng Nhất Nét | Nhất Nét. |
| TD-34 | Hết thuốc | Hết thuốc rồi. |
| TD-35 | Thắng | Nghiệt tan. |
| TD-36 | Thua | Không đứng dậy nổi nữa... |

**Chữ bật lên giữa trận**

| Mã | Khi nào | Nội dung |
|---|---|---|
| TD-37 | Số sát thương, số máu hồi | 25, +3, ... |
| TD-38 | Vỡ hết Chấp | VỠ CHẤP! |
| TD-39 | Được thêm Tịnh | Tịnh |
| TD-40 | Mất hết Tịnh vì quá đà | tâm loạn |
| TD-41 | Nét thứ 2, thứ 3 trúng | NÉT %d |
| TD-42 | Nghiệt đang lảo đảo | ... |

**Thanh bấm nhịp và chữ chấm điểm** (dùng chung cho việc nhà và trận đánh)

| Mã | Khi nào | Nội dung |
|---|---|---|
| TD-43 | Thanh nét (Bổ, chẻ củi) | Giữ Space, thả ở vạch / Thả! |
| TD-44 | Nét thứ 2 trở đi | Nét %d: thả ở vạch mới |
| TD-45 | Cửa sổ nối nét *[sửa: dải giấy của nét sau hiện sẵn vạch dừng mới, vạch thời gian cháy dần bên dưới]* | Nhấn giữ Space: nối nét |
| TD-46 | Cửa sổ nối nét, dòng nhỏ | Để yên: dừng tay, tâm thêm một giọt Tịnh |
| TD-47 | Vòng giữ (Quét, quét sân) | Giữ Space / Thả! |
| TD-48 | Vòng đỡ | Space để đỡ |
| TD-49 | Gánh nước | Space khi thùng văng ra mép / Nước: %d / %d |
| TD-50 | Chấm điểm khi chém | DỨT! (chuẩn) · ĐƯỢC (tạm) · NON TAY (sớm) · QUÁ ĐÀ (quá vạch) |
| TD-51 | Chấm điểm khi đỡ | ĐỠ! (chuẩn) · CHẶN (tạm) · TRÚNG (không đỡ được) |
| TD-52 | Chấm điểm khác | TRƯỢT |
| TD-53 | Sau nhát dứt | NỐI NÉT (bấm tiếp) · DỪNG TAY (để yên) |
| TD-54 | Gánh nước | Vững (đỡ đúng) · Sớm quá (bấm sớm) · Sóng sánh! (để nước văng) |

**Bảng nhân vật và bảng tổng kết**

| Mã | Chỗ | Nội dung |
|---|---|---|
| TD-55 | Bảng nhân vật | Hình %d / %d      Thuốc ×%d |
| TD-56 | Bảng nhân vật | Tịnh *(kèm ba giọt nước)* |
| TD-57 | ~~Bảng nhân vật, khi bị Hóa Sứ~~ *[bỏ: thay bằng TD-78 đến TD-80]* | ~~Hóa Sứ: còn %d lượt~~ |
| TD-58 | Thứ tự lượt | Lượt: *(kèm danh sách tên)* |
| TD-59 | Thanh máu Nghiệt khi vỡ hết Chấp | VỠ |
| TD-60 | Tổng kết sau khi thắng, dòng lớn | Nét: Tịnh · Nét: Vững · Nét: Loạn *(theo cách đánh)* |
| TD-61 | Tổng kết, dòng nhỏ | Chém dứt %d    Đỡ chuẩn %d    Quá đà %d    Nối %d nét |

### Bộ chiêu riêng của Trắng Tay *[mới, 2026-10-12, cần đưa vào bản chuẩn]*

| Mã | Khi nào | Nội dung |
|---|---|---|
| TD-62 | Nghìn Tay, lượt dang tay | Trắng Tay dang hết những cánh tay ra. |
| TD-63 | Chữ nổi trên đầu nó | NGHÌN TAY |
| TD-64 | Đầu lượt người chơi khi nó đang dang tay *[sửa: nó không nghe]* | %s đang dang tay. Chém dứt một nét để bẻ thế, hoặc Thủ mà chờ. |
| TD-65 | Chém dứt trúng lúc nó dang tay | Bẻ được thế! Mấy cánh tay rụng khỏi vòng hào quang. |
| TD-66 | Chữ nổi | BẺ THẾ |
| TD-67 | Lượt quờ tay, thế còn nguyên | Trắng Tay quờ hết những cánh tay tới! |
| TD-68 | Lượt quờ tay, thế đã gãy | Thế đã gãy. Chỉ vài cánh tay quờ tới. |
| TD-69 | Đòn cuối của lượt quờ tay | Những bàn tay trắng trồi lên từ đất! |
| TD-70 | Đỡ chuẩn hết cả lượt quờ tay | Đỡ hết. Trắng Tay vươn hụt, lảo đảo. *(chữ nổi: HỤT TAY)* |
| TD-71 | Nó mất lượt vì hụt tay | %s còn lảo đảo, chưa gom được tay. |
| TD-72 | ~~Bổ quá đà khi đánh Trắng Tay~~ *[bỏ: Trắng Tay không nghe]* | ~~Nhát quá đà vang lên. Trắng Tay nghe thấy, quờ tới!~~ |
| TD-73 | Vỡ Chấp: mặt trên vương miện rơi thành Mảnh Sành | Gương mặt nứt khỏi vương miện của Trắng Tay, rơi xuống, bò dậy. |
| TD-74 | Men sứ, chữ nổi theo lớp | Men tới chân · Men tới tay · BỊT MẮT · men nứt |
| TD-75 | Men lên tới tay | Men sứ leo tới tay. Đòn chém yếu đi. Dừng tay đúng lúc thì men nứt ra. |
| TD-76 | Men lên tới mắt | Men sứ phủ kín mắt. Không thấy gì nữa. Nghe hai tiếng gõ, giữ nhịp: nhịp thứ tư thì đỡ, thì thả tay. |
| TD-77 | Hết Bịt Mắt | Lớp men trên mắt nứt ra, rơi xuống. Lại thấy rồi. |
| TD-78 | Đắp Thuốc khi đang Bịt Mắt | Lá thuốc rửa sạch lớp men trên mắt. |
| TD-79 | Bảng nhân vật | Men sứ tới chân · Men sứ tới tay: đòn yếu đi · BỊT MẮT: còn %d lượt |
| TD-80 | Dòng đếm nhịp khi Bịt Mắt *(dưới hai chấm, một gạch, một vòng)* | Hai tiếng gõ, nhịp thứ tư thì đỡ · Giữ Space · Hai tiếng gõ, nhịp thứ tư thì thả |

**Trận ở đèo: Chắn đường cho Lúa** *[mới, ĐỀ XUẤT; hướng do tác giả chọn]*

| Mã | Khi nào | Nội dung |
|---|---|---|
| TD-81 | Bảng hướng dẫn, đầu trận hai | Trắng Tay không thấy, không nghe. Nó không đánh mình: tay nó quờ về phía **Lúa**. Đứng chắn mà đỡ. Đỡ chuẩn thì tay bật ra; đang **Thủ** thì đỡ tạm cũng chặn được. Tay nào lọt qua, men leo lên người Lúa; ba lớp là Lúa hóa sứ. Vỡ Chấp, đánh rạn hình hài thì nó rụt tay lại. Giữ cho tới khi Lúa qua được cột mốc. |
| TD-82 | Lượt của nó | Tay Trắng Tay quờ về phía Lúa. |
| TD-83 | Một tay lọt qua | Một bàn tay lọt qua, chạm vào Lúa. *(chữ nổi: men lên người Lúa)* |
| TD-84 | Tay thứ ba lọt qua | Men phủ kín người Lúa. |
| TD-85 | Góc trên trái, hai dòng | Lúa: còn %d bước tới cột mốc / Men trên người Lúa: %d/3 |
| TD-86 | Mỗi lần mất một phần tư Hình *[sửa: "rạn" nay là tên một thế, xem TD-89]* | Hình hài nó ~~rạn~~ mẻ một mảng. Trắng Tay rụt tay lại một lượt. *(chữ nổi: RỤT TAY)* |
| TD-87 | Lúa qua cột mốc (thắng) | Lúa qua được cột mốc. |
| TD-88 | Lúa hóa sứ (thua) | Lúa hóa sứ. |
| BC-20a | (dẫn) *[thua vì Lúa hóa sứ]* | Không kịp. Làm lại lần nữa? |

**Nối thế: việc trước gây ra việc sau** *[mới, ĐỀ XUẤT; tác giả nhận xét các chiêu của nhân vật chính chưa có nhân quả gì với nhau]*

| Mã | Khi nào | Nội dung |
|---|---|---|
| TD-89 | Chữ trên thanh của Nghiệt, và chữ nổi khi thế xuất hiện | HỞ · RẠN · CHAO |
| TD-90 | Bảng hướng dẫn, lần đầu có con HỞ | Đỡ chuẩn thì đòn nó hụt đà, thân nó **hở** ra. Lượt này **Bổ** vào con đang HỞ: vạch dừng hiện rõ, đòn nặng gấp rưỡi và tính như trúng điểm yếu. Hết lượt này thì chỗ hở khép lại. |
| TD-91 | Bảng hướng dẫn, lần đầu có con RẠN | Nét chém biết dừng thì có mép, để lại **vết rạn** trên hình hài nó. **Quét** qua con đang RẠN thì vết rạn bung ra: đòn quét lên nó nặng gấp đôi và tính như trúng điểm yếu. Quá đà thì nó nuốt nét, vết rạn liền lại. |
| TD-92 | Bảng hướng dẫn, lần đầu có con CHAO | Quét trúng thì nó **chao** chân. Lượt tới của con đang CHAO, đòn nó tới chậm hơn, dễ đỡ chuẩn hơn. Đỡ chuẩn thì nó lại hở. |
| TD-93 | Câu nối vào cuối bảng thứ ba trong ba bảng trên | **Đỡ** cho nó hở. **Bổ** vào chỗ hở thì nó rạn. **Quét** vết rạn thì nó chao. Nó chao thì dễ đỡ. Việc trước gây ra việc sau. |
| TD-94 | Bổ vào con đang HỞ | Bổ vào chỗ hở. *(chữ nổi: VÀO CHỖ HỞ)* |
| TD-95 | Thanh nét, khi Bổ vào chỗ hở | Chỗ hở: thả ở vạch |
| TD-96 | Quét trúng | Vết rạn bung ra. Nó chao chân. · Cả bầy chao chân. *(chữ nổi trên con bị bung: BUNG!)* |
| TD-97 | Lượt của con đang CHAO *(nối sau TD-20, TD-82, TD-67, TD-68)* | Nó còn chao, đòn tới chậm. · Nó còn chao, tay tới chậm. |
| TD-98 | Quá đà lên con đang HỞ hoặc RẠN | *(chữ nổi)* liền lại |
| TD-99 | Bảng lệnh, khi có con đang HỞ hoặc RẠN | Bổ · hở / Quét · rạn. Dòng mô tả thêm: Có Nghiệt đang HỞ: Bổ vào nó nặng gấp rưỡi, tính như trúng điểm yếu. · Có Nghiệt đang RẠN: Quét bung vết rạn, nặng gấp đôi lên nó. |
| TD-100 | Bổ non tay *(mới: trước đây chỉ có chữ chấm điểm)* | Non tay: nét dừng sớm, đòn nhẹ. *(thêm, nếu đang Bổ vào chỗ hở:)* Chỗ hở khép lại. |
| TD-101 | Quét thả sớm | Thả sớm: vệt quét chưa tới, đòn nhẹ. |
| TD-102 | Tổng kết sau trận, nối vào dòng nhỏ TD-61 | Nối thế %d |

---

## F. Buổi tối

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| DE-01 | (thẻ) | Tối |
| DE-02 | Ông *[đang băng bó]* | Rửa vừa thôi. Rửa mạnh quá thì không lành. |
| DE-03 | [Tên] *[sửa: bớt giọng văn]* | Ông đắp lá gì thế? Chỗ trắng trên chân Lúa không lan lên nữa. |
| DE-04 | Ông *[sửa]* | Lá ngoài vườn. |
| DE-05 | [Tên] *[sửa]* | Bọn trên Bạch Sơn đóng cổng lại, mặc người ta chết ngoài ấy. |
| DE-06 | Ông | Ừ. Ông thấy. |
| DE-07 | [Tên] *[sửa]* | ~~Người như thế không đáng được hiểu.~~ Loại người như thế, hiểu làm gì cho mệt. |
| DE-08 | Ông *[sửa]* | Người gác cổng ấy chắc cũng từng mất người nhà. |
| DE-09 | (chọn) *[sửa]* | Mất người nhà thì được đẩy người khác ra chết à? / Sao lúc nào ông cũng bênh họ thế? |
| DE-10 | Ông *[chọn câu 1; sửa]* | Ông có bảo thế đâu. |
| DE-11 | Ông *[chọn câu 1; sửa: bỏ câu cách ngôn]* | ~~Muốn chém thì chém. Nhưng chém xong phải biết mình đã chém ai.~~ Mai con có gặp họ thì nhìn cho kỹ đã. Rồi muốn làm gì thì làm. |
| DE-12 | Ông *[chọn câu 2; sửa]* | ~~Ông có bênh đâu. Ông chỉ nhớ.~~ Ông có bênh ai. |
| DE-13 | [Tên] *[chọn câu 2; sửa]* | Thế ông nghĩ gì? |
| DE-14 | Ông *[chọn câu 2; sửa: lảng sang bữa cơm]* | Ăn đi, cơm nguội rồi. |
| DE-15 | [Tên] *[sửa]* | Mai con lên Bạch Sơn. Phải có thuốc cho Lúa. Gặp đứa nào đóng cổng thì con hỏi cho ra nhẽ. |
| DE-16 | (bóng) ông lão | ... |
| DE-17 | Ông | Ngủ đi. Mai đi sớm. |
| DE-18 | Lúa *[sửa: người ngoài gặp ông rồi quên]* | Bác ơi... bác tên gì ấy nhỉ? Cháu quên mất. |
| DE-19 | Ông | Cứ gọi là ông. |
| DE-20 | Lúa | ...Dạ. |
| DE-21 | (việc) | Đi ngủ |
| DE-22 | (nút) | Xem / Đi ngủ |
| DE-23 | (dẫn) cái bát *[sửa lần 2: tác giả chọn để mười cái bát, mỗi học trò một cái, cùng số với mười cái móc áo; thay cho bản "một phần cơm để dành" ở lần 5]* | Mười cái bát úp sau mâm, cái nào cũng sạch. Bữa tối nào ông cũng bày đủ mười cái, chẳng bao giờ nói để cho ai. |
| DE-24 | (dẫn) móc áo | Mười cái móc gỗ cũ trong ánh đèn. Không cái nào treo gì. |
| DE-25 | (dẫn) cây xà | Cây xà chính. Ông lại vừa lau nó. |

*(Sau đó là cảnh không lời: ông lão đặt tay lên cây xà chính trước khi đi ngủ.)*

---

## G. Lên đường và kết demo

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| LD-01 | (thẻ) | Rạng sáng hôm sau |
| LD-02 | Ông | Cơm nắm đây. Đi đường xa phải ăn. |
| LD-03 | Ông *[đưa thanh kiếm trên vách]* | Của người khách bỏ quên. Cùn rồi, nhưng còn hơn cái rìu. |
| LD-04 | [Tên] | Ông giữ nhà nhé. Con đi ít lâu thôi. |
| LD-05 | [Tên] *[tới cột mốc]* | Ông không đi tiếp à? |
| LD-06 | Ông | Ông không đi xa được. Chân yếu. |
| LD-07 | Ông | Đi đi. Ông chờ. |
| LD-08 | (thẻ) | **THẬP TỰ** / Đoạn Nghiệt |
| LD-09 | (thẻ) | ~~Hết phần Mở đầu. Cảm ơn đã chơi bản thử nghiệm.~~ *(bỏ 2026-10-15: Mở Đầu nối thẳng sang Bạch Sơn, Q50)* |

---

## H. Giao diện chung

| Mã | Chỗ | Nội dung |
|---|---|---|
| UI-01 | Tiêu đề khung việc | VIỆC CẦN LÀM |
| UI-02 | Dòng phím ở góc màn hình | WASD di chuyển · Shift chạy · Space / E tương tác · Esc tạm dừng |
| UI-03 | Nút tương tác | [Space]  *(kèm tên việc, ví dụ "[Space]  Chẻ củi")* |
| UI-04 | Khung thoại | ▼ *(mũi tên chờ bấm tiếp; lựa chọn đang chọn nằm trên thanh sơn mài sáng hơn, không còn dấu ◆)* |
| UI-05 | Bảng tạm dừng | Tạm dừng / Tiếp tục / Thiết lập / Về màn hình chính / Thoát game |
| UI-06 | Bảng thiết lập | Thiết lập |
| UI-07 | Bảng thiết lập | Âm nhạc |
| UI-08 | Bảng thiết lập | Hiệu ứng |
| UI-09 | Bảng thiết lập | Tốc độ chữ |
| UI-10 | Bảng thiết lập | Toàn màn hình (F11) |
| UI-11 | Bảng thiết lập | Hỗ trợ bấm nhịp (khung bấm rộng hơn) |
| UI-12 | Bảng thiết lập | Đồ họa cao (sương, tia nắng) |
| UI-13 | Màn tiêu đề, tựa trên trời *[mới, 2026-10-13]* | 十字 *(viết bút lông)* · THẬP TỰ · ĐOẠN NGHIỆT *(thay cho TT-01, TT-02 ở màn tiêu đề; không còn màn chờ riêng, không có biển tên nước, không có "Đang tải")* |

---

## I. Bạch Sơn (bản thử) *[mới, 2026-10-12]*

*[Viết lại 2026-10-14: tác giả chê lời Bạch Sơn "lỏ" và cho viết lại toàn bộ theo brief `docs/xuat/bach_son_viet_lai/gui_chatgpt.md`. 175 dòng đổi, đã nạp vào game (`tools/text/bs_text.py import`); bản trả về lưu ở `docs/xuat/bach_son_viet_lai/ban_moi_lan1..4.txt`. Sự việc, mã dòng, thứ tự giữ nguyên.]*

Đoạn đầu chương Bạch Sơn, mở riêng từ màn hình tựa bằng nút **"Bạch Sơn (bản thử)"**. Toàn bộ là ĐỀ XUẤT (xem `docs/N_bach_son.md` mục 16). Cùng quy ước như Mở đầu: không ai gọi nhân vật chính bằng từ chỉ giới; người lớn gọi "cháu" hoặc không gọi. Tên nhân vật phụ (bà Lành, Cỏ, Diệu, Mạnh và mẹ, bà Sương, lão Cẩn, khám sư) là tên đề xuất.

**Lên núi**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-01 | (thẻ) | Bạch Sơn / Ba ngày sau khi rời Vô Danh Cốc |
| BS-02 | Mạnh | Qua bãi này là tới trại. |
| BS-03 | Mạnh | Đừng nhìn mấy pho tượng lâu quá. |
| BS-04 | [Tên] | Họ là ai? |
| BS-05 | Mạnh | Người bị đuổi ra đấy. Trắng Tay chạm vào đầu thì thành thế. |
| BS-06 | (nút tương tác, pho tượng bên đường) | Xem |
| BS-07 | (việc cần làm) | Theo Mạnh lên Trại Ngoài Cổng |
| BS-08 | Mạnh | Đấy. Bạch Sơn. |
| BS-09 | [Tên] | Trắng thật. |
| BS-10 | Mạnh | Ở dưới này, ngày nào cũng phải ngước lên nhìn nó. |

**Xem đồ vật, nơi chốn (tự đi quanh)**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-11 | (xem: porc) | Một pho người bằng sứ, quay mặt về phía cổng. Dải men lam bịt ngang mắt. |
| BS-12 | (xem: nong) | Cái nong đựng những mảnh sứ bằng ngón tay. Mảnh nào cũng khắc một năm. Bà Lành bảo mỗi mảnh là một người. |
| BS-13 | (xem: khe) | Mấy khối đá xám nằm dưới lớp vôi bong. Trên một phiến đá có khắc chữ "Khê" và ba vạch. |
| BS-14 | (xem: well) | Giếng do người trong trại tự đào. Nước lợ, có vị vôi. |
| BS-15 | (xem: glaze) | Vệt đất trắng bóng như men, chạy từ chân núi về phía trại. Giẫm lên nghe giòn như vỏ trứng. |
| BS-16 | (xem: stream) | Nước đục chảy từ cống dưới chân tường thành xuống. Người trong trại vẫn múc để giặt. |

**Nói chuyện trong trại**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-17 | Cỏ | Trên bậc cổng có cái chậu trắng to lắm. Người trong ấy rửa tay ở đấy. |
| BS-18 | Cỏ | Em chưa rửa ở đấy bao giờ. Bà Lành bảo người dưới này không được lại gần. |
| BS-19 | Diệu | Đứng xích ra, chắn hết ánh sáng rồi. Tôi đang giã thuốc. |
| BS-20 | Diệu | Ông lính trên tường ấy à? Tối nào ông ấy cũng đứng đó. Kệ ông ấy. |
| BS-21 | Mẹ Mạnh | Cảm ơn cháu đã đưa nó về. |
| BS-22 | Mẹ Mạnh | Nhà bác bị đuổi theo sắc mới. Chú nó bị đuổi mấy năm trước rồi, giờ đến lượt hai mẹ con bác. |

**Trại Ngoài Cổng**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-23 | Bà Lành | Thằng Mạnh! Mày còn sống à? |
| BS-24 | Mạnh | Con đưa Lúa tới Vô Danh Cốc rồi, bà ạ. |
| BS-25 | Bà Lành | Mẹ mày ngồi ngoài bếp chờ mày từ hôm đi đến giờ đấy. Ra đi. |
| BS-26 | Bà Lành | Còn đây là ai? Mặt mũi sạch sẽ thế kia, đâu phải người ở trại. |
| BS-27 | [Tên] | Cháu ở Vô Danh Cốc. Cháu với Mạnh đưa Lúa về đấy. |
| BS-28 | Bà Lành | Con bé học thuốc ấy à? Nó còn sống thật à? |
| BS-29 | [Tên] | Còn ạ. Chỗ trắng trên chân thôi lan rồi. |
| BS-30 | Bà Lành | ...Thế thì tốt. Ở đây, bà chưa thấy ai thôi lan bao giờ. |
| BS-31 | Bà Lành | Lên đây làm gì? |
| BS-32 | [Tên] | Cháu muốn gặp người dựng cái cổng kia. |
| BS-33 | Bà Lành | Lên đấy thì phải thử tro. Thử xong mà bị đuổi thì xuống đây ở với bà. |
| BS-34 | Bà Lành | Mà cháu lên đúng lúc xui rồi. Trên ấy vừa ra sắc mới, nhà nào có người bị đuổi thì họ hàng cũng phải ra nốt. |
| BS-35 | Bà Lành | Năm ngày nữa là Lễ Quét Vôi. Đợt người tiếp theo bị đuổi đúng hôm ấy. |
| BS-36 | (nút tương tác) | Nói chuyện *(với người)* · Xem *(với đồ vật)* |
| BS-37 | (nút tương tác, bếp lửa) | Ngồi xuống bếp |
| BS-38 | (việc cần làm) | Đi quanh trại. Xong rồi thì ra bếp ngồi với bà Lành. |

**Bữa tối và trận đêm**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-39 | Bà Lành | Ăn đi. Mắm cá suối đấy. |
| BS-40 | [Tên] | ...Ngon ạ. |
| BS-41 | Bà Lành | Trên kia cái gì lên men cũng bị chê là thối. Thối mà ngon thế này thì bà cứ ăn. |
| BS-42 | Bà Lành | Ăn xong thì vào lều ngủ. Đêm đừng có ra ngoài. |
| BS-43 | Cỏ | Bà ơi! |
| BS-44 | (trận, câu mở) | Mảnh Sành bò ra từ Rãnh Sứ, đang bò về phía lều của Cỏ! |
| BS-45 | (dẫn) | Ngã xuống rồi. Đứng dậy lần nữa? |
| BS-46 | (lựa chọn) | Thử lại |
| BS-47 | Bà Lành | Đêm nào cũng thế. Có đêm nó chỉ cào cửa lều thôi. |
| BS-48 | Bà Lành | Có đêm... à mà thôi. |
| BS-49 | Cỏ | Mai lên cổng à? Rửa tay ở cái chậu ấy rồi về kể em nghe nhé. |

**Đoàn xe trắng**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-50 | Bà Sương | Ai biết gánh thì lại đây. Người của tôi bỏ về giữa đường rồi. |
| BS-51 | [Tên] | Cháu gánh được. |
| BS-52 | Bà Sương | Đưa tay đây xem. |
| BS-53 | Bà Sương | Tay chai thế này thì gánh được. Lên cổng cứ đứng sau tôi, đừng nói gì. |
| BS-54 | Bà Lành | Bà Sương năm nào cũng lên một lần. Lúc đi xe rỗng, lúc về xe đầy. |
| BS-55 | [Tên] | Đầy gì ạ? |
| BS-56 | Bà Lành | Người chứ gì. Nghe bảo ai lên xe thì được đưa đi chữa bệnh. |
| BS-57 | (việc cần làm) | Gánh hòm thuốc, theo bà Sương lên Sân Tro |

**Cổng Trắng, Thử Tro**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-58 | Khám sư | Người tiếp theo. Đưa tay đây. |
| BS-59 | Khám sư | Trắng. |
| BS-60 | Khám sư | Bà Sương. Năm nay cũng lên à? |
| BS-61 | Bà Sương | Năm nào tôi chẳng lên. |
| BS-62 | Khám sư | Trắng. |
| BS-63 | Khám sư | Đưa tay đây. Ngửa bàn tay ra. |
| BS-64 | Khám sư | Giữ yên. |
| BS-64b | (bảng thử tro, tiêu đề) | Lòng bàn tay, cổ tay |
| BS-65 | (dấu son trên bảng thử tro) | XÁM |
| BS-66 | Khám sư | ...Xám. |
| BS-67 | Bà Sương | Người gánh hòm thuốc cho tôi đấy. Gánh nặng thì tay nứt thôi. |
| BS-68 | Khám sư | Sổ ghi xám thì phải giữ lại. |
| BS-69 | Lão Cẩn | Tro ướt. |
| BS-70 | Khám sư | Dạ? |
| BS-71 | Lão Cẩn | Tay đổ mồ hôi thì tro không ăn. Thử lại đi. |
| BS-72 | (dấu son trên bảng thử tro) | TRẮNG |
| BS-73 | Khám sư | ...Trắng. |
| BS-74 | Lão Cẩn | Đi đi. |

**Tầng Rửa**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-75 | Bà Sương | Rửa tay đi. Ở đây không rửa là người ta nhìn đấy. |
| BS-76 | (việc cần làm) | Rửa tay ở chậu nước trước cửa nhà |
| BS-76b | (nút tương tác) | Rửa tay |
| BS-77 | (dẫn) | Nước lạnh. Chảy từ tầng trên xuống. |

**Kết bản thử**

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-78 | (thẻ) | Bốn ngày nữa là tới Lễ Quét Vôi |
| BS-79 | (thẻ) | Hết bản thử nghiệm. Cảm ơn đã chơi. *(ĐỀ XUẤT 2026-10-15: thẻ cũ lộ đường dẫn tài liệu "docs/N_bach_son.md" và chữ nội bộ "Biến thể (b)" cho người chơi; Mở Đầu nay nối thẳng sang Bạch Sơn nên lời cảm ơn chuyển về thẻ cuối Bạch Sơn)* |

**Cổng Trắng: ba đường** *[mới, 2026-10-13]*

Sau BS-68, nhân vật chính chọn ai trả giá cho việc qua cổng (A2 Q43, `docs/N_bach_son.md` 8.2 và 9.6). Nhịp con lắc quyết định còn đường nào: tay vững thì có cả ba, tay run thì không có đường "Im lặng". BS-69 tới BS-74 giờ chỉ thuộc đường "Im lặng".

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-80 | (thanh con lắc, gợi ý) | Space khi tay lắc ra mép |
| BS-81 | (thanh con lắc, đếm) | Tay yên: [số] / 5 |
| BS-82 | (lựa chọn, chỉ khi vệt nhạt) | (Im lặng) |
| BS-83 | (lựa chọn) | Cháu bị Nghiệt chạm ở cửa đèo. |
| BS-84 | (lựa chọn) | Cháu đỡ hòm từ tay anh ấy suốt đường. |

*Đường "Im lặng":* BS-69 tới BS-74, rồi trong thành:

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-85 | Bà Sương | Lão gác ấy làm thế nhiều lần rồi. Sớm muộn gì cũng có ngày bị bắt. |

*Đường "Nói thật":*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-86 | Bà Sương | Tôi thuê người ở trại hôm qua. Chuyện của người ấy, tôi không biết. |
| BS-87 | Khám sư | Giữ lại. |
| BS-88 | (thẻ) | Đêm ở Sân Tro |
| BS-89 | (dẫn) | Dưới chân dốc có tiếng gõ trên sứ, lúc thưa lúc dày. Cổng sau lưng vẫn đóng chặt. |
| BS-90 | Khám sư | Thưa Chánh Ty. |
| BS-91 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Khai thật với khám sư à? |
| BS-92 | Chánh Ty | Ba trăm năm nay, chưa ai đứng ở cổng này tự nhận mình bị Nghiệt chạm. |
| BS-93 | Chánh Ty | Cho vào. Sáng nào cũng lên Dinh Ty cho tôi xem tay. |
| BS-94 | Bà Sương *[trong thành]* | Từ giờ đứng cách tôi ra một quãng. |

*Đường "Đổ cho người khác":*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-95 | Khám sư | Anh kia. Đưa tay đây. |
| BS-96 | Anh Vững *[người khiêng hòm]* | Tay tôi... Gánh hòm thì tay nứt chứ. |
| BS-97 | (bảng thử tro, tiêu đề) | Tay anh Vững |
| BS-98 | Khám sư | Xám. Giữ lại. |
| BS-99 | Khám sư | Tay người này dính lây từ tay anh ta. Rửa lại. |
| BS-100 | Khám sư | ...Trắng. |
| BS-101 | Anh Vững | Bà Sương, tôi gánh hòm cho bà sáu năm rồi. |
| BS-102 | Bà Sương | Đi thôi. |
| BS-103 | Người đàn bà *[vợ anh Vững, trong thành]* | Bà Sương, anh Vững nhà em đâu rồi? |
| BS-104 | Bà Sương | Bị giữ lại ở cổng. |

### Phần C: bốn ngày trong thành *[mới, 2026-10-13]*

Sau cổng, bốn ngày tới Lễ Quét Vôi, mỗi ngày ba buổi (`scripts/story/bach_son_city.gd`). Mọi câu dưới đây là ĐỀ XUẤT.
*Đầu mỗi buổi:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-105 | (dẫn) | Ngoài Sân Tro có tiếng roi quất. Người qua đường bảo lão gác già bị phạt vì làm ướt tro cho người lạ. |
| BS-106 | Chị Gấm | Đêm qua tay nó thò vào tận lều. Ông Bảy bán than hóa sứ ngay trước cửa lều. |

*Việc nhỏ, ngồi đợi:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-107 | (dòng nổi) | Tối rồi. Cổng các tầng đóng hết rồi. |
| BS-108 | Thư lại | Không có việc thì đi chỗ khác. |
| BS-109 | (dẫn) | Ngồi bên bể rửa, nhìn người ta rửa tay. *[một trong các câu, theo buổi]* |
| BS-110 | (dẫn) | Ngồi đợi tiếng chuông cổng. *[một trong các câu, theo buổi]* |
| BS-111 | (dẫn) | Về chỗ ngủ trong nhà kho của bà Sương. *[một trong các câu, theo buổi]* |

*Rửa tay ở bể:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-112 | (dẫn) | Nước lạnh. |

*Người áo lam (Mắt Ty): báo Ty:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-113 | Người áo lam | Người gánh hòm cho bà Sương đấy à? |
| BS-114 | Người áo lam | Ở đây thấy gì thì báo cho Ty. Báo đúng, Ty sẽ nhớ. |
| BS-115 | Người áo lam | Thấy gì thì cứ báo. |
| BS-116 | (lựa chọn) | Ông già ở Nhà Rửa. |
| BS-117 | (lựa chọn) | Chị Gấm ở Nhà Rửa. |
| BS-118 | (lựa chọn) | Không thấy ai. |
| BS-119 | Người áo lam | Ừ. Cứ để Ty lo. |

*Gánh hòm cho bà Sương; Sổ Tro ở Dinh Ty:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-120 | Bà Sương | Lên Y Viện lấy mấy gói thuốc cho tôi. *[một trong các câu, theo buổi]* |
| BS-121 | Bà Sương | Mang hòm ra Sân Tro. Người của Hội Y đang đợi. *[một trong các câu, theo buổi]* |
| BS-122 | Bà Sương | Hòm hôm nay nhẹ đấy. Đi nhanh rồi về. *[một trong các câu, theo buổi]* |
| BS-123 | (dẫn) | Hòm nặng trĩu. Người qua đường nhìn cái hòm, chẳng ai nhìn người đang gánh. |
| BS-124 | Bà Sương | Hôm nay mang hòm lên Dinh Ty. Hội Y phải trình sổ thuốc cho Ty. |
| BS-125 | Thư lại | Đặt hòm ở kia. Đứng chờ. |
| BS-126 | Thư lại | Chánh Ty gọi. Đừng động vào thứ gì. |
| BS-127 | (thẻ tranh, tiêu đề) | Sổ Tro, Tầng Rửa |
| BS-128 | (dẫn) | Mỗi dòng ghi một người, có ba cột: trắng, xám, đen. Lật mấy chục trang, cột đen vẫn trống trơn. |
| BS-129 | (thẻ tranh, tiêu đề) | Các sắc, cuối tập |
| BS-130 | (dẫn) | Cuối tập là các tờ sắc. Nét chữ tờ nào cũng giống nhau. Dòng cuối ghi "Chánh Ty Ngọc Khiết soạn", bên dưới là ấn của Điện. |
| BS-131 | (thẻ tranh, tiêu đề) | Quyển mỏng kẹp giữa |
| BS-132 | (dẫn) | Kẹp giữa Sổ Tro là một quyển mỏng. Bên cạnh mỗi tên là một con số. Trang cuối đóng dấu của một nhà buôn Vạn Thư. |
| BS-133 | (thẻ tranh, tiêu đề) | Sổ Tro, tập đầu |
| BS-134 | (dẫn) | Tập đầu tiên, năm PK 21. Mực đã nhạt: "Xám thì giữ lại ở Nhà Rửa, đợi Bà." |
| BS-135 | (thẻ tranh, tiêu đề) | Sổ Tro, tập PK 395 |
| BS-136 | (dẫn) | Tập năm PK 395. "Nhà (tro che mất tên), Tầng Rửa, Luật Cả Nhà. Năm người. Trẻ nhỏ, chưa tên." |
| BS-137 | Thư lại | Xong rồi thì đi. |
| BS-138 | Bà Sương | Tối mai ra sau Dinh Ty. Có mấy cái hòm cần khiêng. |

*Y Viện, bà Mẫn:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-139 | Bà Mẫn | Đi đi. Ở đây lâu quá, người ta để ý đấy. |
| BS-140 | Bà Mẫn | Ai đấy? Người lạ à? Từ Vô Danh Cốc lên sao? |
| BS-141 | Bà Mẫn | Lúa còn sống không? |
| BS-142 | Nhân vật chính | Còn ạ. Chỗ trắng trên chân thôi lan rồi. |
| BS-143 | Bà Mẫn | ...Ừ. |
| BS-144 | Bà Mẫn | Nó theo bà xuống Cửa Cống chữa cho người trong trại. Người ta bắt nó chứ không bắt bà. Bà còn chữa cho nhà Chánh Ty cơ mà. |
| BS-145 | Nhân vật chính | Thử tro ở cổng thì biết được gì ạ? |
| BS-146 | Bà Mẫn | Ngồi xuống đây. |
| BS-147 | (thẻ tranh, tiêu đề) | Cái chén men rạn |
| BS-148 | (thẻ tranh, chú thích) | Bà xoa tro lên chén, dội nước. Men trôi sạch, kẽ rạn còn đen. |
| BS-149 | Bà Mẫn | Tro có biết Nghiệt là gì đâu. Nó chỉ chui vào kẽ thôi. Da bị Nghiệt chạm cũng có lớp men rạn như cái chén này, nên tro mới bám vào. |
| BS-150 | (bảng thử tro, tiêu đề) | Tay bà Mẫn |
| BS-151 | (dấu) | XÁM |
| BS-152 | Bà Mẫn | Tay bà ngâm thuốc suốt ba mươi năm, nứt hết cả rồi. Ra cổng thử tro, bà cũng bị tính là xám thôi. |
| BS-153 | Bà Mẫn | Ba trăm năm nay, trong thành có ai bị Nghiệt chạm đâu. Thế mà năm nào cũng có người bị thử ra xám. |
| BS-154 | Bà Mẫn | Tối muốn xuống trại thì tìm Cửa Cống ở góc quảng trường. Cẩn thận, đừng để người áo lam trông thấy. |

*Đền Thầy:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-155 | Người coi đền | Tối nhớ đặt chén lên bậc cửa. |
| BS-156 | Người coi đền | Rửa tay chưa? Rồi thì vào đi. |
| BS-157 | (thẻ tranh, tiêu đề) | Tranh thờ |
| BS-158 | Người coi đền | Thầy của Bà đấy. Một nhát chém, người sạch một bên, người bẩn một bên. |
| BS-159 | Nhân vật chính | Ông cháu bổ củi đâu có chém kiểu ấy. |
| BS-160 | Người coi đền | Ông cháu thì biết cái gì. |
| BS-161 | (thẻ tranh, chú thích) | Bên trái người áo trắng đứng thẳng. Bên phải người tối màu cúi rạp. Ở giữa là nét trắng. |
| BS-162 | (dẫn) | Nét chém trong tranh không dừng lại ở đâu. Nó kéo thẳng xuống tận mép tranh. |
| BS-163 | Người coi đền | Sứ Giả ngoài cổng cũng từ lòng thành của dân mình mà ra. Nó có đụng đến ai trong thành đâu. |
| BS-164 | Người coi đền | Tối về nhớ đặt một chén lên bậc. Nhà nào cũng đặt cả. |

*Nhà Rửa, ông Sẹo và chị Gấm:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-165 | Chị Gấm | Sáng nay người của Ty xuống đưa ông ấy ra cổng. Ông ấy chẳng mang theo thứ gì. |
| BS-166 | Chị Gấm | Ông ấy ngủ rồi. Cứ để ông ấy ngủ. |
| BS-167 | Chị Gấm | Tìm ai? Đây là chỗ giặt đồ liệm. Người trên kia chẳng xuống đây đâu. |
| BS-168 | Ông Sẹo | Cứ để người ta vào, Gấm. |
| BS-169 | Ông Sẹo | Người gánh hòm cho mụ Sương phải không? Ngồi đi. Khoan, đừng ngồi chỗ ấy. Chỗ lõm kia là chỗ Bà từng ngồi. |
| BS-170 | Nhân vật chính | Bà nào ạ? |
| BS-171 | Ông Sẹo | Bà trên Điện ấy. |
| BS-172 | Ông Sẹo | Năm tôi bảy tuổi, tay bị Nghiệt chạm. Thử tro ra xám, người ta đưa tôi xuống đây. |
| BS-173 | Ông Sẹo | Bà ngồi đúng chỗ ấy, nắm cổ tay tôi rồi cạo lớp men đi. Chỉ còn cái sẹo này. |
| BS-174 | Nhân vật chính | Tay ra xám mà không bị đuổi ạ? |
| BS-175 | Ông Sẹo | Hồi ấy xám thì giữ lại, chờ Bà rửa men. Sau này Bà không xuống nữa. Từ đó, cứ xám là bị đuổi. |
| BS-176 | Chị Gấm | Ông lại kể chuyện ngày xưa rồi. |
| BS-177 | Ông Sẹo | Cái chén ngoài bậc là tôi đặt cho Bà. Không phải cho thứ ngoài cổng ấy. |

*Xe trắng sau Dinh Ty:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-178 | Bà Sương | Đặt hòm lên xe. Cẩn thận đấy. |
| BS-179 | (dẫn) | Người áo lam dẫn ba người ra từ cửa sau Dinh Ty. Tay họ bị trói lỏng. Họ trèo lên xe rồi chui xuống dưới tấm vải trắng. |
| BS-180 | Người áo lam | Ba người. Đúng như trong sổ. |
| BS-181 | Bà Sương | Ba người. |
| BS-182 | (dẫn) | Anh Vững ngồi ở đầu xe. Anh cúi mặt, không ngẩng lên. |
| BS-183 | Nhân vật chính | Họ đi đâu vậy? |
| BS-184 | Bà Sương | Đi chữa bệnh. Ở Vạn Thư, người ta hiểu về men hơn ở đây. Tôi đã cứu được hai người rồi. |
| BS-185 | Nhân vật chính | Thế còn những người khác? |
| BS-186 | Bà Sương | Về ngủ đi. |

*Qua Cửa Cống xuống trại (tối):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-187 | (dẫn) | Cửa Cống thấp, phải cúi gập người mới chui qua được. Nước thải ngập đến đầu gối. |
| BS-188 | Bà Lành | Lại xuống đây à? Ngồi đi. Trên ấy có ai lo cho cháu ăn đâu. |
| BS-189 | Nhân vật chính | Bà ơi, năm PK 395 có nhà nào ở Tầng Rửa bị đuổi, mang theo một đứa bé chưa đặt tên không? |
| BS-190 | (thẻ tranh, tiêu đề) | Cái nong của bà Lành |
| BS-191 | (thẻ tranh, chú thích) | Mỗi mảnh thẻ tro là một người. Năm mảnh xâu chung một sợi dây. |
| BS-192 | Bà Lành | Nhà ông Thục. Năm người, đủ cả năm mảnh đây. |
| BS-193 | Bà Lành | Đứa bé không qua nổi mùa đông đầu tiên. |
| BS-194 | Bà Lành | Sao tự dưng hỏi chuyện ấy? |
| BS-195 | Nhân vật chính | ...Không có gì ạ. |
| BS-196 | Bà Lành | Năm ấy có đoàn người phương bắc ở nhờ trại mấy tuần. Họ mang theo một đứa bé, chẳng cho ai bế. Khăn quấn nó có ô vuông như bàn cờ. Rồi cả đoàn đi về phía đèo. |
| BS-197 | Diệu | Bố tôi bị đánh roi ở Sân Tro. Chỉ vì cho một người lạ qua cổng. |
| BS-198 | Cỏ | Bà ơi! Nó lại xuống rồi! |
| BS-199 | (trận, câu mở) | Tay trắng thò vào lều. Mảnh Sành bò theo sau. |
| BS-200 | (dẫn) | Ngã xuống rồi. Đứng dậy lần nữa? |
| BS-201 | Bà Lành | Mấy đêm nay nó xuống sớm hơn rồi. |
| BS-202 | (dẫn) | Phải về qua Cửa Cống trước khi chuông cổng vang lên. |

*Bị thử tro lại (thanh Nghi đầy):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-203 | Khám sư | Người gánh hòm cho bà Sương phải không? Có người báo lên rồi. Đưa tay đây. |
| BS-204 | (dấu) | XÁM |
| BS-205 | Khám sư | ...Xám. |
| BS-206 | (lựa chọn) | Cháu bị Nghiệt chạm ở cửa đèo. |
| BS-207 | (lựa chọn) | Tay cháu nứt vì gánh hòm. |
| BS-208 | (lựa chọn) | Chị Gấm ở Nhà Rửa cũng bị xám, sao chị ấy vẫn ở trong thành? |
| BS-209 | Khám sư | ...Giữ lại. |
| BS-210 | (dẫn) | Bị giữ ở Dinh Ty đến chiều. Không ai hỏi thêm câu nào. |
| BS-211 | Khám sư | ...Xám nhạt. Đi đi. |
| BS-212 | Khám sư | Gấm nào? ...Thôi, đi đi. Ty sẽ xuống Nhà Rửa. |

*Sổ ghi: điều thấy (mỗi dòng ghi khi thấy):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-213 | (sổ ghi) | Bà Mẫn xoa tro lên cái chén men rạn rồi dội nước. Kẽ rạn vẫn đen. Da bị Nghiệt chạm cũng có lớp men rạn như thế. |
| BS-214 | (sổ ghi) | Bà Mẫn xoa tro lên tay mình. Ba mươi năm ngâm thuốc, tay bà nứt hết. Thử tro cũng ra xám. |
| BS-215 | (sổ ghi) | Sổ Tro, cột "đen" của người trong thành. Lật mấy chục tập vẫn không có dòng nào. |
| BS-216 | (sổ ghi) | Sắc suốt ba mươi lăm năm nay đều cùng một nét chữ. Cuối mỗi tờ ghi "Chánh Ty Ngọc Khiết soạn", bên dưới đóng ấn của Điện. |
| BS-217 | (sổ ghi) | Một quyển sổ mỏng kẹp trong Sổ Tro. Bên cạnh tên mỗi người là một con số. Trang cuối đóng dấu của một nhà buôn Vạn Thư. |
| BS-218 | (sổ ghi) | Sổ Tro tập đầu, năm PK 21: "Xám thì giữ lại ở Nhà Rửa, đợi Bà." |
| BS-219 | (sổ ghi) | Sổ Tro tập PK 395. Một nhà ở Tầng Rửa, năm người. Dòng cuối ghi "trẻ nhỏ, chưa tên". Cũng năm ấy, mình bị bỏ ở cửa đèo. |
| BS-220 | (sổ ghi) | Bà Lành kể, đứa bé nhà ấy không qua được mùa đông đầu. Năm đó có đoàn người phương bắc mang theo một đứa bé quấn khăn kẻ ô bàn cờ, đi về phía đèo. |
| BS-221 | (sổ ghi) | Tối hôm ấy, sau Dinh Ty, người của Ty dẫn ba người bị đuổi lên xe trắng. Bà Sương trả tiền. |
| BS-222 | (sổ ghi) | Đền Thầy có bức tranh vẽ một nhát chém chia người sạch và người bẩn. Người coi đền bảo Sứ Giả ngoài cổng sinh ra từ lòng thành của dân. |
| BS-223 | (sổ ghi) | Lúc tay nó chạm vào mình ở trại, mình thấy những ô cửa sáng đèn trong thành. Người đứng sau lớp giấy nhìn xuống. Trên bậc cửa nhà nào cũng có chén sứ. |
| BS-224 | (sổ ghi) | Ông Sẹo kể, năm bảy tuổi ông bị Nghiệt chạm. Bà tự tay rửa men cho ông ở Nhà Rửa. Rồi có một năm Bà không xuống nữa. |
| BS-225 | (sổ ghi) | Anh Vững ngồi ở đầu xe trắng. Anh không ngẩng lên. |
| BS-226 | (sổ ghi) | Đêm cuối, mình không xuống trại. Tay nó thò tận vào lều. Ông Bảy bán than hóa sứ ngay trước cửa lều. |

*Sổ ghi: Nhận ra (hai điều thấy ghép lại; năm điều đầu tính để mở cảnh ở Điện):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-227 | (nhận ra) | Cái cổng có lý do để tồn tại. Tro phát hiện được dấu Nghiệt chạm, nhưng tay nứt vì vôi, thuốc hay gánh cũng ra xám. |
| BS-228 | (nhận ra) | Bà đóng ấn mà không nhìn. Sắc nào cũng do Chánh Ty soạn. Cột đen trống suốt ba trăm năm mà sắc vẫn được ban xuống. |
| BS-229 | (nhận ra) | Người bị đuổi không biến mất. Tên họ bị bán, rồi họ bị đưa lên xe trắng sang Vạn Thư. |
| BS-230 | (nhận ra) | Cả thành thờ thứ đang săn người ngoài cổng. Nó sinh ra từ chính những ô cửa ấy. |
| BS-231 | (nhận ra) | "Xám thì giữ lại" từng là giữ lại để chữa, Bà giữ lại để cứu họ chứ đâu đuổi họ đi. |
| BS-232 | (nhận ra) | Đứa trẻ chưa tên trong sổ năm PK 395 không phải mình. |

*Giao diện phần C:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-233 | (thẻ đầu ngày) | Ngày 1 / Ngày 2 / Ngày 3 / Ngày 4 |
| BS-234 | (thẻ đầu ngày, dòng dưới) | Bốn ngày tới Lễ Quét Vôi / Ba ngày tới Lễ Quét Vôi / Hai ngày tới Lễ Quét Vôi / Mai là Lễ Quét Vôi |
| BS-235 | (dòng việc) | [Bốn ngày tới Lễ Quét Vôi]. Đi đâu tùy mình (Tab: Sổ ghi) |
| BS-236 | (bảng góc phải) | Ngày 1 · Sáng / Chiều / Tối |
| BS-237 | (bảng góc phải) | Nghi |
| BS-238 | (bảng góc phải) | Tab: Sổ ghi |
| BS-239 | (sổ ghi, tiêu đề) | Sổ ghi |
| BS-240 | (sổ ghi, mục) | Nhận ra |
| BS-241 | (sổ ghi, mục) | Điều thấy |
| BS-242 | (sổ ghi) | (chưa có) |
| BS-243 | (sổ ghi) | Tab: đóng |
| BS-244 | (dòng nổi) | Sổ ghi: thêm một điều thấy (Tab) |
| BS-245 | (dòng nổi) | Nhận ra: [câu nhận ra] |
| BS-246 | (dòng nổi) | Nghi tăng |
| BS-247 | (dòng nổi) | Nghi giảm |
| BS-248 | (lời nhắc) | Rửa tay |
| BS-249 | (lời nhắc) | Gánh hòm cho bà Sương |
| BS-250 | (lời nhắc) | Nói chuyện |
| BS-251 | (lời nhắc) | Vào Nhà Rửa |
| BS-252 | (lời nhắc) | Chui qua Cửa Cống |
| BS-253 | (lời nhắc) | Lên Tầng Giữa |
| BS-254 | (lời nhắc) | Cổng tầng đã đóng |
| BS-255 | (lời nhắc) | Ngồi đợi tới chiều / tối / sáng mai |
| BS-256 | (lời nhắc) | Xuống Tầng Rửa |
| BS-257 | (lời nhắc) | Vào Y Viện |
| BS-258 | (lời nhắc) | Dinh Ty |
| BS-259 | (lời nhắc) | Lên Tầng Đền |
| BS-260 | (lời nhắc) | Ra sau Dinh Ty |
| BS-261 | (lời nhắc) | Xuống Tầng Giữa |
| BS-262 | (lời nhắc) | Vào Đền Thầy |
| BS-263 | (dòng nhịp, thử lại) | Space khi tay lắc ra mép |
| BS-264 | (dòng nhịp, đếm) | Tay yên |
| BS-265 | (lựa chọn, thua trận ở trại) | Thử lại |
| BS-266 | (thẻ cuối) | BẠCH ĐIỆN |
| BS-267 | (thẻ cuối, dòng dưới) | Sáng hôm sau, người của Ty gõ cửa nhà kho. Chánh Ty mời lên Bạch Điện. |
| BS-268 | (thẻ cuối) | Đã nhận ra [n] trong 5 điều. Hết bản thử nghiệm. Cảm ơn đã chơi. *(ĐỀ XUẤT 2026-10-15: thẻ cũ lộ đường dẫn tài liệu "docs/N_bach_son.md" và chữ nội bộ "Biến thể (b)" cho người chơi; Mở Đầu nay nối thẳng sang Bạch Sơn nên lời cảm ơn chuyển về thẻ cuối Bạch Sơn)* |

*Chữ viết trong hình (trang Sổ Tro, tranh; `tools/art/bs_cards.py`):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-269 | (trang sổ) | Tầng Rửa, tập PK 409 / Tầng Rửa, tập PK 410 / Tầng Rửa, tập PK 395 |
| BS-270 | (trang sổ, cột) | Trắng / Xám / Đen |
| BS-271 | (trang sổ) | Họ tên và nghề, ví dụ: Lý Thoa, thợ vôi (tên hai chữ, nghề: thợ vôi, thợ muối, giặt liệm, dọn cống, thợ gốm, gánh nước, thợ đá, lò sứ) |
| BS-272 | (sắc) | SẮC |
| BS-273 | (sắc PK 409) | Thầy thuốc nào đã chữa cho người nhiễm, từ nay coi như nhiễm. Khám sư các cổng thử lại ngay, không đợi năm. Năm PK 409. |
| BS-274 | (sắc PK 412) | Họ hàng của người đã bị đuổi phải ra khỏi cổng trước Lễ Quét Vôi. Không xét từng người. Năm PK 412. |
| BS-275 | (sắc) | Chánh Ty Ngọc Khiết soạn. |
| BS-276 | (ấn) | BẠCH ĐIỆN |
| BS-277 | (quyển mỏng) | Giao, mùa thu |
| BS-278 | (quyển mỏng) | Cộng, đủ số. Đã nhận. |
| BS-279 | (dấu nhà buôn) | VĂN LỤC / VẠN THƯ |
| BS-280 | (tập đầu) | Tập đầu, năm PK 21 |
| BS-281 | (tập đầu) | Lệ của Ty Khám: / Người bị Nghiệt chạm không vào. / Người bị Nghiệt đuổi không vào. / Đêm không mở cổng. / Xám thì giữ lại ở Nhà Rửa, đợi Bà. |
| BS-282 | (tập đầu, ghi chú dòng) | giữ lại ở Nhà Rửa. / giữ lại. Bà đã rửa. / [tên], trắng. / [tên], xám. / [tên], đen. |
| BS-283 | (tập PK 395) | Nhà [tro che] Luật Cả Nhà. Năm người. / Chồng, thợ muối / Vợ, giặt liệm / Mẹ chồng / Con trai, mười hai tuổi / Trẻ nhỏ, chưa tên. / không thử |

### Phần D: Bạch Điện *[mới, 2026-10-13]*

Sáng hôm sau hết phần C, Chánh Ty dẫn nhân vật chính lên Bạch Điện (`scripts/story/bach_son_palace.gd`). Bà Tâm không nhắc tới thầy (Q45). Mọi câu dưới đây là ĐỀ XUẤT.

*Quảng trường, sáng hôm sau: Chánh Ty tới:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-284 | Người áo lam | Thưa Chánh Ty, người này. |
| BS-285 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Người gánh hòm của bà Sương. |
| BS-286 | Người áo lam | [Một / Hai / Ba...] đêm chui qua Cửa Cống xuống trại. Có người thấy. |
| BS-287 | Người áo lam | Tự khai bị Nghiệt chạm. Thử lại vẫn xám. |
| BS-288 | Người áo lam | Lật Sổ Tro ở Dinh Ty lúc thư lại đi vắng. |
| BS-289 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Theo luật, hôm nay người này phải ra cổng. |
| BS-290 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Nhưng Bà muốn gặp người từ Vô Danh Cốc. |
| BS-291 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Đi sau tôi ba bước. Đừng để chạm vào ai. |

*Lên Bạch Điện:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-292 | (dẫn) | Lên mỗi tầng, người đi đường dạt sang hai bên. Không ai nhìn người đi sau Chánh Ty. |
| BS-293 | (dẫn) | Một bà già áo trắng đặt bát cơm lên bậc cửa rồi lùi vào trong. Bát cơm hôm qua vẫn còn nguyên. |
| BS-294 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Thưa Bà. Người từ Vô Danh Cốc. |
| BS-295 | Trong điện | Cho vào. |
| BS-296 | Trong điện | Ngọc Khiết, ở ngoài. |
| BS-297 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Thưa Bà, người này đã... |
| BS-298 | Trong điện | Ở ngoài. |

*Trong điện:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-299 | (dẫn) | Gian điện rộng, trống và lạnh. Tường trắng, chân tường ốp sứ. Một người đứng quay lưng bên chậu nước, đang rửa tay. |
| BS-300 | (thẻ tên) | BĂNG TÂM / Vị Tự của Bạch Sơn |
| BS-301 | Bà Tâm | Đứng đấy. |
| BS-302 | (dẫn) | Giữa hai người là một sải tay. Bà không bước lại gần. |
| BS-303 | Bà Tâm | Cho ta xem tay. |
| BS-304 | (bảng xem tay, tiêu đề) | Lòng bàn tay, chìa ra |
| BS-305 | (dẫn) | Bà nhìn rất lâu. Không cầm tay, cũng không nói gì về điều mình thấy. |
| BS-306 | Bà Tâm | Ngọc Khiết bảo con chui qua Cửa Cống. |
| BS-307 | Bà Tâm | Ngọc Khiết bảo con tự khai bị Nghiệt chạm. |
| BS-308 | Bà Tâm | Ngọc Khiết bảo con lật Sổ Tro. |
| BS-309 | Bà Tâm | Con lên Bạch Sơn làm gì? |
| BS-310 | Nhân vật chính | Đoàn của Lúa bị đuổi khỏi đây. Cái thứ ngoài cổng đuổi theo họ tới tận cửa đèo Vô Danh Cốc. |
| BS-311 | Bà Tâm | Tới cột mốc thì nó dừng. |
| BS-312 | Nhân vật chính | ...Vâng. |
| BS-313 | (dẫn) | Bà im lặng một lúc. |
| BS-314 | Bà Tâm | Con thấy gì ở thành ta? |

*Điều nhân vật chính đã thấy, nói thẳng với bà (theo các Nhận ra đã có):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-315 | Nhân vật chính | Sắc nào cũng do Chánh Ty soạn. Bà đóng ấn. |
| BS-316 | Bà Tâm | Ta đọc. Tuần nào cũng đọc. |
| BS-317 | Nhân vật chính | Bà đọc báo cáo. Còn Sổ Tro thì Bà không đọc. Cột đen ba trăm năm không có lấy một nét. |
| BS-318 | (dẫn) | Bà không đáp. |
| BS-319 | Nhân vật chính | Tro không nhận ra Nghiệt. Nó chỉ chui vào kẽ. Tay nứt vì vôi hay nước thuốc cũng ra xám. |
| BS-320 | Bà Tâm | Tro không biết nói dối. |
| BS-321 | (dẫn) | Bà khép hai tay vào trong tay áo. |
| BS-322 | Nhân vật chính | Người bị đuổi bị bán. Người của Ty đưa họ lên xe trắng, đếm đủ số rồi chở sang Vạn Thư. |
| BS-323 | Bà Tâm | Xe nào? |
| BS-324 | Nhân vật chính | Xe của bà Sương. Năm nào bà ấy cũng lên. |
| BS-325 | (dẫn) | Bà im rất lâu. |
| BS-326 | Bà Tâm | Người đã nhiễm thì đằng nào cũng hóa sứ. |
| BS-327 | Nhân vật chính | Hồi trước, người ra xám được giữ lại chờ Bà rửa men. Ông Sẹo ở Nhà Rửa vẫn còn sẹo. |
| BS-328 | Bà Tâm | Ông ta còn sống à? |
| BS-329 | Nhân vật chính | ...Ông ấy bị đuổi rồi. Hôm kia. |
| BS-330 | (dẫn) | Bà không hỏi ai đã báo tin. |
| BS-331 | Bà Tâm | Cổ tay trái. Hình cánh mai. |
| BS-332 | Nhân vật chính | Cái ngoài cổng không phải Sứ Giả. Nó là Nghiệt, sinh ra từ chính những ô cửa trong thành này. |
| BS-333 | Bà Tâm | Ra quảng trường nói câu ấy, người ta sẽ không để con nói hết đâu. |
| BS-334 | Nhân vật chính | Người ta bị đuổi chỉ vì tay nứt. |
| BS-335 | Bà Tâm | Tro không biết nói dối. |

*Lời đề nghị:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-336 | Bà Tâm | Con muốn gì? |
| BS-337 | Nhân vật chính | Bỏ các sắc. Mở cổng cho người ta về. |
| BS-338 | Bà Tâm | Mở cổng thì thứ ngoài kia cũng vào theo. |
| BS-339 | Bà Tâm | Ta đã thấy một lần. |
| BS-340 | (lựa chọn) | Kể về phiến đá ở nền cổng cũ. |
| BS-341 | (lựa chọn) | Không kể. |
| BS-342 | Nhân vật chính | Dưới lớp vôi ở nền cổng cũ có một phiến đá. Trên đó khắc một chữ Khê. |
| BS-343 | Bà Tâm | Mấy vạch? |
| BS-344 | Nhân vật chính | Ba. |
| BS-345 | (dẫn) | Bà không hỏi thêm. |
| BS-346 | Bà Tâm | Ta sẽ làm thế này. |
| BS-347 | Bà Tâm | Từ mai, tro chỉ giữ người thật sự bị chạm. Ai mới bị đuổi theo sắc họ hàng thì cho về dần. Không đọc sắc, không dán thông báo. Không ai cần biết. |
| BS-348 | Bà Tâm | Ty vẫn là Ty. Ngọc Khiết vẫn là Chánh Ty. |
| BS-349 | Bà Tâm | Đổi lại, con không nói với ai. |
| BS-350 | Bà Tâm | Báo cáo tuần này có tên con. |
| BS-351 | Bà Tâm | Ở cổng, con đỡ hòm từ tay một người khiêng. Người ấy ra cổng, con vào. |
| BS-352 | Bà Tâm | Con chỉ cho người áo lam một người ở Nhà Rửa. |
| BS-353 | Bà Tâm | Xem kìa, con cũng đẩy được người ra ngoài rồi đấy. |
| BS-354 | (lựa chọn) | Không. Mai ở Lễ Quét Vôi, cháu sẽ nói hết trước mọi người. |
| BS-355 | (lựa chọn) | ...Cháu sẽ không nói. |

*Từ chối: xuống núi, mai là Lễ Quét Vôi:*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-356 | Bà Tâm | Phải rồi. Ba trăm năm nay, thành này chỉ thiếu một người chịu nói. |
| BS-357 | (dẫn) | Bà quay lại chậu nước. |
| BS-358 | Bà Tâm | Ngọc Khiết. Để người này đi. Hôm nay không ai ra cổng. |
| BS-359 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | ...Thưa Bà. |
| BS-360 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Mai ở quảng trường, đứng gần người này. |
| BS-361 | Người áo lam | Dạ. |

*Nhận lời: biến thể (b):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-362 | Bà Tâm | Ừ. |
| BS-363 | Bà Tâm | Ngọc Khiết. Để người này đi. Từ mai làm như ta dặn. |
| BS-364 | Chánh Ty *[Ngọc Khiết; không gọi thẳng nhân vật chính]* | Thưa Bà. |
| BS-365 | (thẻ) | Lễ Quét Vôi |
| BS-366 | (dẫn) | Năm ấy, Lễ Quét Vôi không đọc sắc nào. Người ta quét vôi lại bể rửa rồi về nhà. |
| BS-367 | (dẫn) | Chiều tối, cổng hé ra một khe. Mấy người trong trại đi vào, cúi đầu, không ai nói gì. Ông Sẹo đi sau cùng. |
| BS-368 | (dẫn) | Chiều tối, cổng hé ra một khe. Mấy người trong trại đi vào, cúi đầu, không ai nói gì. |
| BS-369 | (dẫn) | Đêm ấy, dưới trại vẫn có tiếng gõ trên sứ. Tiếng gõ chẳng thưa đi. |
| BS-370 | (thẻ tranh, tiêu đề) | Tờ giấy gấp đôi |
| BS-371 | (dẫn) | Bà hầu câm đưa tờ giấy rồi quay lên. Bà Tâm không xuống. |

*Thẻ quanh phần D, và chữ trên tờ giấy của bà Tâm (`tools/art/bs_cards.py`):*

| Mã | Người nói / loại | Nội dung |
|---|---|---|
| BS-372 | (thẻ) | Sáng hôm sau |
| BS-373 | (thẻ cuối, từ chối) | Sáng mai, cả thành sẽ ra Quảng Trường Rửa. |
| BS-374 | (thẻ cuối, từ chối) | Hết bản thử nghiệm. Cảm ơn đã chơi. *(ĐỀ XUẤT 2026-10-15: thẻ cũ lộ đường dẫn tài liệu "docs/N_bach_son.md" và chữ nội bộ "Biến thể (b)" cho người chơi; Mở Đầu nay nối thẳng sang Bạch Sơn nên lời cảm ơn chuyển về thẻ cuối Bạch Sơn)* |
| BS-375 | (thẻ cuối, nhận lời) | Không có bạo loạn, không ai chết. Ty vẫn nguyên vẹn. Bà Tâm không rời Bạch Điện. Cái ngoài cổng không yếu đi. *(ĐỀ XUẤT 2026-10-15: thẻ cũ lộ đường dẫn tài liệu "docs/N_bach_son.md" và chữ nội bộ "Biến thể (b)" cho người chơi; Mở Đầu nay nối thẳng sang Bạch Sơn nên lời cảm ơn chuyển về thẻ cuối Bạch Sơn)* |
| BS-376 | (thẻ cuối, nhận lời) | Hết bản thử nghiệm. Cảm ơn đã chơi. *(ĐỀ XUẤT 2026-10-15: thẻ cũ lộ đường dẫn tài liệu "docs/N_bach_son.md" và chữ nội bộ "Biến thể (b)" cho người chơi; Mở Đầu nay nối thẳng sang Bạch Sơn nên lời cảm ơn chuyển về thẻ cuối Bạch Sơn)* |
| BS-377 | (tờ giấy) | Rửa. / Rắc tro cho kẽ hiện ra. / Kẽ men thẳng, gãy góc, trên nền trắng. / Kẽ da cong theo chỉ tay. Đừng nhầm. / Lần theo kẽ men. Tới mép thì dừng. / Cắt phần đã thối, không cắt người. |
| BS-378 | (ấn trên tờ giấy) | BẠCH ĐIỆN |

