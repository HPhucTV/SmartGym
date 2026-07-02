# Báo cáo Triển khai Task 6, 7, 8, 9 & 10: Bộ quy tắc thích nghi lai & Vòng đời quyết định giao dịch

Tài liệu này ghi nhận toàn bộ các thay đổi, cấu trúc mã nguồn, thiết kế UI và kết quả kiểm thử cho toàn bộ tính năng thích nghi thích ứng thuộc kế hoạch nâng cấp Gym App.

---

## 1. Tổng quan các file được thêm mới & chỉnh sửa

### 📂 File được tạo mới (New Files)
1. **[WeeklySnapshot.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/core/adaptation/WeeklySnapshot.kt)**: Lớp dữ liệu bất biến gom toàn bộ dữ liệu tuần (tiêu thụ calorie, cân nặng gần đây, chỉ số check-in, số buổi tập bị bỏ lỡ, thời gian cooldown).
2. **[AdaptationDecision.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/core/adaptation/AdaptationDecision.kt)**: Lớp dữ liệu thể hiện quyết định thích nghi ở tầng domain (gồm loại quyết định, chế độ tự động áp dụng hoặc cần xác nhận, lý do tiếng Việt, và dữ liệu JSON trước/sau/hoàn tác).
3. **[AdaptationEngine.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/core/adaptation/AdaptationEngine.kt)**: Bộ quy tắc thích nghi thuần Kotlin (pure logic) quyết định việc điều chỉnh calorie, đề xuất ngày nghỉ phục hồi và thay đổi khối lượng tập luyện một cách tất định.
4. **[AdaptationRepository.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/data/AdaptationRepository.kt)**: Interface quản lý lưu trữ và vòng đời của quyết định thích nghi (ghi nhận, chấp nhận, từ chối, hoàn tác).
5. **[RoomAdaptationRepository.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/data/RoomAdaptationRepository.kt)**: Lớp triển khai `AdaptationRepository` sử dụng Room Database. Thực hiện mọi thay đổi trạng thái và cập nhật calorie trong một giao dịch (`database.withTransaction`) nhằm đảm bảo tính toàn vẹn dữ liệu.
6. **[CoachExplanationClient.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/data/CoachExplanationClient.kt)**: Khách hàng HTTP gửi yêu cầu giải thích quyết định thích nghi lên máy chủ backend.
7. **[RecommendationUiState.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/feature/recommendations/RecommendationUiState.kt)**: Định nghĩa trạng thái UI (Loading, Success) cho màn hình Trung tâm đề xuất.
8. **[RecommendationViewModel.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/feature/recommendations/RecommendationViewModel.kt)**: ViewModel quản lý trạng thái, lấy quyết định từ Repository, thực hiện các hành động chấp nhận/từ chối/hoàn tác và tải không đồng bộ giải thích từ AI Coach.
9. **[RecommendationScreen.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/feature/recommendations/RecommendationScreen.kt)**: Màn hình trung tâm đề xuất thích nghi sử dụng các thành phần giao diện phong cách gym.
10. **[GymSectionHeader.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/ui/components/GymSectionHeader.kt)**: Thành phần hiển thị tiêu đề phần có hoặc không có hành động đi kèm.
11. **[GymMetric.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/ui/components/GymMetric.kt)**: Thành phần hiển thị cặp thông tin (nhãn và giá trị) đồng bộ.
12. **[GymHeroCard.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/ui/components/GymHeroCard.kt)**: Thẻ chứa thông tin nổi bật với viền xám mỏng và bo góc.
13. **[AdaptationEngineTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/test/java/com/example/myapplication/core/adaptation/AdaptationEngineTest.kt)**: Suite kiểm thử 22 trường hợp cho bộ quy tắc thích nghi.
14. **[RecommendationViewModelTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/test/java/com/example/myapplication/feature/recommendations/RecommendationViewModelTest.kt)**: Suite kiểm thử hành vi UI ViewModel, bao gồm fallback ngoại tuyến.
15. **[RoomAdaptationRepositoryTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/androidTest/java/com/example/myapplication/data/RoomAdaptationRepositoryTest.kt)**: Suite kiểm thử tích hợp giao dịch (9 kịch bản) cho `RoomAdaptationRepository`.
16. **[AdaptiveJourneyEndToEndTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/androidTest/java/com/example/myapplication/AdaptiveJourneyEndToEndTest.kt)**: Bài test tích hợp E2E chu trình khép kín của tính năng thích nghi thích ứng.
17. **[GymStyleAccessibilityTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/androidTest/java/com/example/myapplication/GymStyleAccessibilityTest.kt)**: Bài test khả năng tiếp cận và kích thước touch target.

### 📝 File được cập nhật (Modified Files)
1. **[PersonalizationDao.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/data/local/PersonalizationDao.kt)**: Bổ sung các câu truy vấn phục vụ cập nhật trạng thái quyết định, lấy thông tin quyết định cũ nhất/mới nhất theo loại để hoàn tác.
2. **[AppContainer.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/app/AppContainer.kt)**: Khởi tạo và phơi bày `adaptationRepository` và `coachExplanationClient` để các ViewModel và Screen sử dụng.
3. **[SettingsScreen.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/feature/settings/SettingsScreen.kt)** & **[SettingsRoute.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/feature/settings/SettingsRoute.kt)**: Thêm nút chuyển hướng sang màn hình Đề xuất thích nghi.
4. **[GymApp.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/app/GymApp.kt)**: Tích hợp màn hình Đề xuất thích nghi vào cây điều hướng NavHost.
5. **[server.js](file:///c:/Users/PC/Documents/Duy/Gym%20App/server/server.js)**: Bổ sung endpoint `/api/explain-decision` gọi API Gemini định dạng nhận xét thích nghi thân thiện bằng tiếng Việt.
6. **[ProfileViewModelTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/test/java/com/example/myapplication/feature/profile/ProfileViewModelTest.kt)** & **[NutritionRepositoryTest.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/test/java/com/example/myapplication/data/NutritionRepositoryTest.kt)**: Cập nhật các mock/fake DAO để tương thích chữ ký DAO mở rộng.

---

## 2. Chi tiết thiết kế quy tắc thích nghi (Task 6)

`AdaptationEngine.evaluate` chạy hoàn toàn offline và tất định với các quy tắc sau:

*   **Điều chỉnh Calorie (`CALORIE_TARGET`)**:
    *   *Điều kiện áp dụng tự động (`AUTO_APPLY`)*: Chỉ xảy ra khi độ lệch calorie đề xuất nằm trong giới hạn cho phép (tối đa 5% lượng calorie hiện tại hoặc 150 kcal), đồng thời tỷ lệ hoàn thành mục tiêu dinh dưỡng tuần (adherence) đạt từ 70% trở lên.
    *   *Yêu cầu xác nhận (`REQUIRES_CONFIRMATION`)*: Khi calorie đề xuất vượt giới hạn tự động, hoặc dữ liệu tuân thủ (adherence) dưới 70%.
    *   *Cooldown*: Chỉ tạo tối đa 1 quyết định điều chỉnh calorie mỗi 7 ngày.
*   **Đề xuất Phục hồi (`RECOVERY_DAY`)**:
    *   Tự động kích hoạt khi có từ 2 check-in tuần liên tiếp báo điểm số phục hồi thấp (≤ 2). Đề xuất này mang tính thông tin, không tự ý xóa hoặc sắp xếp lại lịch tập.
*   **Điều chỉnh Khối lượng (`WORKOUT_VOLUME`)**:
    *   Kích hoạt yêu cầu xác nhận khi người dùng bỏ lỡ liên tiếp từ 2 buổi tập trở lên. Không bao giờ hạ số buổi tập tuần xuống dưới 1.

---

## 3. Quản lý Giao dịch & Hoàn tác (Task 7)

Tất cả các hàm trong `RoomAdaptationRepository` được bao bọc trong `database.withTransaction`:

1.  **Tính toàn vẹn dữ liệu**: Cân nặng lịch sử và thông tin tập luyện đã hoàn thành hoàn toàn được giữ nguyên, chỉ chỉnh sửa mục tiêu dinh dưỡng của ngày hiện tại khi có quyết định được áp dụng/hoàn tác.
2.  **Tính toán Macro**: Khi calorie thay đổi, lượng Carbohydrate và Chất béo sẽ tự động được co giãn tỉ lệ theo **phần năng lượng phi-protein còn lại** (non-protein calories) thay vì co giãn theo tổng calorie, bảo đảm giữ nguyên lượng Protein (1.6g/kg cân nặng) và tổng năng lượng từ các macro luôn trùng khớp hoàn hảo với mục tiêu calorie mới. Trường hợp tạo mục tiêu mới từ đầu, ứng dụng tự động truy vấn hồ sơ để lấy cân nặng và tính Protein chuẩn xác thay vì dùng tỉ lệ cứng 30%.
3.  **Hoàn tác an toàn (Undo)**:
    *   Chỉ cho phép hoàn tác quyết định đã áp dụng gần nhất của loại đó.
    *   Kiểm tra nếu có quyết định mới hơn cùng loại đã được áp dụng, hệ thống sẽ chặn hoàn tác và báo lỗi lỗi thời (`Stale`) để tránh xung đột dữ liệu.

---

## 4. Thiết kế Trung tâm Đề xuất thích nghi & Giải thích AI (Task 8 & 9)

1.  **Trung tâm đề xuất (Recommendation Center)**:
    *   Truy cập qua **Cài đặt** -> mục **Cá nhân hóa** -> **ĐỀ XUẤT THÍCH NGHI**.
    *   Sử dụng giao diện Gym với nền trắng chiếm ưu thế, văn bản xanh navy đậm (`#14213D`), các nút hành động đồng ý màu cam (`#F97316`) và trạng thái hoàn thành màu xanh lá (`#22C55E`).
2.  **Tải giải thích AI động**:
    *   Nếu người dùng cấp quyền truy cập đám mây (`cloudAiConsent == true`), ứng dụng sẽ gọi backend `/api/explain-decision` tải mô tả động từ Gemini.
    *   Nếu mất mạng hoặc xảy ra lỗi phân tích, ứng dụng tự động hiển thị mô tả giải thích nội bộ tất định (`reasonVi`), đảm bảo trải nghiệm offline-first luôn mượt mà.
3.  **Các thành phần dùng chung (Shared Components)**:
    *   Trích xuất và tái cấu trúc các thành phần `GymSectionHeader`, `GymMetric` và `GymHeroCard` giúp đồng bộ giao diện trên toàn bộ các màn hình chính (Today, Progress, Settings và Recommendations).

---

## 5. Kết quả Xác minh & Kiểm thử (Verification - Task 10)

*   **JVM Unit Tests**: Đã chạy thành công 100% các unit test cũ và mới.
    ```powershell
    .\gradlew.bat testDebugUnitTest
    ```
    *Kết quả*: Thành công (BUILD SUCCESSFUL).
*   **Android Instrumented Tests**: Đã biên dịch thành công toàn bộ mã kiểm thử tích hợp (bao gồm E2E test và Accessibility test).
    ```powershell
    .\gradlew.bat assembleDebugAndroidTest
    ```
    *Kết quả*: Thành công (BUILD SUCCESSFUL).
*   **Bảng kiểm xác minh cá nhân hóa**: Đã tạo tài liệu theo dõi tại [adaptive-personalization-checklist.md](file:///c:/Users/PC/Documents/Duy/Gym%20App/docs/verification/adaptive-personalization-checklist.md) phục vụ chạy Release gates.

---

## 6. Thay đổi Tên ứng dụng & Biểu tượng (App Name & Icon Upgrade)

1.  **Tên ứng dụng mới**: Đã được thay đổi từ **Gym App** sang **SmartGym** (Trợ lý tập luyện thông minh) trong file cấu hình tài nguyên hệ thống [strings.xml](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/res/values/strings.xml).
2.  **Biểu tượng ứng dụng (App Icon)**:
    *   Đã thay thế biểu tượng mặc định bằng hình ảnh thiết kế chuyên nghiệp hình lục giác có chữ **"S"** cách điệu màu xanh lục/lam chuyển màu.
    *   Đã chép file hình ảnh này thành `ic_launcher.png` và `ic_launcher_round.png` vào toàn bộ các thư mục tài nguyên mipmap (`mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`) và dọn dẹp các tệp tin `.webp` cũ để loại bỏ xung đột trùng lặp tài nguyên.
    *   Đã xóa các adaptive icon XML mặc định trong `mipmap-anydpi-v26` để hệ thống Android tự động ưu tiên nạp biểu tượng hình ảnh chất lượng cao này.

---

## 7. Cập nhật Calo động trên Trang chủ (Dynamic Calories Integration)

1.  **Dữ liệu Calo thực tế từ Chế độ ăn**: Thay thế calo tĩnh bằng việc kết nối `HomeViewModel` với `NutritionRepository`. Lấy lượng calo hấp thụ thực tế (`caloriesConsumed`) và mục tiêu calo thích ứng ngày hôm nay (`caloriesTarget`) thông qua hàm `observeDay(currentEpochDay)`.
2.  **Dữ liệu Calo thực tế từ Tập luyện**: Tính toán năng lượng tiêu hao (`caloriesBurned`) thực tế từ các bài tập đã hoàn thành của buổi tập hôm nay (`completedCount * 60 kcal`) trên mục tiêu calo tiêu hao tổng của buổi tập (`totalCount * 60 kcal`, tối thiểu 300 kcal).
3.  **Giao diện Dual-Circle**: Nâng cấp [HomeScreen.kt](file:///c:/Users/PC/Documents/Duy/Gym%20App/app/src/main/java/com/example/myapplication/feature/home/HomeScreen.kt) để hiển thị **hai vòng tròn tiến trình neon riêng biệt** ở cột bên phải:
    *   **Vòng Đốt cháy (Workouts)**: Màu cam EnergyOrange (`#F97316`), hiển thị calo tiêu hao thực tế.
    *   **Vòng Hấp thụ (Diet)**: Màu xanh lá NeonGreen (`#22C55E`), hiển thị calo hấp thụ thực tế từ thức ăn.

4.  **Việt hóa & Đồng bộ thời gian thực cho Tóm tắt & Tiến độ**:
    *   **Tóm tắt buổi tập**: Đổi tiêu đề thành `"Tóm tắt buổi tập hôm nay"`, đổi đơn vị thời gian thành `"phút"`, và mô tả trạng thái hoàn thành thành dạng `"X/Y bài đã xong"`. Đồng bộ tức thì khi đánh dấu bài tập trong tab Workouts.
    *   **Tiến độ tuần**: Đổi tiêu đề thành `"Tiến độ tuần này"`, đổi các nhãn thứ tự từ Anh ngữ sang tiếng Việt thân thuộc (`"T2", "T3", "T4", "T5", "T6", "T7", "CN"`). Tự động cập nhật ngay khi hoàn tất trọn vẹn một buổi tập.
    *   **Chuỗi liên tục**: Việt hóa huy hiệu chuỗi ngày tập luyện thành `"Chuỗi X ngày"`.



