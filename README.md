# 🏋️‍♂️ SmartGym — Trợ lý Luyện tập Offline Toàn diện

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_SDK_24--36-F97316?style=for-the-badge&logo=android&logoColor=white" alt="Android Version">
  <img src="https://img.shields.io/badge/Mode-Offline_First-14213D?style=for-the-badge&logo=offline-share&logoColor=white" alt="Offline Mode">
  <img src="https://img.shields.io/badge/UI_Framework-Jetpack_Compose-22C55E?style=for-the-badge&logo=jetpackcompose&logoColor=white" alt="Compose Framework">
  <img src="https://img.shields.io/badge/Architecture-Clean_Architecture-F3F4F6?style=for-the-badge&logo=kotlin&logoColor=14213D" alt="Clean Architecture">
</p>

---

## 🎯 Định hướng Sản phẩm (Product Scope)

**SmartGym** là ứng dụng di động hỗ trợ luyện tập thể hình cá nhân dành cho hệ điều hành Android, được thiết kế theo triết lý **Offline-First**. Ứng dụng hoạt động hoàn toàn ngoại tuyến nhằm tối ưu hóa sự tập trung của người dùng trong phòng tập, không yêu cầu tài khoản, không đồng bộ đám mây và không chứa quảng cáo.

> [!NOTE]
> Ứng dụng được thiết kế như một công cụ lập kế hoạch luyện tập tổng quát. SmartGym **không đưa ra lời khuyên y tế** hoặc các phác đồ điều trị chấn thương.

---

## 🎨 Ngôn ngữ Thiết kế (Visual Identity & UI Specs)

Tuân thủ nghiêm ngặt các quy tắc giao diện đặc trưng được quy định trong thỏa thuận phát triển:

* **Màu sắc chủ đạo**:
  * Nền chính: Trắng tinh khiết (`#FFFFFF`) — Mang lại sự sạch sẽ, tối giản.
  * Văn bản chính: Xanh biển đậm (`#14213D`) — Tạo độ tương phản cao, dễ đọc dưới ánh sáng phòng tập.
  * Hành động & Điểm nhấn: Cam sáng (`#F97316`) — Kích thích năng lượng và sự tập trung.
  * Hoàn thành & Tiến độ: Xanh lá (`#22C55E`) — Biểu thị trạng thái thành công.
  * Bề mặt hỗ trợ: Xám nhạt (`#F3F4F6`) — Dùng cho thẻ, đường viền và phân vùng.
* **Phong cách phẳng (Flat UI)**:
  * Tuyệt đối không sử dụng hiệu ứng chuyển màu (gradients).
  * Viền mỏng, đổ bóng nhẹ và góc bo vừa phải tạo cảm giác hiện đại, gọn gàng.
  * Thiết kế phím bấm kích thước lớn (tối thiểu `48x48dp`), bố trí tối ưu cho thao tác bằng một tay.

---

## 🚀 Tính năng Cốt lõi (Core Features)

Ứng dụng được tổ chức xung quanh 3 điểm đến điều hướng chính:

### 1. Hôm nay (Today Screen)
* Hiển thị danh sách bài tập được chỉ định cho ngày hiện tại dựa trên chương trình tập luyện đã chọn.
* Tích chọn hoàn thành từng hiệp tập trực quan với bộ đếm ngược thời gian nghỉ ngơi (Rest Timer).
* Buổi tập chỉ được tính là hoàn thành khi tất cả các bài tập trong ngày được đánh dấu tích chọn.

### 2. Tiến độ (Progress Screen)
* **Biểu đồ đóng góp (Contribution Graph)**: Hiển thị tần suất luyện tập trong 18 tuần gần nhất dạng ô lưới trực quan (tương tự GitHub).
* **Lịch sử tập luyện**: Xem lại danh sách các buổi tập đã hoàn thành trong quá khứ dưới dạng lịch tháng.
* **Dự báo hoàn thành**: Ước tính thời gian hoàn thành mục tiêu dựa trên tốc độ và tần suất tập luyện thực tế của người dùng.

### 3. Cài đặt & Thích nghi (Settings & Adaptation)
* Thay thế hoặc điều chỉnh mục tiêu luyện tập hiện tại mà vẫn bảo toàn lịch sử tập luyện đã thực hiện.
* **Đề xuất thích nghi tự động (Automatic Adaptation)**: Đưa ra đề xuất điều chỉnh chế độ dinh dưỡng và cường độ tập luyện dựa trên phản hồi mức độ mệt mỏi sau mỗi buổi tập.
* Hỗ trợ giải thích đề xuất thích nghi bằng tiếng Việt (yêu cầu sự đồng ý của người dùng và kết nối mạng nếu sử dụng AI giải thích).

---

## 🏗️ Kiến trúc & Công nghệ (Tech Stack & Architecture)

Dự án được xây dựng dựa trên mô hình kiến trúc sạch (**Clean Architecture**), chia tách trách nhiệm rõ ràng giữa các tầng dữ liệu và giao diện người dùng:

```mermaid
graph TD
    UI[Tầng Giao diện - Jetpack Compose & ViewModels] --> Domain[Tầng Nghiệp vụ - UseCases & Repositories]
    Domain --> Data[Tầng Dữ liệu - Room DB & DataStore]
    Data --> Local[Tệp JSON Cứng - Bài tập & Giáo án mẫu]
```

* **Room Database**: Lưu trữ dữ liệu về mục tiêu, các buổi tập được tạo ra, lịch sử hoàn thành hiệp tập một cách nguyên tử (atomic transactions).
* **DataStore**: Lưu trữ các tùy chọn cấu hình nhỏ như thời gian nhắc nhở và thiết lập ngày nghỉ.
* **Bundled Assets**: Chứa dữ liệu tĩnh về bộ bài tập mẫu tiếng Việt (Free Exercise DB) và danh mục giáo án mẫu chuẩn hóa.
* **Coroutines & Flow**: Quản lý các luồng dữ liệu bất đồng bộ và đồng bộ hóa trạng thái giao diện UI phản ứng (Reactive UI).

---

## 🔧 Cài đặt & Kiểm thử (Setup & Testing)

Dự án sử dụng công cụ xây dựng Gradle tiêu chuẩn. Các lệnh CMD hữu ích trên môi trường Windows:

### Biên dịch ứng dụng
```powershell
# Biên dịch phiên bản chạy thử
.\gradlew.bat assembleDebug

# Biên dịch cả ứng dụng chính và bộ test Android tích hợp
.\gradlew.bat assembleDebug assembleDebugAndroidTest
```

### Chạy kiểm thử tự động
```powershell
# Chạy toàn bộ Unit Tests cục bộ (Logic thích nghi, Chọn giáo án, Lọc lịch,...)
.\gradlew.bat test

# Chạy kiểm thử giao diện và tích hợp trên thiết bị/trình giả lập (Instrumented Tests)
.\gradlew.bat connectedAndroidTest
```
