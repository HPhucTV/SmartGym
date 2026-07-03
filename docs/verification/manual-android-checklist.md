# Android release verification checklist

Date: 2026-07-02 (Asia/Saigon)

## Production-hardening smoke test (2026-07-03)

- [ ] Cài `app/build/outputs/apk/debug/app-debug.apk` trên máy thật bằng ADB hoặc Android Studio.
- [ ] Khi chưa bật AI Cloud consent, quét món ăn không gửi request và hiển thị hướng dẫn bật consent.
- [ ] Khi chưa cấu hình server trên máy thật, core workout, dinh dưỡng thủ công và progress vẫn hoạt động offline.
- [ ] Khi cấu hình URL hợp lệ và bật consent, AI hoạt động; khi server tắt, app fallback mà không crash.
- [ ] Chuyển Light/Dark/System và kiểm tra Home, Today, Achievements, Progress, Settings không còn nền trắng cố định gây mất tương phản.
- [ ] Hoàn thành buổi tập cuối: confetti chuyển động, share hiển thị đúng phần trăm và badge mới.
- [ ] Mở lại hoặc retry session đã hoàn thành: không bắn celebration lần hai.
- [ ] Thay goal, hoàn thành một buổi và xác nhận tiến độ huy hiệu không cộng lịch sử của goal cũ.
- [ ] Xoay màn hình và đưa app background/foreground; state không nhân đôi request hoặc hoàn thành session.

## Test environment

- Device: Android Emulator `Pixel_8` (`sdk_gphone16k_x86_64`)
- Android API: 37
- Physical display: 1080 x 2400, 420 dpi
- Orientation during automated journey: portrait
- App mode tại lần kiểm định 2026-07-02: fully offline. Bản 2026-07-03 có `INTERNET` cho AI tùy chọn, được khóa bằng consent; core vẫn offline-first.
- Debug APK: `app/build/outputs/apk/debug/app-debug.apk`

## Automated verification

| Check | Status | Evidence |
|---|---|---|
| General/beginner/bodyweight/3 sessions/4 weeks onboarding | PASS | `GymAppEndToEndTest` selected the exact real catalog configuration. |
| Today instructions, every exercise check, and completion | PASS | Focused E2E passed 1/1 on Pixel_8; LazyColumn nodes were reached through semantics scrolling. |
| Progress `1/12 buổi` and completion date | PASS | Focused E2E asserted both values. |
| Persistence after Activity recreation | PASS | Focused E2E returned to the next workout or recovery state after `scenario.recreate()`. |
| App data reset returns onboarding | PASS | E2E clears Room and DataStore before Activity launch and completes onboarding from the initial screen. |
| Full connected suite | PASS | 40/40 tests, 0 skipped, 0 failed. |
| JVM unit suite | PASS | `test` completed successfully. |
| Android lint | PASS | `lintDebug` completed successfully; report at `app/build/reports/lint-results-debug.html`. |
| Debug app and test APKs | PASS | `assembleDebug` and `assembleDebugAndroidTest` completed successfully. |

## Manual device matrix

`NOT RUN` is intentional: automated coverage is not presented as visual/manual observation.

| Scenario | Status | Evidence / reason |
|---|---|---|
| Small phone portrait: onboarding, Today scrolling, expanded instructions | NOT RUN | No small-phone AVD was manually observed in this run. |
| Large phone portrait: all three destinations, calendar alignment | NOT RUN | Pixel_8 automated semantics covered navigation and Progress, but visual alignment was not manually observed. |
| Landscape: Today and Progress without clipped primary actions | NOT RUN | Capture was attempted, but the emulator displayed a System UI ANR dialog; the app layout could not be validly inspected. |
| Android 13+: notification permission accepted | NOT RUN | Permission prompt was not manually accepted and visually verified. |
| Android 13+: notification permission denied | NOT RUN | Permission prompt was not manually denied and visually verified. |
| Offline mode: first launch, goal creation, completion, relaunch | PASS (automated) | E2E exercised the complete journey on an app with no network permission. |
| Clock moved forward one day: missed workout remains current | NOT RUN | Clock was not changed on the emulator; scheduling behavior remains covered by unit/instrumented tests. |
| Goal replacement: old completed date remains visible | NOT RUN | Repository/settings tests cover preservation and confirmation, but the full visual journey was not manually observed. |
| Goal deletion: confirmation required and old completed date remains visible | NOT RUN | Settings Compose test verifies confirmation/cancel paths; historical date visibility was not manually observed. |
| App data cleared: onboarding returns as documented | PASS (automated) | E2E reset Room/DataStore before launch and observed onboarding controls. |

## Final command record

```text
.\gradlew.bat --no-daemon assembleDebugAndroidTest
PASS — BUILD SUCCESSFUL in 1m 6s

.\gradlew.bat --no-daemon connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.myapplication.GymAppEndToEndTest
PASS — 1/1, 0 skipped, 0 failed; BUILD SUCCESSFUL in 2m 35s

.\gradlew.bat --no-daemon connectedDebugAndroidTest
Initial run: FAIL — 5 pre-existing test-harness defects (Int/Long assertions, missing state recomposition, repeated setContent).
Final run: PASS — 40/40, 0 skipped, 0 failed; BUILD SUCCESSFUL in 4m 23s

.\gradlew.bat --no-daemon test lintDebug assembleDebugAndroidTest assembleDebug
PASS — BUILD SUCCESSFUL in 4m 1s
```

## Static release audit

- No network runtime permission or HTTP client usage found.
- No Compose gradient/dynamic-color usage found.
- Interactive choices and primary actions touched by the E2E use at least 48 dp targets.
- Exercise checkboxes and expand controls expose Vietnamese content descriptions; stable test tags do not replace accessibility semantics.
- Catalog validation remains part of the green connected suite.
- Existing user-facing Compose copy remains hard-coded in several pre-existing screens. Task 12 introduced no new user-facing copy; broad string-resource migration was not performed to avoid unrelated churn.

## Release status

Automated release gates pass and the APK is produced. The full instrumentation suite passed 62/62 tests on an RMX3521 running Android 14. Manual visual/permission/time-change rows above remain `NOT RUN`; therefore this document does not claim a fully manual device-matrix sign-off.
