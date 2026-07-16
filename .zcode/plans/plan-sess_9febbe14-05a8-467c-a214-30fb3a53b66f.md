# Plan: Tách NutritionScreen.kt (2104 dòng) và TodayScreen.kt (975 dòng)

## Theo chuẩn đã phân tích
- **Package**: giữ nguyên (`feature.nutrition`, `feature.today`)
- **Visibility**: composables chính `public` (không `internal`), helpers `private`
- **Naming**: suffix "Section" cho section, "Card" cho card, "Dialog" cho dialog
- **Parameters**: inline, không data class wrapper
- **UiState**: import từ file `*UiState.kt` trong cùng package

---

## NutritionScreen.kt → 6 file mới

Mỗi file giữ nguyên code logic, chỉ di chuyển + đổi `private fun` → `fun` cho composables public.

| # | File mới | Nội dung | Dòng gốc |
|---|---------|---------|---------|
| 1 | `NutritionSummaryCards.kt` | `CalorieCard`, `WaterCard`, `MacroRow`, `SweatPaymentStatusCard`, `ScanningCard` | 1180-1460 (~280 dòng) |
| 2 | `NutritionLoggedMealsSection.kt` | Toàn bộ khối "Bữa ăn hôm nay" — summary totals, copy-yesterday button, grouped meal list (BREAKFAST/LUNCH/DINNER/SNACK) | ~270 dòng inline trong NutritionScreen (220-432) |
| 3 | `FoodCatalogSection.kt` | Toàn bộ khối "Tra cứu & Nhập thực phẩm" — import guide, tab row, search field, food item cards với expand/grams/meal picker, add-to-cart/add-direct buttons | ~360 dòng inline (508-862) |
| 4 | `NutritionCartSection.kt` | Toàn bộ khối "Giỏ món ăn" (cart display + confirm) | ~70 dòng inline (434-504) |
| 5 | `NutritionDraftDialog.kt` | `NutritionDraftDialog`, `DraftField`, `MealTemplateCard` | 1080-1178 (~100 dòng) |
| 6 | `BarcodeScannerView.kt` | `BarcodeScannerView` + helper `loadResizedBitmapFromFile`, `getFileName`, `defaultMealTime` | 1835-2104 (~270 dòng) |

**NutritionScreen.kt còn lại**: ~600 dòng — top-level Scaffold, LaunchedEffects, launchers, scan result dialog, template delete/rename dialogs, history section, gọi các extracted sections. Đã giảm đáng kể và còn **1 trách nhiệm rõ ràng**: orchestration.

---

## TodayScreen.kt → 4 file mới

| # | File mới | Nội dung | Dòng gốc |
|---|---------|---------|---------|
| 1 | `WorkoutDialogs.kt` | `ExerciseSubstitutionDialog`, `WorkoutFeedbackDialog`, `AchievementUnlockDialog`, `shareWorkoutSummary` helper | 175-370 + 959 (~240 dòng) |
| 2 | `WorkoutContent.kt` | `WorkoutContent` (LazyColumn với header, time-budget, sore muscles, exercise list, completion button) + `TodayHeaderCard` | 371-696 (~325 dòng) |
| 3 | `RecoveryScreen.kt` | `RecoveryScreen`, `formatEpochDay`, `todayDateFormatter` | 737-809 (~75 dòng) |
| 4 | `TodayStateScreens.kt` | `GoalCompleteScreen`, `ErrorScreen`, `AICoachTipCard` | 813-975 (~165 dòng) |

**TodayScreen.kt còn lại**: ~175 dòng — top-level `TodayScreen` routing (Loading/GoalComplete/Recovery/Error/Workout), celebration layer. Đúng vai trò coordinator.

---

## Execution Order
1. Tạo file mới NutritionScreen extracted files (6 files)
2. Sửa NutritionScreen.kt — gọi extracted composables, xóa code đã di chuyển
3. Tạo file mới TodayScreen extracted files (4 files)  
4. Sửa TodayScreen.kt — gọi extracted composables, xóa code đã di chuyển
5. Build & run unit tests để verify không regression
6. Nếu build pass → hoàn tất

**Không thay đổi logic, không thay đổi signature, không refactoring** — chỉ di chuyển code sang file mới và điều chỉnh visibility.
