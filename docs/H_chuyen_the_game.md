# Thập Quốc · Deliverable H: Đề xuất chuyển thể thành game

**Ngày:** 2026-10-11
**Trạng thái:** đề xuất ở mức cấu trúc, chờ người dùng duyệt. Không có code.
**Dựa trên:** A đến G.

## 0. Những gì đã có trước brief

Trước khi có brief, người dùng đã chọn hình thức: **2.5D (sprite 2D trong thế giới 3D, kiểu Octopath), thể loại RPG phiêu lưu bắt quái, làm bằng Godot 4.7.2**. Brief yêu cầu không giả định thể loại hay cách chiến đấu cho tới khi A đến G mạch lạc. Vì vậy H làm hai việc:

1. So sánh các hình thức game mà câu chuyện có thể chịu được, kể cả hình thức người dùng đã chọn.
2. Trả lời câu hỏi để ngỏ từ A24: "bắt quái" có hợp với chủ đề không.

Mọi khuyến nghị dưới đây là **PROPOSAL**.

---

## 1. Câu chuyện đòi hỏi gì ở bất kỳ hình thức game nào

Rút ra từ A đến G. Một hình thức game không làm được những điều này sẽ làm yếu câu chuyện.

| # | Đòi hỏi | Nguồn |
|---|---|---|
| 1 | **Nhịp về nhà** sau mỗi nước: người chơi phải *sống* cùng ông lão (ăn cơm, làm việc nhà), không chỉ xem cảnh cắt. Tình thương của ông thể hiện qua việc làm. | C 2.3, E 0 |
| 2 | **Động tác đầu tiên và cuối cùng là một**: chẻ củi ở mở đầu và nhát chém ở kết phải là cùng một thao tác của người chơi. | G 5 |
| 3 | **Điều tra bằng Nối**: chạm vào Nghiệt hay dấu vết của nó thì thoáng thấy nguồn gốc. Đây là cách người chơi hiểu từng nước. | B Luật 2 |
| 4 | **Đánh tan khác với giải**: đánh chỉ là tạm thời; Nghiệt chỉ tan hẳn khi dục vọng gốc thôi tuyệt đối. | B Luật 1 (APPROVED) |
| 5 | **Lựa chọn có giá và để lại hậu quả** qua nhiều chương: người chết, luật được sửa, món nợ. | D, E |
| 6 | **Không phải nước nào cũng kết thúc bằng đấu boss.** | Brief mục 6, D 2 |
| 7 | **Đồ vật làm manh mối**: móc áo, cái bát, hũ tiền, dép, xà nhà. Người chơi phải có thời gian và lý do để nhìn chúng. | F |
| 8 | **Trận cuối không có mười chữ**: chỉ còn nét gốc. | E 6 |
| 9 | **Một lựa chọn cuối thật**: phải có khả năng người chơi chọn viết chữ thứ mười một. | G 1, dòng 2 |

---

## 2. Ba hình thức có thể

| | **H1. RPG theo lượt, 2.5D** (khuyến nghị) | H2. RPG hành động thời gian thực | H3. Phiêu lưu kể chuyện, chiến đấu nhẹ |
|---|---|---|---|
| Mô tả | Khám phá 2.5D, chiến đấu theo lượt có bấm đúng nhịp, chương theo từng nước. Chính là hình thức người dùng đã chọn. | Chém trực tiếp, né, combo. | Khám phá, hội thoại, giải đố, chọn lựa. Chiến đấu ít và đơn giản. |
| Hợp với đòi hỏi 1 (về nhà) | Tốt. Nhịp chậm hợp cảnh đời thường. | Vừa. Cảnh đời thường lệch nhịp với lối chơi nhanh. | Rất tốt. |
| Hợp với đòi hỏi 2 (một động tác) | Tốt: một nút bấm đúng nhịp, giống nhau ở chẻ củi và ở nhát cuối. | Rất tốt: chém là động tác gốc của thể loại. | Vừa: phải tạo riêng một thao tác. |
| Hợp với 3 và 4 (Nối, giải Nghiệt) | Rất tốt: có thời gian để "thấu", và có chỗ cho một lớp khiên "Chấp" tách khỏi máu. | Khó: dừng giữa trận để thoáng thấy làm gãy nhịp. | Tốt, nhưng mất phần đối kháng. |
| Hợp với 5, 6 (lựa chọn, không phải nước nào cũng có boss) | Tốt. | Vừa: thể loại kéo về phía boss. | Rất tốt. |
| Cảm giác "mười vị Tự mạnh khủng khiếp" | Tốt. | Rất tốt. | Yếu. |
| Chi phí làm | Vừa đến cao (nhiều hệ thống, nhiều nội dung). | Cao (cảm giác đánh phải rất tốt). | Thấp đến vừa. |
| Rủi ro lớn nhất | Mười chương thành một công thức lặp. D đã thiết kế để tránh. | Câu chuyện bị nuốt bởi chiến đấu. | Người chơi muốn chiến đấu sẽ thấy thiếu. |

**Khuyến nghị: H1.** Nó khớp với hình thức người dùng đã chọn, đáp ứng tốt nhất đòi hỏi 3 và 4 (thứ làm nên bản sắc chủ đề của game), và cho nhịp đủ chậm để nhịp về nhà có sức nặng.

---

## 3. "Bắt quái" và chủ đề

**Vấn đề (A24):** Nghiệt là dục vọng thành hình (B Luật 1, APPROVED). Bắt và sở hữu chúng chính là logic kiểm soát mà câu chuyện phê phán: đó là cách nghĩ của Nhất Tự.

| | Hướng | Mô tả | Hợp chủ đề | Rủi ro |
|---|---|---|---|---|
| a | Bỏ hẳn | Không có cơ chế thu thập nào. | Hoàn toàn. | Mất thứ người dùng thích ở ý tưởng ban đầu. |
| **b** | **Giải Nghiệt và Tiểu Niệm** (khuyến nghị) | Khi một Nghiệt nhỏ được *giải* (không phải bị đánh tan), dục vọng của nó trở về cỡ của con người: lòng tham thành sự chắt chiu, nỗi sợ thành sự cẩn thận. Nó để lại một **Tiểu Niệm**, một sinh linh nhỏ, và Tiểu Niệm **tự chọn** có đi theo nhân vật chính hay không. Có một **Sổ Nghiệt** ghi lại điều người chơi đã *hiểu* về mỗi loại Nghiệt, thay cho sổ "đã bắt được". | Cao. Thu thập trở thành hệ quả của việc hiểu, không phải của việc chiếm. Tiểu Niệm có quyền từ chối, đúng triết lý của người thầy. | Phải viết thêm luật cho Tiểu Niệm. Đây là một mở rộng của Luật 1 và **cần người dùng duyệt**. |
| c | Giữ việc bắt, biến nó thành thứ truyện chất vấn | Người chơi bắt được Nghiệt và dùng sức mạnh của chúng, nhưng mỗi con bị giữ làm dấu Nghiệt trên tay nhân vật chính lớn thêm (B Luật 4). Dùng nhiều thì tới cuối game gần như đã chọn chữ thứ mười một. | Cao, theo cách tối. Cơ chế trở thành chính lời phê phán. | Người chơi bị "phạt" vì chơi theo cách game cho phép. Dễ gây khó chịu nếu không làm rất khéo. |

**Khuyến nghị: b.** Nó giữ được niềm vui sưu tầm của ý tưởng ban đầu, đồng thời biến mỗi lần sưu tầm thành một hành động thấu hiểu.

---

## 4. Cấu trúc đề xuất (nếu chọn H1 và hướng b)

### 4.1. Cấu trúc lớn: bánh xe

- **Vô Danh Cốc là trung tâm.** Người chơi luôn về đây sau mỗi nước.
- **Mười nước là mười nan hoa**, đi theo thứ tự ở E. Thứ tự này cố định trong lần chơi đầu, vì mỗi nước được nối với nước sau bằng nhân quả.
- **Mỗi lần về nhà là một buổi tối chơi được:** làm một việc nhà với ông lão, ăn cơm, kể chuyện, ngủ. Đây là nơi phần lớn manh mối nằm (F), và là nơi người chơi *cảm thấy* tình thương của ông lão qua việc làm.

### 4.2. Một chương ở một nước, không theo một khuôn

D đã định cho mỗi nước một loại xung đột, một vai trò của nhân vật chính và một kiểu kết thúc khác nhau. Mỗi chương nên có hình dạng gameplay khác nhau tương ứng:

| Nước | Hình dạng chương gợi ý |
|---|---|
| Bạch Sơn | Trà trộn và điều tra trong thành; cao trào là bạo loạn trên quảng trường. |
| Xích Hoang | Một chuyến đi dài qua bão, quản lý sức của cả đoàn; cao trào là cõng bé gái. |
| Kim Thành | Đọc sổ sách, theo dấu tiền; cao trào là phiên đấu giá. |
| Mộng Trạch | Khám phá trong sương; cao trào là một chuỗi lặn xuống đầm. |
| Vạn Thư | Ba mươi ngày làm đối tượng thí nghiệm: một chuỗi ngày được chia nhịp. |
| Táng Thiên | Tranh luận và xây dựng; cao trào là nghi lễ chôn bàn thờ, rồi trận Nghiệt Phá. |
| Vô Diện | Trà trộn khi đeo mặt nạ; cao trào là buổi lễ đặt tên. |
| Hải Uyên | Phòng thủ có giới hạn thời gian; lựa chọn chiếm hải đăng hay thuyết phục từng người. |
| Thiết Sơn | Đấu tay đôi thuần túy, trận khó nhất về kỹ năng. |
| Thiên Mệnh | Một thành phố hoàn hảo đáng sợ; lựa chọn cuối; trận cuối. |

### 4.3. Hệ thống cốt lõi

**Nét gốc, học từ việc nhà.** Ba việc nhà ở mở đầu (chẻ củi, quét sân, gánh nước) là ba hướng dẫn trá hình cho ba thao tác chiến đấu gốc. Tất cả dùng chung một kiểu bấm đúng nhịp.

| Việc nhà | Thao tác chiến đấu |
|---|---|
| Chẻ củi | **Bổ:** một đòn mạnh, bấm đúng lúc để "dứt". |
| Quét sân | **Quét:** đánh lan nhiều mục tiêu. |
| Gánh nước | **Thủ:** giữ thăng bằng, đỡ đòn đúng lúc. |

**Mười chữ.** Mỗi di sản thêm một nhóm kỹ thuật mang tính cách của vị Tự đã dạy (D, mục 12 của từng nước): Rửa, Gánh, Cân, Lặng, Ghi, Buông, Hòa, Dạt, Đứng, Định.

**Chiến đấu với Nghiệt.** Mỗi Nghiệt có hai thanh:

- **Hình:** máu. Về 0 thì Nghiệt tan, nhưng sẽ tụ lại. Vùng đất xung quanh vẫn bị ảnh hưởng.
- **Chấp:** độ tuyệt đối của dục vọng. Chỉ giảm bằng những hành động nhắm vào gốc của nó, những thứ người chơi biết được qua **Thấu** (Nối) và qua điều tra ngoài trận. Về 0 thì có thể **Giải**: Nghiệt tan hẳn, vùng đất hồi phục, và có thể để lại một Tiểu Niệm.

**Lựa chọn và hậu quả.** Lựa chọn ở mỗi nước thay đổi kết quả tại chỗ (ai sống, luật nào được sửa) và trạng thái thế giới về sau (mật độ Nghiệt, thái độ của dân, những người tị nạn xuất hiện ở Hải Uyên). Mạch truyện chính (E) là một con đường, các lựa chọn khác tạo biến thể nhưng không phá cấu trúc.

**Điều khoản người nhà như một chi tiết hệ thống.** Người ở các nước có những câu thoại quên ông lão ("Có kể rồi mà tôi quên mất"). Lúa hỏi tên ông theo một lịch cố định. Không giải thích, chỉ lặp lại vừa đủ để người chơi cảm thấy.

### 4.4. Đoạn kết như một cơ chế

- **Lựa chọn cuối là một thao tác thật.** Mười chữ hiện quanh lưỡi kiếm. Người chơi có thể ghép chúng thành chữ thứ mười một, hoặc không làm gì và buông.
- **Nhát chém là thao tác chẻ củi.** Cùng một nút, cùng nhịp, cùng âm thanh như phút đầu tiên của game.
- **Trận cuối chỉ có Bổ, Quét, Thủ.**
- **Kết khác (đề xuất): "Chữ Thứ Mười Một".** Nếu người chơi viết chữ thứ mười một, nhân vật chính xích được Nghiệt Định và xích cả thế giới. Không có nhát chém. Cảnh cuối: ông lão vẫn đứng ở cửa lúc chạng vạng, vẫn chờ, không cười. Hết. Kết này cho thấy lựa chọn của người chơi thật sự quyết định nhát chém (brief 8.2 câu 8 và 11).

### 4.5. Thời lượng ước tính

| Phần | Thời lượng |
|---|---|
| Mở đầu | 45 phút đến 1 giờ |
| Mỗi nước | 2 đến 3 giờ |
| Mỗi lần về nhà | 10 đến 15 phút |
| Kết | 30 đến 45 phút |
| **Tổng** | **khoảng 25 đến 35 giờ** |

### 4.6. Tội của nơi ấy (DUYỆT Q43, 2026-10-13)

Ở mỗi nước, nhân vật chính được phép phạm **đúng tội của nước đó**, và tội ấy mọc ra từ chính luật lệ của nơi ấy.

1. **Mỗi nước có một thước đo của riêng nó** (Bạch Sơn: thanh Nghi của Ty, tức "sạch" trong mắt Ty).
2. **Thước đo ấy thưởng cho đúng tội của nước đó.** Không có nút "làm ác". Đi theo luật nơi ấy cho nhanh, cho an toàn là đang phạm tội của nơi ấy; người chơi tối ưu sẽ tự rơi vào.
3. **Lý lẽ đưa ra là lý lẽ của người địa phương**, nói bằng chính câu của họ.
4. **Mỗi lần phạm, một người có tên trả giá và quay lại sau**, có khi ở chương khác. Không thanh thiện ác, không game over, không làm lại.
5. **Cám dỗ phải thật:** đường ác phải ngon hơn về mặt chơi (ít việc hơn, thắng chắc hơn, mở thông tin sớm hơn). Đường ngay cũng có giá.
6. **Không cày được:** số lần phạm có hạn, mỗi lần là một cảnh có người thật. Người bị đẩy đi mang theo phần sự thật của họ, nên phạm tội làm mất manh mối.
7. **Không đụng arc chính:** điều không thể bào chữa của nhân vật chính vẫn ở Hải Uyên (C 1.2). Tội của từng nơi là tùy chọn và nhỏ hơn.

Bạch Sơn làm trước (`N_bach_son.md` 9.6). Ví dụ hướng cho các nước khác, chưa duyệt: Xích Hoang là bỏ người chậm lại (Luật Gánh), Kim Thành là định giá một con người, Vạn Thư là dùng người để biết.

---

## 5. Định hướng hình ảnh và âm thanh (mức tổng quát)

- **2.5D, sprite pixel trong thế giới 3D**, đúng lựa chọn của người dùng. Camera nghiêng, có làm mờ tiền cảnh và hậu cảnh để thế giới giống những sa bàn thu nhỏ.
- **Mỗi nước một bảng màu gắn với Nghiệt của nó:**

| Nước | Bảng màu |
|---|---|
| Bạch Sơn | Trắng sứ, xám tro |
| Xích Hoang | Đỏ cát |
| Kim Thành | Vàng trên nền mục |
| Mộng Trạch | Sương xanh |
| Vạn Thư | Mực đen trên giấy |
| Táng Thiên | Tro xám |
| Vô Diện | Màu da không đường nét |
| Hải Uyên | Xanh đêm và muối trắng |
| Thiết Sơn | Gỉ sắt |
| Thiên Mệnh | Ô bàn cờ, vàng đỏ cung đình |

- **Vô Danh Cốc** là nơi duy nhất có màu tự nhiên, ấm, không bị Nghiệt nhuộm.
- **Ngôi nhà thay đổi theo game:** thêm đồ vật mỗi lần về (dây cõng, hũ tiền được hỏi tới, cái bát).
- **Âm nhạc:** bài hát ru (Nhiên và ông lão) là chủ đề chính, nghe lần đầu ở mở đầu và trở lại ở Mộng Trạch và ở kết. Tiếng chẻ củi là âm thanh của cả game.

---

## 6. Bản thử nghiệm đầu tiên nên làm gì (khi người dùng cho phép viết code)

Đề xuất làm **Mở đầu cộng Bạch Sơn** trước. Phần này kiểm tra được mọi thứ quan trọng của game trong khoảng 2 tới 3 giờ chơi:

- Việc nhà dạy thao tác chiến đấu (đòi hỏi 2).
- Luật Nối, ở trận Nghiệt đầu tiên (đòi hỏi 3).
- Nghiệt Tịnh, với cả Hình lẫn Chấp (đòi hỏi 4).
- Một lần về nhà (đòi hỏi 1).
- Một lựa chọn có giá thật: bạo loạn (đòi hỏi 5).
- Manh mối đồ vật trong ngôi nhà (đòi hỏi 7).

---

## 7. Không nên làm

| Không nên | Vì sao |
|---|---|
| Gặp Nghiệt ngẫu nhiên khi đi đường, đánh để lấy kinh nghiệm | Nghiệt là dục vọng tụ lại ở những nơi cụ thể (B Luật 1). Biến chúng thành quái vô danh để luyện cấp là phản chủ đề. Mỗi Nghiệt nên đặt ở một chỗ có lý do. |
| Cây kỹ năng tách khỏi câu chuyện | Kỹ năng phải đến từ việc nhà và từ mười chữ. |
| Thu phí, dịch vụ trực tuyến | Brief cấm ở giai đoạn này, và không hợp một câu chuyện có kết thúc. |
| Cảnh cắt dài giải thích luật | Brief cấm thuyết minh dài. Luật nên được cảm thấy qua cơ chế. |

---

## 8. Những điểm cần người dùng quyết

1. Hình thức game: H1 (khuyến nghị), H2 hay H3.
2. "Bắt quái": hướng a, b (khuyến nghị) hay c.
3. Nếu chọn b: có thêm luật Tiểu Niệm vào bộ luật thế giới không (mở rộng Luật 1).
4. Có làm kết khác "Chữ Thứ Mười Một" không.
5. Bản thử nghiệm đầu tiên: Mở đầu cộng Bạch Sơn, hay phần khác.
