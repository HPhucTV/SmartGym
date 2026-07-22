import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/profile_models.dart';
import '../../core/model/nutrition_models.dart';
import '../../core/nutrition/nutrition_target_calculator.dart';
import '../../core/profile/profile_goal_validator.dart';
import '../../data/providers/data_providers.dart';
import '../../data/local/database.dart';
import 'profile_ui_state.dart';

class ProfileNotifier extends Notifier<ProfileUiState> {
  @override
  ProfileUiState build() {
    _init();
    return ProfileUiStateLoading();
  }

  void _init() async {
    final foodPhotoUploadConsent = await ref.read(foodPhotoConsentRepositoryProvider).hasConsent();
    final dbProfile = await ref.read(gymDatabaseProvider).personalizationDao.observeProfile().first;
    if (dbProfile != null) {
      state = ProfileUiStateContent(
        birthDateEpochDay: dbProfile.birthDateEpochDay,
        metabolicSex: dbProfile.metabolicSex,
        heightCmStr: dbProfile.heightCm.toString(),
        currentWeightKgStr: dbProfile.currentWeightKg.toString(),
        targetWeightKgStr: dbProfile.targetWeightKg.toString(),
        activityLevel: dbProfile.activityLevel,
        goalPace: dbProfile.goalPace,
        personalizationConsent: dbProfile.personalizationConsent,
        cloudAiConsent: dbProfile.cloudAiConsent,
        foodPhotoUploadConsent: foodPhotoUploadConsent,
      );
    } else {
      // Default reasonable values
      final defaultBirthDate = DateTime.now().subtract(const Duration(days: 365 * 25)).millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
      state = ProfileUiStateContent(
        birthDateEpochDay: defaultBirthDate,
        metabolicSex: MetabolicSex.male,
        heightCmStr: "170",
        currentWeightKgStr: "70",
        targetWeightKgStr: "65",
        activityLevel: ActivityLevel.moderate,
        goalPace: GoalPace.standard,
        personalizationConsent: false,
        cloudAiConsent: false,
        foodPhotoUploadConsent: foodPhotoUploadConsent,
      );
    }
  }

  void updateBirthDate(int dateEpochDay) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(birthDateEpochDay: dateEpochDay);
    }
  }

  void updateMetabolicSex(MetabolicSex sex) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(metabolicSex: sex);
    }
  }

  void updateHeight(String height) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(heightCmStr: height);
    }
  }

  void updateCurrentWeight(String weight) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(currentWeightKgStr: weight);
    }
  }

  void updateTargetWeight(String weight) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(targetWeightKgStr: weight);
    }
  }

  void updateActivityLevel(ActivityLevel level) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(activityLevel: level);
    }
  }

  void updateGoalPace(GoalPace pace) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(goalPace: pace);
    }
  }

  void updatePersonalizationConsent(bool consent) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(personalizationConsent: consent);
    }
  }

  void updateCloudAiConsent(bool consent) {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(cloudAiConsent: consent);
    }
  }

  Future<void> updateFoodPhotoUploadConsent(bool consent) async {
    final s = state;
    if (s is! ProfileUiStateContent) return;
    state = s.copyWith(foodPhotoUploadConsent: consent, saveError: null);
    if (consent) return;

    try {
      await ref.read(foodPhotoConsentRepositoryProvider).setConsent(false);
    } catch (_) {
      final current = state;
      if (current is ProfileUiStateContent &&
          !current.foodPhotoUploadConsent) {
        state = current.copyWith(
          foodPhotoUploadConsent: true,
          saveError: 'Không thể thu hồi quyền tải ảnh. Vui lòng thử lại.',
        );
      }
    }
  }

  void clearSuccess() {
    final s = state;
    if (s is ProfileUiStateContent) {
      state = s.copyWith(success: false);
    }
  }

  void saveProfile() async {
    final s = state;
    if (s is! ProfileUiStateContent) return;

    final today = DateTime.now();
    final height = double.tryParse(s.heightCmStr.replaceAll(',', '.'));
    final currentWeight = double.tryParse(s.currentWeightKgStr.replaceAll(',', '.'));
    final targetWeight = double.tryParse(s.targetWeightKgStr.replaceAll(',', '.'));

    final localErrors = <String>[];
    if (height == null || height <= 0) {
      localErrors.add("Chiều cao không hợp lệ.");
    }
    if (currentWeight == null || currentWeight <= 0) {
      localErrors.add("Cân nặng hiện tại không hợp lệ.");
    }
    if (targetWeight == null || targetWeight <= 0) {
      localErrors.add("Cân nặng mục tiêu không hợp lệ.");
    }

    if (localErrors.isNotEmpty) {
      state = s.copyWith(validationErrors: localErrors);
      return;
    }

    final profile = PersonalProfile(
      birthDateEpochDay: s.birthDateEpochDay,
      metabolicSex: s.metabolicSex,
      heightCm: height!,
      currentWeightKg: currentWeight!,
      targetWeightKg: targetWeight!,
      activityLevel: s.activityLevel,
      goalPace: s.goalPace,
      personalizationConsent: s.personalizationConsent,
      cloudAiConsent: s.cloudAiConsent,
    );

    final profileIssues = profile.validationIssues(today);
    localErrors.addAll(profileIssues);

    final activeGoal = await ref.read(workoutRepositoryProvider).observeActiveGoal().first;
    if (activeGoal != null) {
      final goalIssues = ProfileGoalValidator.validate(
        profile: profile,
        fitnessGoal: activeGoal.config.goal,
      );
      localErrors.addAll(goalIssues);
    }

    if (localErrors.isNotEmpty) {
      state = s.copyWith(validationErrors: localErrors);
      return;
    }

    state = s.copyWith(isSaving: true, validationErrors: const [], saveError: null);

    try {
      await ref.read(foodPhotoConsentRepositoryProvider).setConsent(s.foodPhotoUploadConsent);
      final dao = ref.read(gymDatabaseProvider).personalizationDao;
      final epochDayVal = currentLocalEpochDay();
      
      final entity = PersonalProfileData(
        id: 1,
        birthDateEpochDay: profile.birthDateEpochDay,
        metabolicSex: profile.metabolicSex,
        heightCm: profile.heightCm,
        currentWeightKg: profile.currentWeightKg,
        targetWeightKg: profile.targetWeightKg,
        activityLevel: profile.activityLevel,
        goalPace: profile.goalPace,
        personalizationConsent: profile.personalizationConsent,
        cloudAiConsent: profile.cloudAiConsent,
        updatedAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
      );
      await dao.upsertProfile(entity);

      await dao.upsertWeight(
        WeightMeasurement(
          epochDay: epochDayVal,
          weightKg: profile.currentWeightKg,
          recordedAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      if (profile.personalizationConsent) {
        final birthDate = DateTime.fromMillisecondsSinceEpoch(
          profile.birthDateEpochDay * 24 * 60 * 60 * 1000,
          isUtc: true,
        );
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }

        final calculator = NutritionTargetCalculator();
        final calcResult = calculator.calculate(
          profile: profile,
          ageYears: age,
        );

        await calcResult.maybeMap(
          target: (targetVal) async {
            await ref.read(nutritionRepositoryProvider).setTarget(
              epochDayVal,
              targetVal.value,
            );
          },
          orElse: () async {},
        );
      }

      state = (state as ProfileUiStateContent).copyWith(success: true, isSaving: false);
    } catch (e) {
      state = (state as ProfileUiStateContent).copyWith(
        saveError: "Lỗi khi lưu hồ sơ: ${e.toString()}",
        isSaving: false,
      );
    }
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileUiState>(ProfileNotifier.new);
