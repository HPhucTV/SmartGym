# Hướng dẫn & Nhật ký tích hợp Backend & Tính năng Dinh dưỡng (Smart Fuel)

Tài liệu này ghi lại chi tiết các thay đổi khi tích hợp backend Node.js (sử dụng Gemini API để nhận diện món ăn từ hình ảnh) và các giao diện dinh dưỡng, cơ chế tập bù calo (**Sweat Payment**), cùng tính năng **Trợ lý AI Coach nhận xét hằng ngày** và các nâng cấp giao diện responsive trên ứng dụng Android.

---

## 1. Tóm tắt các thay đổi trong Codebase

### 🖥️ A. Backend Server (Node.js & Express)
* **Thư mục:** `server/`
* **Các file chính:**
  * [server.js](file:///c:/Users/PC/Documents/Duy/Gym App/server/server.js): Cài đặt 2 endpoint POST chính:
    * `/api/analyze-food`: Nhận ảnh tải lên từ Android Client, gọi **Gemini API** để phân tích calo, dinh dưỡng vi lượng, đánh giá món ăn và đề xuất bài tập bù đắp (Sweat Payment).
    * `/api/coach-review`: Nhận dữ liệu mục tiêu tập luyện, mức calo và các nhóm dưỡng chất đã nạp của người dùng, gọi **Gemini API** để sinh lời khuyên thể hình/dinh dưỡng cá nhân hóa (1-3 câu tiếng Việt).
  * [package.json](file:///c:/Users/PC/Documents/Duy/Gym App/server/package.json): Khai báo các thư viện phụ thuộc gồm `express`, `cors`, `multer`, `dotenv`, và `@google/genai`.
  * [.env](file:///c:/Users/PC/Documents/Duy/Gym App/server/.env): Lưu cấu hình cổng PORT và `GEMINI_API_KEY`.

### 📱 B. Android Client (Dinh dưỡng, Sweat Payment & AI Coach)
* **Cấu hình & Quyền hạn:**
  * [AndroidManifest.xml](file:///c:/Users/PC/Documents/Duy/Gym App/app/src/main/AndroidManifest.xml): Thêm quyền Internet (`android.permission.INTERNET`) và Camera (`android.permission.CAMERA`).
  * [build.gradle.kts](file:///c:/Users/PC/Documents/Duy/Gym App/app/build.gradle.kts): Thêm thư viện `OkHttp` để hỗ trợ gọi API tải ảnh và lấy lời khuyên.
* **Tầng dữ liệu (Data & Domain):**
  * `NutritionRepository.kt`: Quản lý lưu trữ dinh dưỡng hàng ngày (Calo nạp vào, Carbs, Protein, Fat, mục tiêu calo), trạng thái Sweat Payment và nhận xét hằng ngày của AI (`aiCoachReview`) bằng **DataStore Preferences**.
  * `AppContainer.kt`: Khởi tạo và cung cấp `NutritionRepository` cho ứng dụng.
* **Giao diện người dùng (UI - Jetpack Compose):**
  * **Trợ lý Cố vấn Cục bộ (SmartCoachAdvisor)**:
    * [SmartCoachAdvisor.kt](file:///c:/Users/PC/Documents/Duy/Gym App/app/src/main/java/com/example/myapplication/feature/today/SmartCoachAdvisor.kt): Triển khai bộ phân tích dữ liệu ngoại tuyến (offline) để sinh ra lời khuyên chi tiết, thực tế dựa trên mục tiêu tập luyện (Tăng cơ, Giảm mỡ, Sức bền, Sức khỏe) và tỷ lệ nạp đạm/calo thực tế mà không cần kết nối mạng.
  * **Màn hình Dinh dưỡng** ([NutritionScreen.kt](file:///c:/Users/PC/Documents/Duy/Gym App/app/src/main/java/com/example/myapplication/feature/nutrition/NutritionScreen.kt)):
    * Vòng tròn tiến trình calo động biến đổi màu theo giới hạn calo.
    * Các thanh tiến trình macronutrients có màu sắc phân biệt trực quan (Đạm - Xanh lá, Tinh bột - Cam, Béo - Xanh dương).
    * Bốn thẻ hiển thị chỉ số dinh dưỡng (Calo, Đạm, Tinh bột, Béo) co giãn bằng tỷ lệ `weight(1f)` giúp tự động thích ứng với các dòng màn hình điện thoại từ hẹp đến rộng.
    * Thay thế các component gạch ngang `Divider` cũ bằng `HorizontalDivider` để tránh cảnh báo lỗi biên dịch (deprecation warnings).
  * **Màn hình Hôm nay & Phục hồi** ([TodayScreen.kt](file:///c:/Users/PC/Documents/Duy/Gym App/app/src/main/java/com/example/myapplication/feature/today/TodayScreen.kt)):
    * **Thẻ Hero Header**: Tách biệt lời chào mừng và các shortcut liên kết (`📚 Tra cứu`, `🥗 Dinh dưỡng`) thành 2 dòng riêng để tránh bị chồng chéo ký tự trên điện thoại màn hình nhỏ.
    * **Thẻ UI AI Coach (`AICoachTipCard`)**: Hiển thị hộp nhận xét cao cấp có viền nổi bật cùng biểu tượng robot `🤖`, chứa lời khuyên từ AI Coach và tích hợp nút **Cập nhật 🔄** để đồng bộ trực tiếp với máy chủ AI khi online. Xuất hiện cả trên giao diện danh sách tập luyện và giao diện nghỉ ngơi (RecoveryScreen).
  * **Màn hình Tạo mục tiêu** ([OnboardingScreen.kt](file:///c:/Users/PC/Documents/Duy/Gym App/app/src/main/java/com/example/myapplication/feature/onboarding/OnboardingScreen.kt)):
    * Các ô lựa chọn hiển thị thêm nút bấm chọn tròn (`RadioButton`) canh phải giúp giao diện trực quan và cao cấp hơn.
    * Thẻ tóm tắt mục tiêu (`ReviewCard`) được định dạng dưới dạng danh mục rõ ràng, chuyên nghiệp đi kèm các biểu tượng emoji phù hợp.
  * **Biểu đồ Tiến trình** ([ProgressCharts.kt](file:///c:/Users/PC/Documents/Duy/Gym App/app/src/main/java/com/example/myapplication/feature/progress/ProgressCharts.kt)):
    * Nhãn biểu đồ tuần được gán tỷ lệ co giãn động `weight(1f)` thay vì chiều rộng cố định `70.dp`, giúp hiển thị đều đặn trên máy tính bảng hoặc điện thoại màn hình siêu rộng.

---

## 2. Hướng dẫn Chạy và Kiểm thử

### Bước 1: Khởi động Backend
1. Sao chép `server/.env.example` thành `server/.env`, sau đó điền `GEMINI_API_KEY` trên máy cục bộ. Không commit hoặc chia sẻ file `server/.env`.
2. Di chuyển terminal vào thư mục `server/` và khởi chạy server:
   ```bash
   npm install
   node server.js
   ```
   *Server sẽ thông báo: `Server Gym App Backend đang chạy tại http://localhost:3000`*

### Bước 2: Chạy ứng dụng Android
1. Mở Emulator hoặc kết nối thiết bị Android của bạn ở chế độ Debug.
2. Kiểm tra **Chế độ Offline**: Tắt server, mở app. Thẻ AI Coach sẽ tự động hiển thị lời khuyên sức khỏe và ăn uống dựa trên giải thuật cục bộ (ví dụ: khuyên ăn thêm đạm nếu lượng đạm nạp vào thấp).
3. Kiểm tra **Chế độ Online**: Bật server backend. Nhấn nút **"Cập nhật 🔄"** trên thẻ AI Coach. Đảm bảo server gọi Gemini API thành công và trả về nhận xét động sinh động.
4. Kiểm tra **Tập bù calo (Sweat Payment)**: Vào tab Dinh dưỡng, quét đĩa ăn dư calo, bấm "Xác nhận ăn". Quay lại tab Hôm nay để xác nhận bài tập tương ứng đã được tự động cộng bù số hiệp tập kèm ngọn lửa đánh dấu `(+X hiệp bù calo 🔥)`.
---

## 3. Bảo mật và ranh giới cá nhân hóa

- Backend và Gemini là tính năng tùy chọn. Lập kế hoạch tập, mục tiêu dinh dưỡng, check-in và các quy tắc điều chỉnh cốt lõi phải tiếp tục hoạt động khi offline.
- Chỉ gửi ảnh hoặc dữ liệu hồ sơ lên backend sau khi người dùng bật đồng ý sử dụng AI đám mây riêng biệt. Khi chưa đồng ý, ứng dụng chỉ dùng phân tích cục bộ.
- Gemini chỉ giải thích quyết định bằng tiếng Việt; không được tự tạo giáo án, thay đổi lịch tập hoặc áp dụng điều chỉnh.
- Điều chỉnh nhỏ, có thể hoàn tác mới được tự động áp dụng. Thay đổi chương trình, số buổi, mục tiêu, khối lượng tập hoặc mức calo lớn phải được người dùng xác nhận.
- `server/.env` và `server/node_modules/` là dữ liệu cục bộ, không được đưa vào Git. Chỉ `server/.env.example` được lưu để mô tả tên biến cấu hình.
- Ứng dụng cung cấp hướng dẫn sức khỏe tổng quát, không chẩn đoán hoặc thay thế tư vấn y tế.
