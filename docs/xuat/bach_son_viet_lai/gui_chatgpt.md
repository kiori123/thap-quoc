# Bạch Sơn: viết lại toàn bộ lời thoại và chữ trong game

*File này để gửi ChatGPT. Sinh tự động từ code game ngày 2026-10-14 bằng `tools/text/bs_text.py export`: 365 dòng, đúng như trong game lúc này.*

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
5. **Không dùng gạch ngang dài (,)**. Dùng dấu phẩy, dấu chấm, hai chấm.
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

### Phần A. Lên núi: Mạnh dẫn đường qua Bãi Tro (những người hóa sứ), thấy Bạch Sơn

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-001 | (thẻ chương / thời gian) | Bạch Sơn |
| BS-01 | (thẻ chương / thời gian) | Ba ngày sau khi rời Vô Danh Cốc |
| BS-02 | Mạnh | Qua bãi này là tới trại. |
| BS-03 | Mạnh | Đừng nhìn mấy pho tượng lâu quá. |
| BS-04 | [Tên] | Họ là ai? |
| BS-05 | Mạnh | Người bị đuổi ra đấy. Trắng Tay chạm vào đầu thì thành thế. |
| BS-06 | (nút tương tác) | Xem |
| BS-07 | (việc cần làm) | Theo Mạnh lên Trại Ngoài Cổng |
| BS-08 | Mạnh | Đấy. Bạch Sơn. |
| BS-09 | [Tên] | Trắng thật. |
| BS-10 | Mạnh | Ở dưới này, ngày nào cũng phải ngước lên nhìn nó. |

### Phần A. Xem đồ vật, nơi chốn quanh trại (lời kể khi người chơi bấm Xem)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-11 | (xem đồ vật) | Một pho người bằng sứ, quay mặt về phía cổng. Dải men lam bịt ngang mắt. |
| BS-12 | (xem đồ vật) | Cái nong đựng những mảnh sứ bằng ngón tay. Mảnh nào cũng khắc một năm. Bà Lành bảo mỗi mảnh là một người. |
| BS-13 | (xem đồ vật) | Mấy khối đá xám nằm dưới lớp vôi bong. Trên một phiến đá có khắc chữ "Khê" và ba vạch. |
| BS-14 | (xem đồ vật) | Giếng do người trong trại tự đào. Nước lợ, có vị vôi. |
| BS-15 | (xem đồ vật) | Vệt đất trắng bóng như men, chạy từ chân núi về phía trại. Giẫm lên nghe giòn như vỏ trứng. |
| BS-16 | (xem đồ vật) | Nước đục chảy từ cống dưới chân tường thành xuống. Người trong trại vẫn múc để giặt. |

### Phần A. Nói chuyện với người trong trại (Cỏ, Diệu, mẹ Mạnh)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-17 | Cỏ | Trên bậc cổng có cái chậu trắng to lắm. Người trong ấy rửa tay ở đấy. |
| BS-18 | Cỏ | Em chưa rửa ở đấy bao giờ. Bà Lành bảo người dưới này không được lại gần. |
| BS-19 | Diệu | Đứng xích ra, chắn hết ánh sáng rồi. Tôi đang giã thuốc. |
| BS-20 | Diệu | Ông lính trên tường ấy à? Tối nào ông ấy cũng đứng đó. Kệ ông ấy. |
| BS-21 | Mẹ Mạnh | Cảm ơn cháu đã đưa nó về. |
| BS-22 | Mẹ Mạnh | Nhà bác bị đuổi theo sắc mới. Chú nó bị đuổi mấy năm trước rồi, giờ đến lượt hai mẹ con bác. |

### Phần A. Trại Ngoài Cổng: bà Lành đón Mạnh, hỏi nhân vật chính lên đây làm gì

| Mã | Ai nói / loại | Câu hiện tại |
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

### Phần A. Tự đi quanh trại, nói chuyện với người trong trại; tối ngồi bếp với bà Lành

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-250 | (nút tương tác) | Nói chuyện |
| BS-37 | (nút tương tác) | Ngồi xuống bếp |
| BS-38 | (việc cần làm) | Đi quanh trại. Xong rồi thì ra bếp ngồi với bà Lành. |

### Phần A. Đêm đầu ở trại: Mảnh Sành bò ra từ Rãnh Sứ, trận đánh, thua thì đứng dậy đánh lại

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-39 | Bà Lành | Ăn đi. Mắm cá suối đấy. |
| BS-40 | [Tên] | ...Ngon ạ. |
| BS-41 | Bà Lành | Trên kia cái gì lên men cũng bị chê là thối. Thối mà ngon thế này thì bà cứ ăn. |
| BS-42 | Bà Lành | Ăn xong thì vào lều ngủ. Đêm đừng có ra ngoài. |
| BS-43 | Cỏ | Bà ơi! |
| BS-44 | (dòng mở trận đánh) | Mảnh Sành bò ra từ Rãnh Sứ, đang bò về phía lều của Cỏ! |
| BS-45 | (lời kể) | Ngã xuống rồi. Đứng dậy lần nữa? |
| BS-46 | (lựa chọn) | Thử lại |
| BS-47 | Bà Lành | Đêm nào cũng thế. Có đêm nó chỉ cào cửa lều thôi. |
| BS-48 | Bà Lành | Có đêm thì nó không chỉ cào cửa. |
| BS-49 | Cỏ | Mai lên cổng à? Rửa tay ở cái chậu ấy rồi về kể em nghe nhé. |

### Phần A. Sáng hôm sau: đoàn thầy thuốc của bà Sương nghỉ chân ở trại; nhân vật chính xin gánh hòm thuốc để được vào thành

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-50 | Bà Sương | Ai biết gánh thì lại đây. Người của tôi bỏ về giữa đường rồi. |
| BS-51 | [Tên] | Cháu gánh được. |
| BS-52 | Bà Sương | Đưa tay đây xem. |
| BS-53 | Bà Sương | Tay chai thế này thì gánh được. Lên cổng cứ đứng sau tôi, đừng nói gì. |
| BS-54 | Bà Lành | Bà Sương năm nào cũng lên một lần. Lúc đi xe rỗng, lúc về xe đầy. |
| BS-55 | [Tên] | Đầy gì ạ? |
| BS-56 | Bà Lành | Người chứ gì. Nghe bảo ai lên xe thì được đưa đi chữa bệnh. |
| BS-57 | (việc cần làm) | Gánh hòm thuốc, theo bà Sương lên Sân Tro |

### Phần B. Sân Tro trước Cổng Trắng: Thử Tro. Tay nhân vật chính có men rạn thật (bị Trắng Tay chạm ở cửa đèo Vô Danh Cốc), nên tro ra xám

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-58 | Khám sư | Người tiếp theo. Đưa tay đây. |
| BS-59 | Khám sư | Trắng. |
| BS-60 | Khám sư | Bà Sương. Năm nay cũng lên à? |
| BS-61 | Bà Sương | Năm nào tôi chẳng lên. |
| BS-63 | Khám sư | Đưa tay đây. Ngửa bàn tay ra. |
| BS-64 | Khám sư | Giữ yên. |
| BS-80 | (chữ giao diện (Thử Tro: giữ tay yên)) | Space khi tay lắc ra mép |
| BS-264 | (chữ giao diện (Thử Tro: giữ tay yên)) | Tay yên |
| BS-65 | (dấu đóng (Thử Tro)) | XÁM |
| BS-66 | Khám sư | ...Xám. |
| BS-67 | Bà Sương | Người gánh hòm thuốc cho tôi đấy. Gánh nặng thì tay nứt thôi. |
| BS-68 | Khám sư | Sổ ghi xám thì phải giữ lại. |
| BS-82 | (lựa chọn) | (Im lặng) |
| BS-83 | (lựa chọn) | Cháu bị Nghiệt chạm ở cửa đèo. |
| BS-84 | (lựa chọn) | Cháu đỡ hòm từ tay anh ấy suốt đường. |

### Phần B. Cách qua cổng 1: im lặng; lão Cẩn (lính cổng) làm ướt tro rồi cho thử lại. Lão sẽ bị phạt vì việc này

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-69 | Lão Cẩn | Tro ướt. |
| BS-70 | Khám sư | Dạ? |
| BS-71 | Lão Cẩn | Tay đổ mồ hôi thì tro không ăn. Thử lại đi. |
| BS-72 | (dấu đóng (Thử Tro)) | TRẮNG |
| BS-73 | Khám sư | ...Trắng. |
| BS-74 | Lão Cẩn | Đi đi. |

### Phần B. Cách qua cổng 2: nói thật mình bị Nghiệt chạm; bị giữ một đêm ở Sân Tro, sáng ra Chánh Ty Ngọc Khiết tự xuống xem

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-002 | [Tên] | Cháu bị Nghiệt chạm ở cửa đèo. |
| BS-86 | Bà Sương | Tôi thuê người ở trại hôm qua. Chuyện của người ấy, tôi không biết. |
| BS-87 | Khám sư | Giữ lại. |
| BS-88 | (thẻ chương / thời gian) | Đêm ở Sân Tro |
| BS-89 | (lời kể) | Dưới chân dốc có tiếng gõ trên sứ, lúc thưa lúc dày. Cổng sau lưng vẫn đóng chặt. |
| BS-90 | Khám sư | Thưa Chánh Ty. |
| BS-91 | Chánh Ty | Khai thật với khám sư à? |
| BS-92 | Chánh Ty | Ba trăm năm nay, chưa ai đứng ở cổng này tự nhận mình bị Nghiệt chạm. |
| BS-93 | Chánh Ty | Cho vào. Sáng nào cũng lên Dinh Ty cho tôi xem tay. |

### Phần B. Cách qua cổng 3: đổ cho anh Vững (người khiêng hòm cùng đoàn). Tay anh nứt vì gánh nên tro ra xám; anh bị giữ lại rồi bị đuổi

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-003 | [Tên] | Cháu đỡ hòm từ tay anh ấy suốt đường. |
| BS-95 | Khám sư | Anh kia. Đưa tay đây. |
| BS-96 | Anh Vững | Tay tôi... Gánh hòm thì tay nứt chứ. |
| BS-97 | (tiêu đề thẻ tranh) | Tay anh Vững |
| BS-98 | Khám sư | Xám. Giữ lại. |
| BS-99 | Khám sư | Tay người này dính lây từ tay anh ta. Rửa lại. |
| BS-101 | Anh Vững | Bà Sương, tôi gánh hòm cho bà sáu năm rồi. |
| BS-102 | Bà Sương | Đi thôi. |

### Phần B. Qua cổng, vào Tầng Rửa; vợ anh Vững (nếu đã đổ cho anh) hỏi chồng đâu

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-85 | Bà Sương | Lão gác ấy làm thế nhiều lần rồi. Sớm muộn gì cũng có ngày bị bắt. |
| BS-94 | Bà Sương | Từ giờ đứng cách tôi ra một quãng. |
| BS-103 | Người đàn bà | Bà Sương, anh Vững nhà em đâu rồi? |
| BS-104 | Bà Sương | Bị giữ lại ở cổng. |
| BS-75 | Bà Sương | Rửa tay đi. Ở đây không rửa là người ta nhìn đấy. |
| BS-76b | (nút tương tác / việc cần làm) | Rửa tay |
| BS-76 | (nút tương tác / việc cần làm) | Rửa tay ở chậu nước trước cửa nhà |
| BS-77 | (lời kể) | Nước lạnh. Chảy từ tầng trên xuống. |

### Chuyển sang Phần D

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-372 | (thẻ chương / thời gian) | Sáng hôm sau |

### Thẻ kết thúc bản thử

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-004 | (thẻ chương / thời gian) | LỄ QUÉT VÔI |
| BS-373 | (thẻ chương / thời gian) | Sáng mai, cả thành sẽ ra Quảng Trường Rửa. |
| BS-374 | (thẻ chương / thời gian) | Hết bản thử Bạch Sơn (tới hết phần D). Phần còn lại ở docs/N_bach_son.md. |
| BS-375 | (thẻ chương / thời gian) | Biến thể (b): không có bạo loạn, không ai chết trong chương. Ty vẫn nguyên vẹn. Bà Tâm không rời Bạch Điện. Cái ngoài cổng không yếu đi. |
| BS-376 | (thẻ chương / thời gian) | Hết bản thử Bạch Sơn (biến thể b). Phần còn lại ở docs/N_bach_son.md. |
| BS-266 | (thẻ chương / thời gian) | BẠCH ĐIỆN |
| BS-267 | (thẻ chương / thời gian) | Sáng hôm sau, người của Ty gõ cửa nhà kho. Chánh Ty mời lên Bạch Điện. |
| BX-005 | (thẻ chương / thời gian) | Hết bản thử Bạch Sơn (tới hết phần C). Đã nhận ra %d trong 5 điều. Phần còn lại ở docs/N_bach_son.md. |
| BX-006 | (thẻ chương / thời gian) | BẠCH SƠN |
| BS-78 | (thẻ chương / thời gian) | Bốn ngày nữa là tới Lễ Quét Vôi |
| BS-79 | (thẻ chương / thời gian) | Hết bản thử Bạch Sơn. Phần còn lại của chương ở docs/N_bach_son.md. |

### Phần C. Các bảng chữ: buổi trong ngày; Sổ ghi (Điều thấy là dữ kiện thấy được, Nhận ra là kết luận ghép từ các Điều thấy)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-007 | (buổi trong ngày (ghép vào thẻ "Ngày N · buổi")) | Sáng |
| BX-008 | (buổi trong ngày (ghép vào thẻ "Ngày N · buổi")) | Chiều |
| BX-009 | (buổi trong ngày (ghép vào thẻ "Ngày N · buổi")) | Tối |
| BS-213 | (Sổ ghi: điều thấy) | Bà Mẫn xoa tro lên cái chén men rạn rồi dội nước. Kẽ rạn vẫn đen. Da bị Nghiệt chạm cũng có lớp men rạn như thế. |
| BS-214 | (Sổ ghi: điều thấy) | Bà Mẫn xoa tro lên tay mình. Ba mươi năm ngâm thuốc, tay bà nứt hết. Thử tro cũng ra xám. |
| BS-215 | (Sổ ghi: điều thấy) | Sổ Tro, cột "đen" của người trong thành. Lật mấy chục tập vẫn không có dòng nào. |
| BS-216 | (Sổ ghi: điều thấy) | Sắc suốt ba mươi lăm năm nay đều cùng một nét chữ. Cuối mỗi tờ ghi "Chánh Ty Ngọc Khiết soạn", bên dưới đóng ấn của Điện. |
| BS-217 | (Sổ ghi: điều thấy) | Một quyển sổ mỏng kẹp trong Sổ Tro. Bên cạnh tên mỗi người là một con số. Trang cuối đóng dấu của một nhà buôn Vạn Thư. |
| BS-218 | (Sổ ghi: điều thấy) | Sổ Tro tập đầu, năm PK 21: "Xám thì giữ lại ở Nhà Rửa, đợi Bà." |
| BS-219 | (Sổ ghi: điều thấy) | Sổ Tro tập PK 395. Một nhà ở Tầng Rửa, năm người. Dòng cuối ghi "trẻ nhỏ, chưa tên". Cũng năm ấy, mình bị bỏ ở cửa đèo. |
| BS-220 | (Sổ ghi: điều thấy) | Bà Lành kể, đứa bé nhà ấy không qua được mùa đông đầu. Năm đó có đoàn người phương bắc mang theo một đứa bé quấn khăn kẻ ô bàn cờ, đi về phía đèo. |
| BS-221 | (Sổ ghi: điều thấy) | Tối hôm ấy, sau Dinh Ty, người của Ty dẫn ba người bị đuổi lên xe trắng. Bà Sương trả tiền. |
| BS-222 | (Sổ ghi: điều thấy) | Đền Thầy có bức tranh vẽ một nhát chém chia người sạch và người bẩn. Người coi đền bảo Sứ Giả ngoài cổng sinh ra từ lòng thành của dân. |
| BS-223 | (Sổ ghi: điều thấy) | Lúc tay nó chạm vào mình ở trại, mình thấy những ô cửa sáng đèn trong thành. Người đứng sau lớp giấy nhìn xuống. Trên bậc cửa nhà nào cũng có chén sứ. |
| BS-224 | (Sổ ghi: điều thấy) | Ông Sẹo kể, năm bảy tuổi ông bị Nghiệt chạm. Bà tự tay rửa men cho ông ở Nhà Rửa. Rồi có một năm Bà không xuống nữa. |
| BS-225 | (Sổ ghi: điều thấy) | Anh Vững ngồi ở đầu xe trắng. Anh không ngẩng lên. |
| BS-226 | (Sổ ghi: điều thấy) | Đêm cuối, mình không xuống trại. Tay nó thò tận vào lều. Ông Bảy bán than hóa sứ ngay trước cửa lều. |
| BS-227 | (Sổ ghi: nhận ra) | Cái cổng có lý do để tồn tại. Tro phát hiện được dấu Nghiệt chạm, nhưng tay nứt vì vôi, thuốc hay gánh cũng ra xám. |
| BS-228 | (Sổ ghi: nhận ra) | Bà đóng ấn mà không nhìn. Sắc nào cũng do Chánh Ty soạn. Cột đen trống suốt ba trăm năm mà sắc vẫn được ban xuống. |
| BS-229 | (Sổ ghi: nhận ra) | Người bị đuổi không biến mất. Tên họ bị bán, rồi họ bị đưa lên xe trắng sang Vạn Thư. |
| BS-230 | (Sổ ghi: nhận ra) | Cả thành đang thờ thứ săn người ngoài cổng. Nó sinh ra từ nỗi sợ sau những ô cửa trong thành. |
| BS-231 | (Sổ ghi: nhận ra) | Ngày trước, người bị thử ra xám được giữ ở Nhà Rửa để chờ Bà rửa men. Bà từng chữa cho họ, không đuổi họ đi. |
| BS-232 | (Sổ ghi: nhận ra) | Đứa trẻ chưa tên trong sổ năm PK 395 không phải mình. |

### Phần C. Thông báo khi Sổ ghi có dòng mới

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-244 | (thông báo) | Sổ ghi: thêm một điều thấy (Tab) |
| BX-010 | (thông báo) | Nhận ra:  |

### Phần C. Thông báo khi thanh Nghi (Ty nghi ngờ mình) tăng

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-246 | (thông báo) | Nghi tăng |
| BS-247 | (thông báo) | Nghi giảm |

### Phần C. Thẻ đầu mỗi buổi, đếm ngày tới Lễ Quét Vôi

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-011 | (thẻ chương / thời gian) | Ngày %d |
| BS-234 | (thẻ chương / thời gian) | Ba ngày tới Lễ Quét Vôi |
| BX-012 | (thẻ chương / thời gian) | Hai ngày tới Lễ Quét Vôi |
| BX-013 | (thẻ chương / thời gian) | Mai là Lễ Quét Vôi |
| BX-014 | (thẻ chương / thời gian) | Ngày %d · %s |
| BS-105 | (lời kể) | Ngoài Sân Tro có tiếng roi quất. Người qua đường bảo lão gác già bị phạt vì làm ướt tro cho người lạ. |
| BS-106 | Chị Gấm (hoặc lời kể) | Đêm qua tay nó thò vào tận lều. Ông Bảy bán than hóa sứ ngay trước cửa lều. |

### Phần C. Nút tương tác trong thành (hiện khi đứng gần)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-249 | (nút tương tác (trong thành)) | Gánh hòm cho bà Sương |
| BS-251 | (nút tương tác (trong thành)) | Vào Nhà Rửa |
| BS-252 | (nút tương tác (trong thành)) | Chui qua Cửa Cống |
| BS-253 | (nút tương tác (trong thành)) | Lên Tầng Giữa |
| BS-254 | (nút tương tác (trong thành)) | Cổng tầng đã đóng |
| BX-015 | (nút tương tác (trong thành)) | Ngồi đợi tới  |
| BX-016 | (nút tương tác (trong thành)) | chiều |
| BX-017 | (nút tương tác (trong thành)) | tối |
| BX-018 | (nút tương tác (trong thành)) | sáng mai |
| BS-256 | (nút tương tác (trong thành)) | Xuống Tầng Rửa |
| BS-257 | (nút tương tác (trong thành)) | Vào Y Viện |
| BS-258 | (nút tương tác (trong thành)) | Dinh Ty |
| BS-259 | (nút tương tác (trong thành)) | Lên Tầng Đền |
| BS-260 | (nút tương tác (trong thành)) | Ra sau Dinh Ty |
| BS-261 | (nút tương tác (trong thành)) | Xuống Tầng Giữa |
| BS-262 | (nút tương tác (trong thành)) | Vào Đền Thầy |

### Phần C. Việc cần làm trong thành

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-019 | (việc cần làm) | %s. Đi đâu tùy mình (Tab: Sổ ghi) |

### Phần C. Những việc nhỏ (ngồi đợi qua buổi, cổng tầng đóng...)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-107 | (thông báo) | Tối rồi. Cổng các tầng đóng hết rồi. |
| BS-108 | Thư lại | Không có việc thì đi chỗ khác. |
| BX-020 | (lời kể) | Ngồi bên bể rửa, nhìn người ta rửa tay. |
| BX-021 | (lời kể) | Ngồi đợi tiếng chuông cổng. |
| BX-022 | (lời kể) | Về chỗ ngủ trong nhà kho của bà Sương. |

### Phần C. Rửa tay ở bể (người trong thành rửa tay suốt ngày)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-112 | (lời kể) | Nước lạnh. |

### Phần C. Mắt Ty: người áo lam gạ nhân vật chính báo người khác cho Ty

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-113 | Người áo lam | Người gánh hòm cho bà Sương đấy à? |
| BS-114 | Người áo lam | Ở đây thấy gì thì báo cho Ty. Báo đúng, Ty sẽ nhớ. |
| BS-115 | Người áo lam | Thấy gì thì cứ báo. |
| BS-116 | (lựa chọn) | Ông già ở Nhà Rửa. |
| BS-117 | (lựa chọn) | Chị Gấm ở Nhà Rửa. |
| BS-118 | (lựa chọn) | Không thấy ai. |
| BS-119 | Người áo lam | Ừ. Cứ để Ty lo. |

### Phần C. Gánh hòm cho bà Sương; lên Dinh Ty, Sổ Tro để mở trên bàn khi thư lại đi vắng

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-023 | Bà Sương | Lên Y Viện lấy mấy gói thuốc cho tôi. |
| BX-024 | Bà Sương | Mang hòm ra Sân Tro. Người của Hội Y đang đợi. |
| BX-025 | Bà Sương | Hòm hôm nay nhẹ đấy. Đi nhanh rồi về. |
| BS-123 | (lời kể) | Hòm nặng trĩu. Người qua đường nhìn cái hòm, chẳng ai nhìn người đang gánh. |
| BS-124 | Bà Sương | Hôm nay mang hòm lên Dinh Ty. Hội Y phải trình sổ thuốc cho Ty. |
| BS-125 | Thư lại | Đặt hòm ở kia. Đứng chờ. |
| BS-126 | Thư lại | Chánh Ty gọi. Đừng động vào thứ gì. |
| BS-127 | (tiêu đề thẻ tranh) | Sổ Tro, Tầng Rửa |
| BS-128 | (lời kể) | Mỗi dòng ghi một người, có ba cột: trắng, xám, đen. Lật mấy chục trang, cột đen vẫn trống trơn. |
| BS-129 | (tiêu đề thẻ tranh) | Các sắc, cuối tập |
| BS-130 | (lời kể) | Cuối tập là các tờ sắc. Nét chữ tờ nào cũng giống nhau. Dòng cuối ghi "Chánh Ty Ngọc Khiết soạn", bên dưới là ấn của Điện. |
| BS-131 | (tiêu đề thẻ tranh) | Quyển mỏng kẹp giữa |
| BS-132 | (lời kể) | Kẹp giữa Sổ Tro là một quyển mỏng. Bên cạnh mỗi tên là một con số. Trang cuối đóng dấu của một nhà buôn Vạn Thư. |
| BS-133 | (tiêu đề thẻ tranh) | Sổ Tro, tập đầu |
| BS-134 | (lời kể) | Tập đầu tiên, năm PK 21. Mực đã nhạt: "Xám thì giữ lại ở Nhà Rửa, đợi Bà." |
| BS-135 | (tiêu đề thẻ tranh) | Sổ Tro, tập PK 395 |
| BS-136 | (lời kể) | Tập năm PK 395. "Nhà (tro che mất tên), Tầng Rửa, Luật Cả Nhà. Năm người. Trẻ nhỏ, chưa tên." |
| BS-137 | Thư lại | Xong rồi thì đi. |
| BS-138 | Bà Sương | Tối mai ra sau Dinh Ty. Có mấy cái hòm cần khiêng. |

### Phần C. Y Viện: bà Mẫn (thầy thuốc già, thầy của Lúa) và cái chén men rạn

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-139 | Bà Mẫn | Đi đi. Ở đây lâu quá, người ta để ý đấy. |
| BS-140 | Bà Mẫn | Ai đấy? Người lạ à? Từ Vô Danh Cốc lên sao? |
| BS-141 | Bà Mẫn | Lúa còn sống không? |
| BS-143 | Bà Mẫn | ...Ừ. |
| BS-144 | Bà Mẫn | Nó theo bà xuống Cửa Cống chữa cho người trong trại. Người ta bắt nó chứ không bắt bà. Bà còn chữa cho nhà Chánh Ty cơ mà. |
| BS-145 | [Tên] | Thử tro ở cổng thì biết được gì ạ? |
| BS-146 | Bà Mẫn | Ngồi xuống đây. |
| BS-147 | (tiêu đề thẻ tranh) | Cái chén men rạn |
| BS-149 | Bà Mẫn | Tro có biết Nghiệt là gì đâu. Nó chỉ chui vào kẽ thôi. Da bị Nghiệt chạm cũng có lớp men rạn như cái chén này, nên tro mới bám vào. |
| BS-150 | (tiêu đề thẻ tranh) | Tay bà Mẫn |
| BS-152 | Bà Mẫn | Tay bà ngâm thuốc suốt ba mươi năm, nứt hết cả rồi. Ra cổng thử tro, bà cũng bị tính là xám thôi. |
| BS-153 | Bà Mẫn | Ba trăm năm nay, trong thành có ai bị Nghiệt chạm đâu. Thế mà năm nào cũng có người bị thử ra xám. |
| BS-154 | Bà Mẫn | Tối muốn xuống trại thì tìm Cửa Cống ở góc quảng trường. Cẩn thận, đừng để người áo lam trông thấy. |

### Phần C. Đền Thầy: người coi đền, tranh thờ nhát chém tách người sạch khỏi người bẩn

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-155 | Người coi đền | Tối nhớ đặt chén lên bậc cửa. |
| BS-156 | Người coi đền | Rửa tay chưa? Rồi thì vào đi. |
| BS-157 | (tiêu đề thẻ tranh) | Tranh thờ |
| BS-158 | Người coi đền | Thầy của Bà đấy. Một nhát chém, người sạch một bên, người bẩn một bên. |
| BS-159 | [Tên] | Ông cháu bổ củi đâu có chém kiểu ấy. |
| BS-160 | Người coi đền | Ông cháu thì biết cái gì. |
| BS-162 | (lời kể) | Nét chém trong tranh không dừng lại ở đâu. Nó kéo thẳng xuống tận mép tranh. |
| BS-163 | Người coi đền | Sứ Giả ngoài cổng cũng từ lòng thành của dân mình mà ra. Nó có đụng đến ai trong thành đâu. |
| BS-164 | Người coi đền | Tối về nhớ đặt một chén lên bậc. Nhà nào cũng đặt cả. |

### Phần C. Nhà Rửa (xưởng giặt liệm): chị Gấm, ông Sẹo được Bà rửa men hồi bảy tuổi

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-165 | Chị Gấm | Sáng nay người của Ty xuống đưa ông ấy ra cổng. Ông ấy chẳng mang theo thứ gì. |
| BS-166 | Chị Gấm | Ông ấy ngủ rồi. Cứ để ông ấy ngủ. |
| BS-167 | Chị Gấm | Tìm ai? Đây là chỗ giặt đồ liệm. Người trên kia chẳng xuống đây đâu. |
| BS-168 | Ông Sẹo | Cứ để người ta vào, Gấm. |
| BS-169 | Ông Sẹo | Người gánh hòm cho mụ Sương phải không? Ngồi đi. Khoan, đừng ngồi chỗ ấy. Chỗ lõm kia là chỗ Bà từng ngồi. |
| BS-170 | [Tên] | Bà nào ạ? |
| BS-171 | Ông Sẹo | Bà trên Điện ấy. |
| BS-172 | Ông Sẹo | Năm tôi bảy tuổi, tay bị Nghiệt chạm. Thử tro ra xám, người ta đưa tôi xuống đây. |
| BS-173 | Ông Sẹo | Bà ngồi đúng chỗ ấy, nắm cổ tay tôi rồi cạo lớp men đi. Chỉ còn cái sẹo này. |
| BS-174 | [Tên] | Tay ra xám mà không bị đuổi ạ? |
| BS-175 | Ông Sẹo | Hồi ấy xám thì giữ lại, chờ Bà rửa men. Sau này Bà không xuống nữa. Từ đó, cứ xám là bị đuổi. |
| BS-176 | Chị Gấm | Ông lại kể chuyện ngày xưa rồi. |
| BS-177 | Ông Sẹo | Cái chén ngoài bậc là tôi đặt cho Bà. Không phải cho thứ ngoài cổng ấy. |

### Phần C. Tối, sau Dinh Ty: xe trắng chở người bị đuổi đi, bà Sương trả tiền

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-178 | Bà Sương | Đặt hòm lên xe. Cẩn thận đấy. |
| BS-179 | (lời kể) | Người áo lam dẫn ba người ra từ cửa sau Dinh Ty. Tay họ bị trói lỏng. Họ trèo lên xe rồi chui xuống dưới tấm vải trắng. |
| BS-180 | Người áo lam | Ba người. Đúng như trong sổ. |
| BS-181 | Bà Sương | Ba người. |
| BS-182 | (lời kể) | Anh Vững ngồi ở đầu xe. Anh cúi mặt, không ngẩng lên. |
| BS-183 | [Tên] | Họ đi đâu vậy? |
| BS-184 | Bà Sương | Đi chữa bệnh. Ở Vạn Thư, người ta hiểu về men hơn ở đây. Tôi đã cứu được hai người rồi. |
| BS-185 | [Tên] | Thế còn những người khác? |
| BS-186 | Bà Sương | Về ngủ đi. |

### Phần C. Đêm, chui qua Cửa Cống xuống trại: bà Lành, cái nong thẻ tro, tay Trắng Tay quờ vào lều

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-187 | (lời kể) | Cửa Cống thấp, phải cúi gập người mới chui qua được. Nước thải ngập đến đầu gối. |
| BS-188 | Bà Lành | Lại xuống đây à? Ngồi đi. Trên ấy có ai lo cho cháu ăn đâu. |
| BS-189 | [Tên] | Bà ơi, năm PK 395 có nhà nào ở Tầng Rửa bị đuổi, mang theo một đứa bé chưa đặt tên không? |
| BS-190 | (tiêu đề thẻ tranh) | Cái nong của bà Lành |
| BS-192 | Bà Lành | Nhà ông Thục. Năm người, đủ cả năm mảnh đây. |
| BS-193 | Bà Lành | Đứa bé không qua nổi mùa đông đầu tiên. |
| BS-194 | Bà Lành | Sao tự dưng hỏi chuyện ấy? |
| BS-195 | [Tên] | ...Không có gì ạ. |
| BS-196 | Bà Lành | Năm ấy có đoàn người phương bắc ở nhờ trại mấy tuần. Họ mang theo một đứa bé, chẳng cho ai bế. Khăn quấn nó có ô vuông như bàn cờ. Rồi cả đoàn đi về phía đèo. |
| BS-197 | Diệu | Bố tôi bị đánh roi ở Sân Tro. Chỉ vì cho một người lạ qua cổng. |
| BS-198 | Cỏ | Bà ơi! Nó lại xuống rồi! |
| BS-199 | (dòng mở trận đánh) | Tay trắng thò vào lều. Mảnh Sành bò theo sau. |
| BS-201 | Bà Lành | Mấy đêm nay nó xuống sớm hơn rồi. |
| BS-202 | (lời kể) | Phải về qua Cửa Cống trước khi chuông cổng vang lên. |

### Phần C. Nghi đầy: khám sư và người của Ty chặn ở quảng trường, thử lại

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-203 | Khám sư | Người gánh hòm cho bà Sương phải không? Có người báo lên rồi. Đưa tay đây. |
| BS-207 | (lựa chọn) | Tay cháu nứt vì gánh hòm. |
| BS-208 | (lựa chọn) | Chị Gấm ở Nhà Rửa cũng bị xám, sao chị ấy vẫn ở trong thành? |
| BS-209 | Khám sư | ...Giữ lại. |
| BS-210 | (lời kể) | Bị giữ ở Dinh Ty đến chiều. Không ai hỏi thêm câu nào. |
| BS-211 | Khám sư | ...Xám nhạt. Đi đi. |
| BS-212 | Khám sư | Gấm nào? ...Thôi, đi đi. Ty sẽ xuống Nhà Rửa. |

### Phần D. Số đếm ghép vào câu

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BX-026 | (số đếm (ghép vào câu "%s đêm chui qua Cửa Cống...")) | Một |
| BX-027 | (số đếm (ghép vào câu "%s đêm chui qua Cửa Cống...")) | Hai |
| BX-028 | (số đếm (ghép vào câu "%s đêm chui qua Cửa Cống...")) | Ba |
| BX-029 | (số đếm (ghép vào câu "%s đêm chui qua Cửa Cống...")) | Bốn |
| BX-030 | (số đếm (ghép vào câu "%s đêm chui qua Cửa Cống...")) | Năm |

### Phần D. Sáng sau buổi cuối: Chánh Ty Ngọc Khiết tới bắt, đưa lên Điện

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-284 | Người áo lam | Thưa Chánh Ty, người này. |
| BS-285 | Chánh Ty | Người gánh hòm của bà Sương. |
| BX-031 | Người áo lam | %s đêm chui qua Cửa Cống xuống trại. Có người thấy. |
| BS-287 | Người áo lam | Tự khai bị Nghiệt chạm. Thử lại vẫn xám. |
| BS-288 | Người áo lam | Lật Sổ Tro ở Dinh Ty lúc thư lại đi vắng. |
| BS-289 | Chánh Ty | Theo luật, hôm nay người này phải ra cổng. |
| BS-290 | Chánh Ty | Nhưng Bà muốn gặp người từ Vô Danh Cốc. |
| BS-291 | Chánh Ty | Đi sau tôi ba bước. Đừng để chạm vào ai. |

### Phần D. Lên Bạch Điện; người hầu câm, bát cơm không ai ăn ở bậc cửa

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-292 | (lời kể) | Lên mỗi tầng, người đi đường dạt sang hai bên. Không ai nhìn người đi sau Chánh Ty. |
| BS-293 | (lời kể) | Một bà già áo trắng đặt bát cơm lên bậc cửa rồi lùi vào trong. Bát cơm hôm qua vẫn còn nguyên. |
| BS-294 | Chánh Ty | Thưa Bà. Người từ Vô Danh Cốc. |
| BS-295 | Trong điện | Cho vào. |
| BS-296 | Trong điện | Ngọc Khiết, ở ngoài. |
| BS-297 | Chánh Ty | Thưa Bà, người này đã... |
| BS-298 | Trong điện | Ở ngoài. |

### Phần D. Trong điện: Băng Tâm quay lưng rửa tay. "Ngọc Khiết, ở ngoài." "Cho ta xem tay."

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-299 | (lời kể) | Gian điện rộng, trống và lạnh. Tường trắng, chân tường ốp sứ. Một người đứng quay lưng bên chậu nước, đang rửa tay. |
| BX-032 | (thẻ tên) | BĂNG TÂM |
| BS-300 | (thẻ tên) | Vị Tự của Bạch Sơn |
| BS-301 | Bà Tâm | Đứng đấy. |
| BS-302 | (lời kể) | Giữa hai người là một sải tay. Bà không bước lại gần. |
| BS-303 | Bà Tâm | Cho ta xem tay. |
| BS-304 | (tiêu đề thẻ tranh) | Lòng bàn tay, chìa ra |
| BS-305 | (lời kể) | Bà nhìn rất lâu. Không cầm tay, cũng không nói gì về điều mình thấy. |
| BS-306 | Bà Tâm | Ngọc Khiết bảo con chui qua Cửa Cống. |
| BS-307 | Bà Tâm | Ngọc Khiết bảo con tự khai bị Nghiệt chạm. |
| BS-308 | Bà Tâm | Ngọc Khiết bảo con lật Sổ Tro. |
| BS-309 | Bà Tâm | Con lên Bạch Sơn làm gì? |
| BS-310 | [Tên] | Đoàn của Lúa bị đuổi khỏi đây. Cái thứ ngoài cổng đuổi theo họ tới tận cửa đèo Vô Danh Cốc. |
| BS-311 | Bà Tâm | Tới cột mốc thì nó dừng. |
| BS-312 | [Tên] | ...Vâng. |
| BS-313 | (lời kể) | Bà im lặng một lúc. |
| BS-314 | Bà Tâm | Con thấy gì ở thành ta? |

### Phần D. Nhân vật chính nói thẳng với Tâm những điều đã nhận ra; Tâm đáp được chỗ nào thì đáp, chỗ không đáp được thì im

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-315 | [Tên] | Sắc nào cũng do Chánh Ty soạn. Bà đóng ấn. |
| BS-316 | Bà Tâm | Ta đọc. Tuần nào cũng đọc. |
| BS-317 | [Tên] | Bà đọc báo cáo. Còn Sổ Tro thì Bà không đọc. Cột đen ba trăm năm không có lấy một nét. |
| BS-318 | (lời kể) | Bà không đáp. |
| BS-319 | [Tên] | Tro không nhận ra Nghiệt. Nó chỉ chui vào kẽ. Tay nứt vì vôi hay nước thuốc cũng ra xám. |
| BS-320 | Bà Tâm | Tro không biết nói dối. |
| BS-321 | (lời kể) | Bà khép hai tay vào trong tay áo. |
| BS-322 | [Tên] | Người bị đuổi bị bán. Người của Ty đưa họ lên xe trắng, đếm đủ số rồi chở sang Vạn Thư. |
| BS-323 | Bà Tâm | Xe nào? |
| BS-324 | [Tên] | Xe của bà Sương. Năm nào bà ấy cũng lên. |
| BS-325 | (lời kể) | Bà im rất lâu. |
| BS-326 | Bà Tâm | Người đã nhiễm thì đằng nào cũng hóa sứ. |
| BS-327 | [Tên] | Hồi trước, người ra xám được giữ lại chờ Bà rửa men. Ông Sẹo ở Nhà Rửa vẫn còn sẹo. |
| BS-328 | Bà Tâm | Ông ta còn sống à? |
| BS-329 | [Tên] | ...Ông ấy bị đuổi rồi. Hôm kia. |
| BS-330 | (lời kể) | Bà không hỏi ai đã báo tin. |
| BS-331 | Bà Tâm | Cổ tay trái. Hình cánh mai. |
| BS-332 | [Tên] | Cái ngoài cổng không phải Sứ Giả. Nó là Nghiệt, sinh ra từ chính những ô cửa trong thành này. |
| BS-333 | Bà Tâm | Ra quảng trường nói câu ấy, người ta sẽ không để con nói hết đâu. |
| BS-334 | [Tên] | Người ta bị đuổi chỉ vì tay nứt. |

### Phần D. Lời đề nghị của Tâm (thu Thử Tro lại, lặng lẽ cho người mới bị đuổi về, nhưng không thừa nhận gì; đổi lại nhân vật chính không nói với ai), và lựa chọn

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-336 | Bà Tâm | Con muốn gì? |
| BS-337 | [Tên] | Bỏ các sắc. Mở cổng cho người ta về. |
| BS-338 | Bà Tâm | Mở cổng thì thứ ngoài kia cũng vào theo. |
| BS-339 | Bà Tâm | Ta đã thấy một lần. |
| BS-340 | (lựa chọn) | Kể về phiến đá ở nền cổng cũ. |
| BS-341 | (lựa chọn) | Không kể. |
| BS-342 | [Tên] | Dưới lớp vôi ở nền cổng cũ có một phiến đá. Trên đó khắc một chữ Khê. |
| BS-343 | Bà Tâm | Mấy vạch? |
| BS-344 | [Tên] | Ba. |
| BS-345 | (lời kể) | Bà không hỏi thêm. |
| BS-346 | Bà Tâm | Ta sẽ làm thế này. |
| BS-347 | Bà Tâm | Từ mai, tro chỉ giữ người thật sự bị chạm. Ai mới bị đuổi theo sắc họ hàng thì cho về dần. Không đọc sắc, không dán thông báo. Không ai cần biết. |
| BS-348 | Bà Tâm | Ty vẫn là Ty. Ngọc Khiết vẫn là Chánh Ty. |
| BS-349 | Bà Tâm | Đổi lại, con không nói với ai. |
| BS-350 | Bà Tâm | Báo cáo tuần này có tên con. |
| BS-351 | Bà Tâm | Ở cổng, con đỡ hòm từ tay một người khiêng. Người ấy ra cổng, con vào. |
| BS-352 | Bà Tâm | Con chỉ cho người áo lam một người ở Nhà Rửa. |
| BS-353 | Bà Tâm | Con cũng đã đẩy người khác ra ngoài cổng. |
| BS-354 | (lựa chọn) | Không. Mai ở Lễ Quét Vôi, cháu sẽ nói hết trước mọi người. |
| BS-355 | (lựa chọn) | ...Cháu sẽ không nói. |

### Phần D. Từ chối: rời điện; thẻ Lễ Quét Vôi

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-356 | Bà Tâm | Con tin chỉ cần nói ra là đủ sao? |
| BS-357 | (lời kể) | Bà quay lại chậu nước. |
| BS-358 | Bà Tâm | Ngọc Khiết. Để người này đi. Hôm nay không ai ra cổng. |
| BS-359 | Chánh Ty | ...Thưa Bà. |
| BS-360 | Chánh Ty | Mai ở quảng trường, đứng gần người này. |
| BS-361 | Người áo lam | Dạ. |

### Phần D. Nhận lời (biến thể b): tờ giấy của Tâm

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-362 | Bà Tâm | Ừ. |
| BS-363 | Bà Tâm | Ngọc Khiết. Để người này đi. Từ mai làm như ta dặn. |
| BS-364 | Chánh Ty | Thưa Bà. |
| BS-365 | (thẻ chương / thời gian) | Lễ Quét Vôi |
| BS-366 | (lời kể) | Năm ấy, Lễ Quét Vôi không đọc sắc nào. Người ta quét vôi lại bể rửa rồi về nhà. |
| BS-367 | (lời kể) | Chiều tối, cổng hé ra một khe. Mấy người trong trại đi vào, cúi đầu, không ai nói gì. Ông Sẹo đi sau cùng. |
| BS-368 | (lời kể) | Chiều tối, cổng hé ra một khe. Mấy người trong trại đi vào, cúi đầu, không ai nói gì. |
| BS-369 | (lời kể) | Đêm ấy, dưới trại vẫn có tiếng gõ trên sứ. Tiếng gõ chẳng thưa đi. |
| BS-370 | (tiêu đề thẻ tranh) | Tờ giấy gấp đôi |
| BS-371 | (lời kể) | Bà hầu câm đưa tờ giấy rồi quay lên. Bà Tâm không xuống. |

### Giao diện: Sổ ghi (mở bằng Tab)

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-239 | (chữ giao diện) | Sổ ghi |
| BS-243 | (chữ giao diện) | Tab: đóng |

### Giao diện: Sổ ghi, các mục

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-240 | (Sổ ghi (giao diện)) | Nhận ra |
| BS-242 | (Sổ ghi (giao diện)) | (chưa có) |
| BS-241 | (Sổ ghi (giao diện)) | Điều thấy |

### Giao diện: thẻ Thử Tro

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-64b | (tiêu đề thẻ tranh) | Lòng bàn tay, cổ tay |

### Giao diện: thanh Nghi và ngày giờ ở góc màn hình

| Mã | Ai nói / loại | Câu hiện tại |
|---|---|---|
| BS-237 | (chữ giao diện) | Nghi |
| BS-238 | (chữ giao diện) | Tab: Sổ ghi |

## 9. Chữ vẽ sẵn trong ảnh (tham khảo, không nằm trong khối trả về)

Mấy tấm thẻ tranh trong Phần C và D có chữ vẽ thẳng vào ảnh (trang Sổ Tro, sắc, quyển sổ bán tên, tờ giấy của Tâm). Nếu muốn đổi chữ ở đây, ghi ở phần Ghi chú, Claude sẽ vẽ lại ảnh.

- Trang Sổ Tro: tiêu đề "Tầng Rửa, tập PK 409", "Tầng Rửa, tập PK 410", "Tập đầu, năm PK 21", "Tầng Rửa, tập PK 395"; cột "Trắng", "Xám", "Đen".
- Sắc: "Thầy thuốc nào đã chữa cho người nhiễm, từ nay coi như nhiễm." / "Khám sư các cổng thử lại ngay, không đợi năm." (Năm PK 409); "Họ hàng của người đã bị đuổi phải ra khỏi cổng trước Lễ Quét Vôi." / "Không xét từng người." (Năm PK 412); dòng ký "Chánh Ty Ngọc Khiết soạn."; ấn "BẠCH ĐIỆN".
- Quyển sổ bán tên: "Giao, mùa thu", "Cộng, đủ số. Đã nhận.", ấn "VĂN LỤC · VẠN THƯ".
- Tập đầu: "Lệ của Ty Khám:", "Người bị Nghiệt chạm không vào.", "Người bị Nghiệt đuổi không vào.", "Đêm không mở cổng.", "Xám thì giữ lại ở Nhà Rửa, đợi Bà.", ghi chú "giữ lại ở Nhà Rửa.", "giữ lại. Bà đã rửa."
- Tập PK 395: "Nhà ... Luật Cả Nhà. Năm người.", "không thử", "Chồng, thợ muối", "Vợ, giặt liệm", "Mẹ chồng", "Con trai, mười hai tuổi", "Trẻ nhỏ, chưa tên."
- Tờ giấy của Tâm: "Rửa.", "Rắc tro cho kẽ hiện ra.", "Kẽ men thẳng, gãy góc, trên nền trắng.", "Kẽ da cong theo chỉ tay. Đừng nhầm.", "Lần theo kẽ men. Tới mép thì dừng.", "Cắt phần đã thối, không cắt người." (câu cuối là câu khóa của Tâm, giữ nguyên).
