# Đánh giá riêng tư cho phân tích ảnh món ăn

Bộ đánh giá này đo độ chính xác bằng ảnh thật nhưng không đưa ảnh, đường dẫn cục bộ, tên món, quan sát thô hoặc manifest thật vào Git hay báo cáo. Script dùng `GeminiFoodObserver`, `FoodAnalysisService`, `NutritionEstimator` và `AnalysisSessionStore` của production; chỉ phần xác nhận dùng ground truth đã cân/đọc thủ công qua đúng contract xác nhận của API.

## Điều kiện dữ liệu

- Ít nhất 30 ca `MEAL` và 20 ca `NUTRITION_LABEL`.
- Mỗi ảnh phải có quyền sử dụng có thể kiểm chứng. Mỗi case bắt buộc có `source`, `license`, `licenseReference` và `collectedAt`.
- Không ghi `UNKNOWN`, `TBD` hoặc tự gán giấy phép. Nếu quyền chưa rõ, không đưa case đó vào tập đánh giá.
- Ground truth của món ăn phải được cân hoặc đo độc lập. `majorComponentFoodIds` chỉ dùng ID có trong danh mục đã duyệt.
- Với nhãn, `confirmation` là dữ liệu đã đọc thủ công; `clearLabel` chỉ đặt `true` khi các trường bắt buộc nhìn rõ trên ảnh.
- Ảnh phụ là tùy chọn trong manifest. Harness chỉ gửi ảnh đó khi workflow production trả `NEEDS_SECOND_IMAGE`.

Copy `manifest.example.json` thành `manifest.json` trong thư mục riêng tư bên ngoài Git, thay toàn bộ giá trị minh họa và đặt ảnh dưới các đường dẫn tương đối:

```text
<FOOD_EVAL_DIR>/
  manifest.json
  images/
    ... private JPEG, PNG or WEBP files ...
```

`primaryImage` và `secondaryImage.path` phải là đường dẫn tương đối nằm trong `FOOD_EVAL_DIR`. Harness từ chối absolute path, `..`, symlink thoát khỏi thư mục, ảnh rỗng, ảnh trên 5 MB và magic bytes không hợp lệ. Manifest tối đa 1 MB và 500 case.

## Chạy đánh giá

Cấu hình `server/.env` với `GEMINI_API_KEY`; `GEMINI_MODEL` mặc định là `gemini-2.5-pro`. Việc chạy gửi ảnh tới provider, có thể phát sinh chi phí và chỉ được thực hiện sau khi bộ ảnh có consent/quyền sử dụng phù hợp với chính sách retention đang áp dụng.

```powershell
$env:FOOD_EVAL_DIR = (Resolve-Path "C:\private\smartgym-food-eval").Path
node server\evaluation\run_evaluation.js
```

Script đọc cố định `<FOOD_EVAL_DIR>/manifest.json`; không nội suy shell từ manifest. Báo cáo JSON theo ngày được ghi vào `server/evaluation/results/` (đã ignore) và stdout chỉ chứa số đếm, chỉ số tổng hợp, latency và trạng thái gate. Lỗi chỉ in mã tổng quát, không in tên món, đường dẫn ảnh, observation, prompt, API key hoặc chi tiết case.

## Chỉ số và release gate

| Chỉ số | Mục tiêu |
|---|---:|
| Nhận diện thành phần chính | `>= 90%` |
| Trung vị sai số calorie tuyệt đối sau xác nhận | `<= 20%` |
| Ước tính nằm trong sai số calorie 35% | `>= 90%` |
| Độ đầy đủ trường bắt buộc của nhãn rõ | `>= 95%` |
| Tự động lưu | `0` |

Báo cáo còn có tỷ lệ cần ảnh thứ hai, số lỗi theo mã, p50 và p95 latency. Ca phân tích lỗi vẫn làm giảm chỉ số nhận diện/completeness tương ứng và được tính là không nằm trong ngưỡng sai số 35%; chúng không bị loại để làm đẹp số liệu. Gate `automatic saves = 0` nằm ở Flutter notifier/integration tests vì Node service không sở hữu persistence.

Exit code khác 0 nếu thiếu số lượng tối thiểu, metadata provenance/license không hợp lệ hoặc bất kỳ mục tiêu accuracy nào thất bại. Tính năng phải tiếp tục hiển thị **“Thử nghiệm”** cho đến khi có báo cáo theo ngày đạt tất cả gate và test Flutter về không tự động lưu cũng đạt.

Không commit thư mục riêng tư, `manifest.json` thật hay báo cáo. Trước commit, kiểm tra:

```powershell
git status --short
git check-ignore server/evaluation/private/example.jpg server/evaluation/results/example.json
```
