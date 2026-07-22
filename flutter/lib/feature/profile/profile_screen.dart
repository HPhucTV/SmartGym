import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/model/profile_models.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/theme.dart';
import 'profile_ui_state.dart';
import 'profile_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const ProfileScreen({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);
    final customColors = context.customColors;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.white,
      appBar: AppBar(
        title: const Text(
          "HỒ SƠ CÁ NHÂN",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: customColors.primaryText,
      ),
      body: state is ProfileUiStateLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.energyOrange),
              ),
            )
          : ProfileContent(
              state: state as ProfileUiStateContent,
              onBack: onBack,
            ),
    );
  }
}

class ProfileContent extends ConsumerStatefulWidget {
  final ProfileUiStateContent state;
  final VoidCallback onBack;

  const ProfileContent({
    super.key,
    required this.state,
    required this.onBack,
  });

  @override
  ConsumerState<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent> {
  late TextEditingController _heightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.state.heightCmStr);
    _currentWeightController = TextEditingController(text: widget.state.currentWeightKgStr);
    _targetWeightController = TextEditingController(text: widget.state.targetWeightKgStr);
  }

  @override
  void didUpdateWidget(ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.heightCmStr != oldWidget.state.heightCmStr &&
        _heightController.text != widget.state.heightCmStr) {
      _heightController.text = widget.state.heightCmStr;
    }
    if (widget.state.currentWeightKgStr != oldWidget.state.currentWeightKgStr &&
        _currentWeightController.text != widget.state.currentWeightKgStr) {
      _currentWeightController.text = widget.state.currentWeightKgStr;
    }
    if (widget.state.targetWeightKgStr != oldWidget.state.targetWeightKgStr &&
        _targetWeightController.text != widget.state.targetWeightKgStr) {
      _targetWeightController.text = widget.state.targetWeightKgStr;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final birthDate = DateTime.fromMillisecondsSinceEpoch(
      widget.state.birthDateEpochDay * 24 * 60 * 60 * 1000,
      isUtc: true,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.energyOrange,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final epochDay = DateTime(picked.year, picked.month, picked.day).millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
      ref.read(profileNotifierProvider.notifier).updateBirthDate(epochDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final birthLocalDate = DateTime.fromMillisecondsSinceEpoch(
      widget.state.birthDateEpochDay * 24 * 60 * 60 * 1000,
      isUtc: true,
    );
    final birthDateStr = DateFormat("dd/MM/yyyy").format(birthLocalDate);

    if (widget.state.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Thành công"),
            content: const Text("Hồ sơ cá nhân và mục tiêu dinh dưỡng đã được cập nhật thành công!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(profileNotifierProvider.notifier).clearSuccess();
                  widget.onBack();
                },
                child: const Text(
                  "Đồng ý",
                  style: TextStyle(color: AppColors.energyOrange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Basic Info Card
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surfaceGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.borderGray,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thông tin cơ bản",
                        style: TextStyle(
                          color: customColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Birthdate Picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ngày sinh",
                            style: TextStyle(color: customColors.mutedText, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkBg
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.fromBorderSide(BorderSide(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkBorder
                                      : AppColors.borderGray,
                                )),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    birthDateStr,
                                    style: TextStyle(color: customColors.primaryText, fontSize: 16),
                                  ),
                                  Icon(Icons.calendar_today, color: customColors.mutedText, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Metabolic Sex Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Giới tính sinh học (để tính mức tiêu hao năng lượng)",
                            style: TextStyle(color: customColors.mutedText, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => ref.read(profileNotifierProvider.notifier).updateMetabolicSex(MetabolicSex.male),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: widget.state.metabolicSex == MetabolicSex.male
                                          ? customColors.orangeLight
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? AppColors.darkBg
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.fromBorderSide(BorderSide(
                                        color: widget.state.metabolicSex == MetabolicSex.male
                                            ? AppColors.energyOrange
                                            : (Theme.of(context).brightness == Brightness.dark
                                                ? AppColors.darkBorder
                                                : AppColors.borderGray),
                                        width: widget.state.metabolicSex == MetabolicSex.male ? 2 : 1,
                                      )),
                                    ),
                                    child: Text(
                                      "Nam",
                                      style: TextStyle(
                                        color: widget.state.metabolicSex == MetabolicSex.male
                                            ? AppColors.energyOrange
                                            : customColors.primaryText,
                                        fontWeight: widget.state.metabolicSex == MetabolicSex.male
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => ref.read(profileNotifierProvider.notifier).updateMetabolicSex(MetabolicSex.female),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: widget.state.metabolicSex == MetabolicSex.female
                                          ? customColors.orangeLight
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? AppColors.darkBg
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.fromBorderSide(BorderSide(
                                        color: widget.state.metabolicSex == MetabolicSex.female
                                            ? AppColors.energyOrange
                                            : (Theme.of(context).brightness == Brightness.dark
                                                ? AppColors.darkBorder
                                                : AppColors.borderGray),
                                        width: widget.state.metabolicSex == MetabolicSex.female ? 2 : 1,
                                      )),
                                    ),
                                    child: Text(
                                      "Nữ",
                                      style: TextStyle(
                                        color: widget.state.metabolicSex == MetabolicSex.female
                                            ? AppColors.energyOrange
                                            : customColors.primaryText,
                                        fontWeight: widget.state.metabolicSex == MetabolicSex.female
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Height and Weight Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: "Chiều cao",
                                suffixText: "cm",
                                labelStyle: const TextStyle(color: AppColors.energyOrange),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.energyOrange, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkBorder
                                        : AppColors.borderGray,
                                  ),
                                ),
                              ),
                              style: TextStyle(color: customColors.primaryText),
                              onChanged: (val) => ref.read(profileNotifierProvider.notifier).updateHeight(val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _currentWeightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: "Cân nặng",
                                suffixText: "kg",
                                labelStyle: const TextStyle(color: AppColors.energyOrange),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.energyOrange, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkBorder
                                        : AppColors.borderGray,
                                  ),
                                ),
                              ),
                              style: TextStyle(color: customColors.primaryText),
                              onChanged: (val) => ref.read(profileNotifierProvider.notifier).updateCurrentWeight(val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _targetWeightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Cân nặng mục tiêu",
                          suffixText: "kg",
                          labelStyle: const TextStyle(color: AppColors.energyOrange),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.energyOrange, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkBorder
                                  : AppColors.borderGray,
                            ),
                          ),
                        ),
                        style: TextStyle(color: customColors.primaryText),
                        onChanged: (val) => ref.read(profileNotifierProvider.notifier).updateTargetWeight(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Activity Level & Goal Pace Card
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surfaceGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.borderGray,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hoạt động & Tốc độ mục tiêu",
                        style: TextStyle(
                          color: customColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Activity level
                      Text(
                        "Mức độ hoạt động hằng ngày",
                        style: TextStyle(color: customColors.mutedText, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: [
                          _buildActivityOption(
                            ActivityLevel.sedentary,
                            "Ít vận động (Nhân viên văn phòng)",
                            customColors,
                          ),
                          const SizedBox(height: 6),
                          _buildActivityOption(
                            ActivityLevel.light,
                            "Vận động nhẹ (Luyện tập 1-3 ngày/tuần)",
                            customColors,
                          ),
                          const SizedBox(height: 6),
                          _buildActivityOption(
                            ActivityLevel.moderate,
                            "Vận động vừa (Luyện tập 3-5 ngày/tuần)",
                            customColors,
                          ),
                          const SizedBox(height: 6),
                          _buildActivityOption(
                            ActivityLevel.high,
                            "Vận động nhiều (Luyện tập 6-7 ngày/tuần)",
                            customColors,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Goal pace options
                      Text(
                        "Tốc độ điều chỉnh cân nặng mong muốn",
                        style: TextStyle(color: customColors.mutedText, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      _buildPaceOptions(customColors),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Privacy & Consents Card
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surfaceGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.borderGray,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quyền riêng tư & Cam kết",
                        style: TextStyle(
                          color: customColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Consent 1: Personalization
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: widget.state.personalizationConsent,
                            activeColor: AppColors.energyOrange,
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(profileNotifierProvider.notifier).updatePersonalizationConsent(val);
                              }
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Đồng ý cá nhân hóa dinh dưỡng",
                                  style: TextStyle(
                                    color: customColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Cho phép ứng dụng sử dụng các chỉ số cơ thể để tính toán calo & macros mục tiêu ngoại tuyến.",
                                  style: TextStyle(color: customColors.mutedText, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Consent 2: Cloud AI Consent
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: widget.state.cloudAiConsent,
                            activeColor: AppColors.energyOrange,
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(profileNotifierProvider.notifier).updateCloudAiConsent(val);
                              }
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Đồng ý gửi dữ liệu ẩn danh lên AI Coach",
                                  style: TextStyle(
                                    color: customColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Cho phép gửi ẩn danh các chỉ số dinh dưỡng ngày (không bao gồm thông tin cá nhân) để nhận lời khuyên thông minh từ AI.",
                                  style: TextStyle(color: customColors.mutedText, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Consent 3: Food-photo upload and AI analysis
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            key: const Key('food-photo-upload-consent'),
                            value: widget.state.foodPhotoUploadConsent,
                            activeColor: AppColors.energyOrange,
                            onChanged: (val) async {
                              if (val != null) {
                                await ref.read(profileNotifierProvider.notifier).updateFoodPhotoUploadConsent(val);
                              }
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Đồng ý tải ảnh món ăn để phân tích bằng AI",
                                  style: TextStyle(
                                    color: customColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Ảnh được gửi tới máy chủ ứng dụng và nhà cung cấp AI đã cấu hình để nhận diện món hoặc nhãn và ước tính dinh dưỡng. Ảnh có thể chứa thông tin nhận diện nên không được bảo đảm ẩn danh. Ứng dụng xóa dữ liệu ảnh khỏi bộ nhớ máy chủ sau khi xử lý; thời gian lưu hoặc xóa tại nhà cung cấp AI phụ thuộc chính sách của họ và không thể được ứng dụng bảo đảm. Bạn có thể không đồng ý hoặc thu hồi quyền này và tiếp tục nhập tay.",
                                  style: TextStyle(color: customColors.mutedText, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Validation Errors Display
              if (widget.state.validationErrors.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Vui lòng sửa các lỗi sau:",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...widget.state.validationErrors.map(
                        (err) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            "- $err",
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 5. Save Error Display
              if (widget.state.saveError != null) ...[
                Text(
                  widget.state.saveError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],

              // 6. Save Button
              ElevatedButton(
                onPressed: widget.state.isSaving
                    ? null
                    : () => ref.read(profileNotifierProvider.notifier).saveProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.energyOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.state.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "LƯU HỒ SƠ",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityOption(ActivityLevel level, String label, GymCustomColors customColors) {
    final selected = widget.state.activityLevel == level;
    return InkWell(
      onTap: () => ref.read(profileNotifierProvider.notifier).updateActivityLevel(level),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? customColors.orangeLight
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBg
                  : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.fromBorderSide(BorderSide(
            color: selected
                ? AppColors.energyOrange
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.borderGray),
            width: selected ? 2 : 1,
          )),
        ),
        child: Row(
          children: [
            Radio<ActivityLevel>(
              value: level,
              groupValue: widget.state.activityLevel,
              activeColor: AppColors.energyOrange,
              onChanged: (val) {
                if (val != null) {
                  ref.read(profileNotifierProvider.notifier).updateActivityLevel(val);
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.energyOrange : customColors.primaryText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceOptions(GymCustomColors customColors) {
    final currentWeight = double.tryParse(widget.state.currentWeightKgStr.replaceAll(',', '.')) ?? 0.0;
    final targetWeight = double.tryParse(widget.state.targetWeightKgStr.replaceAll(',', '.')) ?? 0.0;

    final List<MapEntry<GoalPace, String>> paceOptions;
    if (targetWeight < currentWeight) {
      paceOptions = [
        const MapEntry(GoalPace.mild, "Thong thả\n(-10% Calo)"),
        const MapEntry(GoalPace.standard, "Tiêu chuẩn\n(-15% Calo)"),
        const MapEntry(GoalPace.aggressive, "Mạnh mẽ\n(-20% Calo)"),
      ];
    } else if (targetWeight > currentWeight) {
      paceOptions = [
        const MapEntry(GoalPace.mild, "Tăng cơ nạc\n(+5% Calo)"),
        const MapEntry(GoalPace.standard, "Tiêu chuẩn\n(+10% Calo)"),
        const MapEntry(GoalPace.aggressive, "Mạnh mẽ\n(+15% Calo)"),
      ];
    } else {
      paceOptions = [
        const MapEntry(GoalPace.mild, "Thong thả\n(Giữ cân)"),
        const MapEntry(GoalPace.standard, "Tiêu chuẩn\n(Giữ cân)"),
        const MapEntry(GoalPace.aggressive, "Mạnh mẽ\n(Giữ cân)"),
      ];
    }

    return Row(
      children: paceOptions.map((entry) {
        final pace = entry.key;
        final label = entry.value;
        final selected = widget.state.goalPace == pace;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => ref.read(profileNotifierProvider.notifier).updateGoalPace(pace),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? customColors.orangeLight
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBg
                          : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.fromBorderSide(BorderSide(
                    color: selected
                        ? AppColors.energyOrange
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : AppColors.borderGray),
                    width: selected ? 2 : 1,
                  )),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.energyOrange : customColors.primaryText,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
