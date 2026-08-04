# Tài liệu Thiết kế: Tính năng Quét mã vạch trực tuyến (Online Barcode Scanner)

> **Superseded 2026-08-04.** Thiết kế ghi server/public write đã được thay bằng API tra cứu chỉ-đọc và override Drift cục bộ. Xem [`../../decisions/ADR-002-local-barcode-overrides-and-read-only-api.md`](../../decisions/ADR-002-local-barcode-overrides-and-read-only-api.md).

Tài liệu này đặc tả thiết kế hệ thống quét mã vạch sản phẩm đóng gói để tự động nhận diện và tính toán dinh dưỡng (Calories, Protein, Carbs, Fat) chuẩn xác, thay thế cho chức năng chụp ảnh đĩa ăn cũ.

---

## 1. Tổng quan & Mục tiêu
* **Vấn đề**: Việc phân tích dinh dưỡng qua hình ảnh đĩa ăn/món ăn có sai lệch lớn (20%-50%) và không chính xác đối với nhãn mác bao bì sản phẩm do có nhiều yếu tố gây nhiễu thị giác.
* **Giải pháp**: Tích hợp công cụ quét mã vạch (Barcode Scanner) chạy offline trên điện thoại kết hợp API Backend thông minh (tra cứu cơ sở dữ liệu mở Open Food Facts và cào dữ liệu qua Gemini API) để nhận diện chính xác 100% dinh dưỡng đồ đóng hộp/gói.
* **Mục tiêu**:
  * Quét mã vạch siêu nhanh bằng camera trên Android.
  * Tự động nhận diện sản phẩm Việt Nam và thế giới.
  * Tự học và cập nhật dữ liệu tự động cho các lần quét sau.

---

## 2. Kiến trúc & Luồng Dữ liệu (Data Flow)

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant App as Ứng dụng Android (Client)
    participant Server as SmartGym Backend
    participant OFF as Open Food Facts API
    participant Gemini as Gemini AI API

    User->>App: Mở tính năng quét mã vạch & Quét
    Note over App: Sử dụng Google ML Kit Barcode
    App->>Server: Gửi mã số Barcode (GET /api/scan-barcode?barcode=...)
    
    rect rgb(240, 248, 255)
        Note over Server: 1. Kiểm tra cache cục bộ (vietnam_products.json)
    end
    
    alt Khớp dữ liệu cache
        Server-->>App: Trả về kết quả dinh dưỡng chuẩn xác
    else Chưa có trong cache
        Server->>OFF: Gọi API tra cứu (GET /api/v0/product/{barcode}.json)
        alt OFF tìm thấy sản phẩm
            OFF-->>Server: Trả về thông tin sản phẩm & dinh dưỡng
            Server->>Server: Lưu vào vietnam_products.json (Cập nhật cache)
            Server-->>App: Trả về kết quả dinh dưỡng
        else OFF không tìm thấy
            Server->>Gemini: Yêu cầu Gemini Google Search mã vạch
            alt Gemini tìm thấy thông số
                Gemini-->>Server: Trả về dữ liệu đã bóc tách
                Server->>Server: Lưu vào vietnam_products.json
                Server-->>App: Trả về kết quả dinh dưỡng
            else Thất bại hoàn toàn
                Server-->>App: Trả về trạng thái "Chưa xác định"
                App->>User: Yêu cầu nhập thông số / chụp nhãn chữ OCR
                User->>App: Lưu thông số tự nhập
                App->>Server: Đồng bộ thông số mới (POST /api/register-barcode)
                Server->>Server: Cập nhật vietnam_products.json
            end
        end
    end
    App->>User: Điền tự động thông số dinh dưỡng vào màn hình nhập liệu
```

---

## 3. Chi tiết triển khai

### A. Phía Backend (Node.js Express)
* **Tệp sửa đổi**: `server/server.js`
* **API mới 1**: `GET /api/scan-barcode`
  * **Tham số**: `barcode` (string)
  * **Chức năng**:
    1. Kiểm tra mã vạch trong `vietnam_products.json`.
    2. Nếu không có, gọi `https://world.openfoodfacts.org/api/v0/product/{barcode}.json`.
    3. Nếu không tìm thấy, dùng Gemini API để tra cứu thông tin sản phẩm trên web.
    4. Trả về định dạng `ScanResult` tương thích với Client.
* **API mới 2**: `POST /api/register-barcode`
  * **Tham số**: `barcode` (string), `dishName` (string), `totalCalories` (number), `proteinGrams` (number), `carbsGrams` (number), `fatGrams` (number), `advice` (string).
  * **Chức năng**: Cập nhật thông số do người dùng nhập tay vào tệp `vietnam_products.json` để phục vụ các lượt quét tương lai.

### B. Phía Android (Kotlin/Jetpack Compose)
* **Thư viện tích hợp**: 
  * `com.google.mlkit:barcode-scanning:17.3.0`
  * `androidx.camera:camera-lifecycle` và `androidx.camera:camera-view`
* **Màn hình giao diện**: Thay đổi nút `"📸 Chụp đĩa ăn"` thành nút `"📸 Quét mã vạch"`.
  * Khi nhấn vào nút, mở hộp thoại/màn hình Camera quét trực tiếp. 
  * Khi quét thành công mã vạch, tự động đóng Camera và gọi API Backend `/api/scan-barcode`.
  * Hiển thị kết quả dưới dạng Thẻ kết quả nháp giống như tính năng phân tích cũ để người dùng xác nhận hoặc sửa trước khi lưu.

---

## 4. Kế hoạch xác minh (Verification Plan)
* **Kiểm thử cục bộ**:
  * Sử dụng Postman/Curl để gọi thử `/api/scan-barcode` với mã vạch thật (như `8936036020403` - Choco Pie) để kiểm tra kết quả trả về từ Open Food Facts.
  * Đảm bảo tệp `vietnam_products.json` được cập nhật chính xác sau khi quét mã vạch mới.
* **Kiểm thử thiết bị (Android)**:
  * Chạy ứng dụng trên Emulator hoặc máy thật.
  * Sử dụng hình ảnh mã vạch trên màn hình để camera của app quét và tự động điền dinh dưỡng.
