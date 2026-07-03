# Checklist rà soát chương trình tập preset

## Rà soát lịch thích ứng

- Mỗi tổ hợp mục tiêu, trình độ và dụng cụ có đúng một chương trình nền đã kiểm duyệt.
- Các buổi tuần đầu tạo thành chu kỳ blueprint có thứ tự cho lịch 1–6 buổi/tuần.
- Bài trong mỗi buổi được xếp từ thiết yếu đến bổ trợ; buổi ngắn giữ các bài đứng trước.
- Biến thể 30 phút luôn có bài và giữ trọng tâm vận động chính.
- Các mốc dài hơn chỉ thêm bài đã có trong chương trình nền, không tự sinh hoặc chọn ngẫu nhiên.
- Cùng một cấu hình luôn tạo cùng snapshot buổi tập.
- Trước khi phát hành cần rà thủ công đầu ra 30, 45, 60, 75 và 90 phút.

- Ngày rà soát dự án: **2026-06-30**
- Phạm vi: 6 chương trình, 116 buổi tập đã mở rộng theo tuần trong `programs.json`.
- Trạng thái rà soát: kiểm tra tự động và kiểm tra bằng agent đã đạt; chưa có người dùng hoặc chuyên gia bên ngoài rà soát từng buổi.
- Kiểm tra tự động trước khi duyệt: parse JSON, tiếng Việt không lỗi mã hóa, ma trận chương trình, 116 buổi, khóa tham chiếu bài tập, thứ tự tuần/buổi, giới hạn hiệp-lần-thời gian-nghỉ, thứ tự bài ghép trước bài phụ/thân giữa và tổng lịch 7 ngày đều đạt.
- Quy tắc cơ liên tiếp: hai buổi là hai ngày tập liên tiếp khi buổi trước có `restDaysAfter == 0`; hai ngày như vậy không được trùng nhóm cơ chính. Nếu có ít nhất một ngày phục hồi được khai báo giữa hai buổi thì quy tắc này được đặt lại.
- Rà soát cuối của con người: **đang chờ**. Mọi trạng thái cuối bên dưới giữ ở `PENDING_USER_REVIEW` cho đến khi người dùng đọc và duyệt từng chương trình.

| Chương trình | Phù hợp mục tiêu | Bài tập sẵn có | Cân bằng nhóm cơ | Kiểm tra cơ liên tiếp | Khối lượng tuần | Khoảng nghỉ | Phù hợp người mới | Hướng dẫn tiếng Việt | Duyệt cuối |
|---|---|---|---|---|---|---|---|---|---|
| general-beginner-bodyweight-3x-4w | Đạt: thể lực toàn thân | Đạt: chỉ bodyweight | Đạt: squat/hinge/push/pull/core | Đạt: mọi cặp đều có ngày phục hồi 1/1/2 | Đạt: 2 hiệp tuần 1–2, 3 hiệp tuần 3–4 | Đạt | Đạt: biến thể chống đẩy dễ và lần lặp vừa phải | Đạt: mọi ID trỏ tới catalog đã dịch | **PENDING_USER_REVIEW** |
| conditioning-beginner-bodyweight-4x-4w | Đạt: điều hòa và tiêu hao năng lượng | Đạt: chỉ bodyweight | Đạt: cardio/core/chân/thân trên/toàn thân | Đạt: các cặp nghỉ 0 ngày không trùng cơ chính | Đạt: tăng hiệp và thời lượng nhỏ | Đạt | Đạt: tuần 1–2 dùng jumping jack tác động thấp | Đạt | **PENDING_USER_REVIEW** |
| endurance-beginner-bodyweight-3x-4w | Đạt: sức bền tim mạch | Đạt: đi bộ và bodyweight | Đạt: cardio chính, core/bắp chân hỗ trợ | Đạt: mọi cặp có ngày phục hồi 1/1/2 | Đạt: thời lượng mỗi bước tăng không quá 10% | Đạt: 1/1/2 ngày | Đạt: cường độ thấp, tiến triển từ từ | Đạt | **PENDING_USER_REVIEW** |
| muscle-beginner-dumbbells-3x-4w | Đạt: tăng cơ nền tảng | Đạt: tạ đơn và bodyweight | Đạt: chân/hinge/push/pull/vai-tay/core trong A/B/C | Đạt: mọi cặp có ngày phục hồi 1/1/2 | Đạt: 2 hiệp tuần 1–2, 3 hiệp tuần 3–4 | Đạt | Đạt: bài cơ bản, 8–15 lần, nghỉ 45–75 giây | Đạt | **PENDING_USER_REVIEW** |
| general-intermediate-gym-4x-8w | Đạt: thể lực tổng quát trung cấp | Đạt: thiết bị full gym | Đạt: upper/lower cân bằng | Đạt: các cặp nghỉ 0 ngày không trùng cơ chính | Đạt: 2 pha 4 tuần; pha 2 đổi tối đa 1 bài/buổi | Đạt: 0/1/0/2 | Không áp dụng: chương trình trung cấp; mức tải hợp lý | Đạt | **PENDING_USER_REVIEW** |
| muscle-intermediate-gym-4x-8w | Đạt: tăng cơ trung cấp | Đạt: thiết bị full gym | Đạt: hai upper và hai lower, đủ bài ghép/phụ | Đạt: các cặp nghỉ 0 ngày không trùng cơ chính | Đạt: 2 pha; tăng hiệp bài ghép và đổi 1 phụ kiện/buổi | Đạt: 0/1/0/2 | Không áp dụng: chương trình trung cấp; kê đơn trong giới hạn | Đạt | **PENDING_USER_REVIEW** |

Các chương trình này là kế hoạch thể lực chung, không phải tư vấn y khoa hoặc phác đồ phục hồi chấn thương.
