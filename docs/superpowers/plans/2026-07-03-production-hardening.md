# Gym App Production Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sửa các lỗi đã xác nhận trong 10 tính năng mới và làm bản Android an toàn hơn để kiểm thử trên máy thật mà không viết lại ứng dụng.

**Architecture:** Giữ single-module và manual dependency wiring. Tạo các seam nhỏ cho luật Achievement, AI Coach và nội dung chia sẻ; ViewModel chỉ điều phối state, còn Room và HTTP nằm sau adapter hiện có.

**Tech Stack:** Kotlin, Jetpack Compose Material 3, Coroutines/Flow, Room, DataStore, OkHttp, JUnit 4, Android Lint.

---

### Task 1: Làm luật Achievement xác định và đúng

**Files:**
- Create: `app/src/test/java/com/example/myapplication/core/achievement/AchievementRulesTest.kt`
- Create: `app/src/main/java/com/example/myapplication/core/achievement/AchievementRules.kt`
- Modify: `app/src/main/java/com/example/myapplication/core/achievement/AchievementChecker.kt`
- Modify: `app/src/main/java/com/example/myapplication/data/local/AchievementDao.kt`

- [ ] Viết test thất bại cho ngưỡng nửa chương trình dùng phép làm tròn lên, streak và thời điểm early/night dựa trên tham số.
- [ ] Chạy `\.\gradlew.bat testDebugUnitTest --tests "*AchievementRulesTest" --rerun-tasks` và xác nhận RED vì `AchievementRules` chưa tồn tại.
- [ ] Thêm `AchievementSnapshot` và `AchievementRules.evaluate(snapshot)` thuần; dùng `(totalSessions + 1) / 2` cho 50%.
- [ ] Đổi `AchievementDao.insert` trả về `Long`; `AchievementChecker` chỉ trả badge khi insert không trả `-1`.
- [ ] Chạy lại test đích và toàn bộ unit test.

### Task 2: Tách AI Coach khỏi TodayViewModel và khóa bằng consent

**Files:**
- Create: `app/src/test/java/com/example/myapplication/feature/today/TodayCoachCoordinatorTest.kt`
- Create: `app/src/main/java/com/example/myapplication/data/CoachReviewClient.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/today/TodayViewModel.kt`
- Modify: `app/src/main/java/com/example/myapplication/app/AppContainer.kt`
- Modify: `app/src/main/java/com/example/myapplication/app/GymApp.kt`

- [ ] Viết test thất bại: không gọi client khi consent false; loading phải xuất hiện; lỗi client trả về local fallback.
- [ ] Chạy test đích và xác nhận RED do interface/coordinator chưa tồn tại.
- [ ] Tạo `CoachReviewRequest`, `CoachReviewClient` và adapter OkHttp; inject vào ViewModel.
- [ ] Đưa `cloudAiConsent` và loading flow vào `combine`, xóa OkHttp/JSONObject khỏi ViewModel.
- [ ] Nối consent từ `PersonalizationDao.observeProfile()` trong composition root.
- [ ] Chạy test Today/Recommendation/Nutrition và toàn bộ unit test.

### Task 3: Ổn định celebration và nội dung chia sẻ

**Files:**
- Create: `app/src/test/java/com/example/myapplication/feature/today/WorkoutShareTextTest.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/today/WorkoutShareText.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/today/TodayScreen.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/today/TodayViewModel.kt`
- Modify: `app/src/main/java/com/example/myapplication/core/ui/ConfettiCelebration.kt`

- [ ] Viết test thất bại cho nội dung share 100%, tiêu đề và badge; thêm test không celebration cho `AlreadyCompleted`.
- [ ] Xác nhận RED bằng test đích.
- [ ] Tách formatter thuần và giữ Intent launcher tại UI adapter.
- [ ] Chỉ phát celebration cho `CompleteWorkoutResult.Completed`.
- [ ] Làm frame time thành Compose state để Canvas invalidate; bỏ delay kép trong animation loop.
- [ ] Chạy test Today và test formatter.

### Task 4: Hardening cấu hình thiết bị thật

**Files:**
- Create: `app/src/debug/AndroidManifest.xml`
- Create: `app/proguard-rules.pro`
- Modify: `app/src/main/AndroidManifest.xml`
- Modify: `app/build.gradle.kts`
- Modify: `app/src/main/java/com/example/myapplication/app/BackendConfig.kt`
- Modify: `walkthrough.md`

- [ ] Thêm unit test cho chuẩn hóa URL và từ chối URL không phải HTTP(S).
- [ ] Chuyển cleartext sang debug manifest; main manifest mặc định không cho cleartext.
- [ ] Bỏ debug signing khỏi release và bật minify/resource shrinking với rules cho Room/serialization khi cần.
- [ ] Xóa developer IP hardcode khỏi fallback máy thật; chỉ emulator mặc định `10.0.2.2`, máy thật cần URL người dùng cấu hình.
- [ ] Sửa `walkthrough.md` để đường dẫn và tuyên bố verification khớp bằng chứng thực tế.
- [ ] Chạy unit test URL, Lint và cả hai assemble variants.

### Task 5: Verification và rà diff

**Files:**
- Modify: `docs/verification/manual-android-checklist.md`

- [ ] Chạy `\.\gradlew.bat test --rerun-tasks` và đọc số lỗi thực tế.
- [ ] Chạy `\.\gradlew.bat lintDebug` và xử lý lỗi severity cao trong phần code thay đổi.
- [ ] Chạy `\.\gradlew.bat assembleDebug assembleRelease`.
- [ ] Nếu có thiết bị/emulator, chạy `\.\gradlew.bat connectedAndroidTest`; nếu không có, ghi rõ chưa chạy thay vì suy đoán.
- [ ] Rà `git diff --check`, `git diff --stat` và xác nhận không chạm file ngoài phạm vi.
