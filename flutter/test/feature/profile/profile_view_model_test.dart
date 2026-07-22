import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/core/model/profile_models.dart';
import 'package:gym_app/core/model/nutrition_models.dart';
import 'package:gym_app/data/local/database.dart';
import 'package:gym_app/data/providers/data_providers.dart';
import 'package:gym_app/data/repositories/workout_repository.dart';
import 'package:gym_app/data/repositories/nutrition_repository.dart';
import 'package:gym_app/data/repositories/food_photo_consent_repository.dart';
import 'package:gym_app/feature/profile/profile_ui_state.dart';
import 'package:gym_app/feature/profile/profile_screen.dart';
import 'package:gym_app/feature/profile/profile_view_model.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_notifier.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_state.dart';
import 'package:gym_app/ui/theme/theme.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockNutritionRepository extends Mock implements NutritionRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GymDatabase database;
  late MockWorkoutRepository mockWorkoutRepo;
  late MockNutritionRepository mockNutritionRepo;
  late SharedPreferences preferences;

  setUpAll(() {
    registerFallbackValue(const NutritionTarget(
      basalCalories: 0,
      maintenanceCalories: 0,
      calories: 0,
      proteinGrams: 0,
      carbsGrams: 0,
      fatGrams: 0,
      audit: NutritionTargetAudit(
        rawBasalCalories: 0,
        rawMaintenanceCalories: 0,
        rawTargetCalories: 0,
        rawProteinGrams: 0,
        rawCarbsGrams: 0,
        rawFatGrams: 0,
      ),
    ));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    database = GymDatabase(NativeDatabase.memory());
    mockWorkoutRepo = MockWorkoutRepository();
    mockNutritionRepo = MockNutritionRepository();

    when(() => mockWorkoutRepo.observeActiveGoal())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockNutritionRepo.setTarget(any(), any()))
        .thenAnswer((_) => Future.value());
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer createContainer({
    FoodPhotoConsentRepository? consentRepository,
  }) {
    final container = ProviderContainer(
      overrides: [
        gymDatabaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(preferences),
        if (consentRepository != null)
          foodPhotoConsentRepositoryProvider
              .overrideWithValue(consentRepository),
        workoutRepositoryProvider.overrideWithValue(mockWorkoutRepo),
        nutritionRepositoryProvider.overrideWithValue(mockNutritionRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('default profile is set when database profile is empty', () async {
    final container = createContainer();

    // Verify initial state is loading
    expect(
        container.read(profileNotifierProvider), isA<ProfileUiStateLoading>());

    // Wait for the initialization stream to emit
    await Future.delayed(const Duration(milliseconds: 100));

    final state = container.read(profileNotifierProvider);
    expect(state, isA<ProfileUiStateContent>());
    final content = state as ProfileUiStateContent;
    expect(content.heightCmStr, equals("170"));
    expect(content.currentWeightKgStr, equals("70"));
    expect(content.targetWeightKgStr, equals("65"));
    expect(content.metabolicSex, equals(MetabolicSex.male));
    expect(content.activityLevel, equals(ActivityLevel.moderate));
    expect(content.goalPace, equals(GoalPace.standard));
    expect(content.personalizationConsent, isFalse);
    expect(content.cloudAiConsent, isFalse);
    expect(content.foodPhotoUploadConsent, isFalse);
  });

  test('saving valid profile updates DB and registers weight measurement',
      () async {
    final container = createContainer();
    container.read(profileNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    final notifier = container.read(profileNotifierProvider.notifier);
    notifier.updateHeight("180");
    notifier.updateCurrentWeight("80");
    notifier.updateTargetWeight("75");
    notifier.updatePersonalizationConsent(true);
    notifier.updateFoodPhotoUploadConsent(true);

    notifier.saveProfile();
    await Future.delayed(const Duration(milliseconds: 100));

    final savedProfile = await database.personalizationDao.profileNow();
    expect(savedProfile, isNotNull);
    expect(savedProfile!.heightCm, equals(180.0));
    expect(savedProfile.currentWeightKg, equals(80.0));
    expect(savedProfile.targetWeightKg, equals(75.0));
    expect(savedProfile.personalizationConsent, isTrue);
    expect(
      await container.read(foodPhotoConsentRepositoryProvider).hasConsent(),
      isTrue,
    );

    // Verify weight logged
    final weights = await database.personalizationDao.weightHistoryNow();
    expect(weights.length, equals(1));
    expect(weights.first.weightKg, equals(80.0));

    // Verify nutrition target calculated and set
    verify(() => mockNutritionRepo.setTarget(any(), any())).called(1);
  });

  test('saving invalid values fails with validation errors', () async {
    final container = createContainer();
    container.read(profileNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    final notifier = container.read(profileNotifierProvider.notifier);
    notifier.updateHeight("invalid");
    notifier.updateCurrentWeight("-10");

    notifier.saveProfile();
    await Future.delayed(const Duration(milliseconds: 100));

    final state =
        container.read(profileNotifierProvider) as ProfileUiStateContent;
    expect(state.validationErrors, isNotEmpty);
  });

  test('revocation persists and blocks photos despite invalid profile fields',
      () async {
    final container = createContainer();
    await container
        .read(foodPhotoConsentRepositoryProvider)
        .setConsent(true);
    container.read(profileNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    final notifier = container.read(profileNotifierProvider.notifier);
    notifier.updateHeight('invalid');
    notifier.updateTargetWeight('-1');
    await notifier.updateFoodPhotoUploadConsent(false);
    notifier.saveProfile();
    await Future.delayed(const Duration(milliseconds: 100));

    final profileState =
        container.read(profileNotifierProvider) as ProfileUiStateContent;
    expect(profileState.validationErrors, isNotEmpty);
    expect(profileState.foodPhotoUploadConsent, isFalse);
    expect(
      await container.read(foodPhotoConsentRepositoryProvider).hasConsent(),
      isFalse,
    );

    final subscription = container.listen(
      foodPhotoNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    expect(
      await container
          .read(foodPhotoNotifierProvider.notifier)
          .requestPrimaryCapture(),
      isNull,
    );
    expect(
      container.read(foodPhotoNotifierProvider),
      isA<FoodPhotoConsentRequired>(),
    );
  });

  test('failed revocation keeps consent enabled and reports the failure',
      () async {
    final container = createContainer(
      consentRepository: _FailingConsentRepository(),
    );
    container.read(profileNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    await container
        .read(profileNotifierProvider.notifier)
        .updateFoodPhotoUploadConsent(false);

    final state =
        container.read(profileNotifierProvider) as ProfileUiStateContent;
    expect(state.foodPhotoUploadConsent, isTrue);
    expect(state.saveError, contains('thu hồi'));
  });

  testWidgets('profile presents informed dedicated food-photo consent copy',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: getGymLightTheme(),
        home: ProfileContent(
          onBack: () {},
          state: ProfileUiStateContent(
            birthDateEpochDay: 0,
            metabolicSex: MetabolicSex.male,
            heightCmStr: '170',
            currentWeightKgStr: '70',
            targetWeightKgStr: '65',
            activityLevel: ActivityLevel.moderate,
            goalPace: GoalPace.standard,
            personalizationConsent: true,
            cloudAiConsent: true,
            foodPhotoUploadConsent: false,
          ),
        ),
      ),
    ));

    expect(find.byKey(const Key('food-photo-upload-consent')), findsOneWidget);
    expect(find.textContaining('máy chủ ứng dụng'), findsOneWidget);
    expect(find.textContaining('không được bảo đảm ẩn danh'), findsOneWidget);
    expect(find.textContaining('thu hồi quyền này'), findsOneWidget);
    expect(find.textContaining('tiếp tục nhập tay'), findsOneWidget);
  });
}

final class _FailingConsentRepository
    implements FoodPhotoConsentRepository {
  @override
  Future<bool> hasConsent() async => true;

  @override
  Future<void> setConsent(bool consent) async {
    throw StateError('disk unavailable');
  }
}
