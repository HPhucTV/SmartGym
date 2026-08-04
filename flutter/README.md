# SmartGym Flutter app

Ứng dụng Android offline-first của SmartGym. UI dùng Flutter/Material 3,
Riverpod quản lý state, Drift lưu dữ liệu quan hệ và SharedPreferences lưu các
tùy chọn nhỏ. Dữ liệu bài tập và chương trình nằm trong `assets/catalog/`.

## Chạy và kiểm thử

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

Sau khi thay đổi model Freezed/JSON Serializable, chạy:

```powershell
flutter pub run build_runner build
```

## Minh họa 3D

Renderer stick figure nằm tại `assets/3d/`. Mỗi `ExerciseDefinition` dùng
`animationId` rõ ràng; UI không hiển thị nút 3D nếu ID vắng mặt. Contract giữa
catalog và renderer được kiểm tra trong bộ test Node ở `../server/test/`.

Xem tài liệu tổng quan và ADR tại [`../README.md`](../README.md) và
[`../docs/decisions/ADR-001-explicit-exercise-animation-contract.md`](../docs/decisions/ADR-001-explicit-exercise-animation-contract.md).

## Android release

Release build không dùng debug signing. Sao chép `android/key.properties.example`
thành `android/key.properties`, trỏ `storeFile` tới keystore nằm ngoài repository
và điền secret cục bộ. Nếu thiếu một trường, release task sẽ dừng ngay thay vì
tạo APK ký bằng debug key.

```powershell
flutter build apk --release
```

Ứng dụng tắt Android backup và loại trừ database, preferences, file nội bộ lẫn
device transfer. CI chỉ tạo debug APK; release artifact cần được xác minh chữ ký
và certificate bằng quy trình riêng có secret.
