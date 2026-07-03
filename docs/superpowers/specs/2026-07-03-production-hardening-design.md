# Production hardening design

## Mục tiêu

Ổn định 10 tính năng trong `walkthrough.md` trước khi chạy trên thiết bị thật, giữ nguyên dữ liệu Room và luồng sử dụng hiện tại. Core workout, lịch tập, dinh dưỡng thủ công và tiến độ phải tiếp tục hoạt động hoàn toàn offline.

## Phạm vi kiến trúc

- Giữ một Android module và cách khởi tạo dependency thủ công trong `AppContainer`.
- Đưa HTTP/JSON ra khỏi `TodayViewModel` sau một interface nhỏ để ViewModel chỉ điều phối immutable UI state.
- Mọi lời gọi cloud phải kiểm tra `cloudAiConsent`; khi không có consent hoặc lỗi mạng, dùng lời khuyên local.
- Tách luật mở khóa huy hiệu thành logic thuần, nhận thời gian qua tham số và chỉ báo mở khóa khi Room thực sự chèn bản ghi mới.
- Giữ schema Room phiên bản 4; không tạo migration nếu không cần thay đổi dữ liệu.
- Chỉ tách các phần UI đang được sửa và có trách nhiệm độc lập; không viết lại navigation hay toàn bộ màn hình.

## Luồng dữ liệu

`Compose -> ViewModel -> interface -> adapter` áp dụng cho AI Coach. Luồng workout vẫn là `Compose -> TodayViewModel -> WorkoutRepository -> Room`. Celebration chỉ phát sau kết quả `Completed`, không phát lại cho `AlreadyCompleted`.

Achievement được đánh giá từ snapshot lịch sử hoàn thành và cấu hình chương trình. Logic thời gian dùng ngày/giờ được truyền vào để có thể kiểm thử ổn định.

## An toàn triển khai

- Không hardcode địa chỉ backend vào hành vi production; URL tùy chỉnh được chuẩn hóa và kiểm tra trước khi dùng.
- Không bật cleartext traffic cho toàn ứng dụng ở release. Debug có thể dùng HTTP LAN để thử với backend trên máy phát triển.
- Release không ký bằng debug key. Việc tạo và lưu production keystore nằm ngoài repo.
- Không ghi secret, API key hoặc `local.properties` vào Git.

## Kiểm thử

- Unit tests cho luật Achievement, AI consent/fallback/loading và các formatter chia sẻ.
- Giữ toàn bộ test hiện có; chạy lại bằng `--rerun-tasks`.
- Chạy Android Lint, `assembleDebug`, `assembleRelease` và migration tests nếu có emulator/device.
- Kiểm thử thủ công trên máy thật theo checklist trong `docs/verification/manual-android-checklist.md`.

## Ngoài phạm vi

- Không thêm tài khoản, cloud sync, DI framework, module mới hoặc thuật toán sinh workout.
- Không tự tạo production signing key hoặc triển khai backend công khai.
