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
| **Quyền riêng tư (AI Cloud Consent)**: Tắt quyền AI Coach trong Hồ sơ cá nhân. Kiểm tra xem màn hình đề xuất có gửi yêu cầu HTTP đến `/api/explain-decision` hay không (phải không gửi). | ĐÃ TEST | Chặn gửi request đúng thiết kế. |
| **Nhập liệu số thập phân (Locale-safe input)**: Nhập cân nặng sử dụng dấu phẩy (Vietnamese locale: `78,5`) và dấu chấm (`78.5`). Đảm bảo ứng dụng tự động chuẩn hóa và không crash. | ĐÃ TEST | Chuẩn hóa mượt mà nhờ hàm `.replace(',', '.')`. |
| **Khả năng hiển thị nút Hoàn tác (Undo visibility)**: Kiểm tra nút Hoàn tác chỉ hiện trên thẻ quyết định cuối cùng được áp dụng của loại đó. Các thẻ cũ hơn hoặc thẻ đã từ chối không được hiện nút Hoàn tác. | ĐÃ TEST | Hiển thị chính xác theo trường `isUndoEligible` tính từ ViewModel. |
| **Độ phủ màn hình và tỷ lệ chữ (Accessibility Font Scaling)**: Tăng kích thước chữ của hệ thống lên mức lớn nhất (Large font). Kiểm tra xem các card đề xuất và thông số Calorie/Macro có bị tràn viền hay không. | ĐÃ TEST | Sử dụng Box/Row co giãn và cuộn tự động trong LazyColumn nên hiển thị tốt. |
