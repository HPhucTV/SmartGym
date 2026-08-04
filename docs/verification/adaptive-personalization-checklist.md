# Bảng kiểm xác minh Cá nhân hóa Thích nghi Dinh dưỡng & Tập luyện

Tài liệu này dùng để theo dõi và ghi nhận kết quả kiểm thử thủ công và tự động đối với các tính năng thích nghi thích ứng của Gym App.

---

## 1. Danh sách kiểm thử tự động (Automated Verification)

| Bộ kiểm thử | Mục tiêu xác minh | Trạng thái |
|---|---|---|
| `AdaptationEngineTest` | 22 kịch bản về quy tắc thích nghi, bao gồm giới hạn calorie delta (min của 5% hoặc 150 kcal), cooldown 7 ngày, phát hiện nghỉ ngơi khi recovery kém, giảm volume khi bỏ lỡ tập. | ✅ ĐÃ ĐẠT |
| `RoomAdaptationRepositoryTest` | 9 kịch bản kiểm thử giao dịch: áp dụng tự động, xác nhận từ người dùng, chống stale target, co giãn tỷ lệ Carbohydrate/Chất béo và khôi phục (Undo) an toàn. | ✅ ĐÃ ĐẠT |
| `RecommendationViewModelTest` | Kiểm thử trạng thái UI (Loading, Success), bật/tắt quyền AI Coach (Cloud AI Consent), lấy thông tin giải thích AI từ Backend hoặc tự động fallback nội bộ. | ✅ ĐÃ ĐẠT |
| `AdaptiveJourneyEndToEndTest` | Kiểm thử tích hợp chu trình hoàn chỉnh: Tạo Hồ sơ -> Tính calorie ban đầu -> Nhập ăn uống -> Check-in tuần -> Thích nghi tự động -> Hoàn tác. | ✅ ĐÃ ĐẠT |
| `GymStyleAccessibilityTest` | Kiểm tra kích thước touch target của các nút hành động chính đạt tối thiểu 48dp và trạng thái disabled. | ✅ ĐÃ ĐẠT |

---

## 2. Danh sách kiểm thử thủ công (Manual Verification Matrix)

| Kịch bản kiểm thử | Trạng thái | Ghi chú |
|---|---|---|
| **Chế độ ngoại tuyến (Offline Mode)**: Tắt kết nối Internet/Backend, kiểm tra màn hình Đề xuất thích nghi phải tự động hiển thị mô tả giải thích nội bộ (local reasonVi) thay vì quay vòng vô tận. | ĐÃ TEST | Hoạt động bình thường. |
| **Quyền riêng tư (AI Cloud Consent)**: Tắt quyền AI Coach trong Hồ sơ cá nhân. Kiểm tra xem màn hình đề xuất có gửi yêu cầu HTTP đến `/api/coach/decision-explanations` hay không (phải không gửi). | ĐÃ TEST | Chặn gửi request đúng thiết kế. |
| **Nhập liệu số thập phân (Locale-safe input)**: Nhập cân nặng sử dụng dấu phẩy (Vietnamese locale: `78,5`) và dấu chấm (`78.5`). Đảm bảo ứng dụng tự động chuẩn hóa và không crash. | ĐÃ TEST | Chuẩn hóa mượt mà nhờ hàm `.replace(',', '.')`. |
| **Khả năng hiển thị nút Hoàn tác (Undo visibility)**: Kiểm tra nút Hoàn tác chỉ hiện trên thẻ quyết định cuối cùng được áp dụng của loại đó. Các thẻ cũ hơn hoặc thẻ đã từ chối không được hiện nút Hoàn tác. | ĐÃ TEST | Hiển thị chính xác theo trường `isUndoEligible` tính từ ViewModel. |
| **Độ phủ màn hình và tỷ lệ chữ (Accessibility Font Scaling)**: Tăng kích thước chữ của hệ thống lên mức lớn nhất (Large font). Kiểm tra xem các card đề xuất và thông số Calorie/Macro có bị tràn viền hay không. | ĐÃ TEST | Sử dụng Box/Row co giãn và cuộn tự động trong LazyColumn nên hiển thị tốt. |
# Xác minh bản nâng cấp chức năng 2026-07-04

## Quy tắc và ngưỡng đã triển khai

- Phản hồi sau buổi tập gồm `Quá nhẹ`, `Vừa sức`, `Quá nặng`; mỗi session chỉ lưu một bản ghi.
- Deload chỉ được đề xuất ngoài phase deload, sau cooldown 7 ngày, khi có 3 đánh giá `HARD` trong các mẫu gần nhất hoặc 2 `HARD` đi kèm 2 check-in phục hồi thấp liên tiếp. Xác nhận deload đặt volume các session sắp tới về 70%; undo chỉ phục hồi đúng các session chưa hoàn thành.
- Biến thể thời lượng là 15/30/45 phút hoặc đầy đủ, luôn giữ bài đầu tiên và một prefix có thứ tự. Không thể đổi sau khi đã tick bài.
- Nhận xét tuần cần ít nhất 2 tuần đầy đủ; xu hướng độ khó/thời lượng cần 4 mẫu, thứ ổn định cần 3 lần xuất hiện, xu hướng bám lịch cần chênh tối thiểu 15 điểm phần trăm.
- Dự báo mục tiêu cần ít nhất 2 buổi trong 2 tuần đầy đủ; đây chỉ là dự báo hoàn thành lịch tập.
- Mẫu bữa ăn: tên sau trim dài 1–60 ký tự, unique không phân biệt hoa/thường; calo > 0, macro không âm.

## Kết quả tự động của worktree `codex/functional-upgrades`

| Cổng | Kết quả quan sát |
|---|---|
| Focused JVM suite cho feedback/program/catalog/progress/Today/Nutrition | PASS — `BUILD SUCCESSFUL` ngày 2026-07-04 |
| Full `test` | PASS — `BUILD SUCCESSFUL` ngày 2026-07-04 |
| `lintDebug` | PASS sau khi thay API 35 `removeLast()` bằng `removeAt(lastIndex)`; 0 errors, 18 warnings |
| `compileDebugAndroidTestKotlin` | PASS |
| `assembleDebug` | PASS; tạo `app-debug.apk` |
| `connectedDebugAndroidTest` | PENDING — thiết bị `emulator-5564` chuyển sang offline trước khi chạy; 0 test được thực thi |

Không tuyên bố migration/Compose test đã chạy trên thiết bị trong lần xác minh này. Các kiểm tra thủ công về airplane mode, process death, rotation, theme và touch target vẫn `NOT RUN`.
