import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/food_photo_analysis_models.dart';
import 'package:gym_app/core/model/nutrition_models.dart';
import 'package:gym_app/data/providers/data_providers.dart';
import 'package:gym_app/data/providers/remote_providers.dart';
import 'package:gym_app/data/remote/food_analysis_client.dart';
import 'package:gym_app/data/repositories/nutrition_repository.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_notifier.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_state.dart';

void main() {
  group('FoodPhotoNotifier', () {
    late _FakeFoodAnalysisClient client;
    late _FakeNutritionRepository repository;
    late bool consent;
    late Completer<bool>? consentGate;
    late DateTime now;
    late _NotifierHarness harness;

    setUp(() {
      client = _FakeFoodAnalysisClient();
      repository = _FakeNutritionRepository();
      consent = true;
      consentGate = null;
      now = DateTime(2026, 7, 22, 12, 30);
      harness = _NotifierHarness(
        client: client,
        repository: repository,
        consent: () => consentGate?.future ?? Future.value(consent),
        now: () => now,
        epochDay: () => 20656,
      );
    });

    tearDown(() {
      harness.dispose();
    });

    test('primary capture moves through uploading to needs-second-photo',
        () async {
      final response = Completer<FoodAnalysisReview>();
      client.onStart = (_) => response.future;

      final primaryToken = harness.notifier.beginPrimaryCapture();
      expect(harness.state, isA<FoodPhotoCapturing>());
      expect((harness.state as FoodPhotoCapturing).isSecondary, isFalse);

      final submit =
          harness.notifier.submitPrimary(_upload(1), token: primaryToken);
      expect(harness.state, isA<FoodPhotoUploading>());
      response.complete(_mealReview(status: 'NEEDS_SECOND_IMAGE'));
      await submit;

      expect(harness.state, isA<FoodPhotoNeedsSecondPhoto>());
      expect(client.startUploads.single.bytes, [1, 2, 3]);
      await harness.notifier.retry();
      expect(client.startUploads, hasLength(1),
          reason: 'a successful first request must release primary bytes');
    });

    test('recognized primary images enter the matching review variant',
        () async {
      client.onStart = (_) async => _mealReview();
      await harness.startPrimary(_upload(1));
      expect(harness.state, isA<FoodPhotoReviewingMeal>());

      final secondPrimaryToken = harness.notifier.beginPrimaryCapture();
      client.onStart = (_) async => _labelReview();
      await harness.notifier
          .submitPrimary(_upload(2), token: secondPrimaryToken);
      expect(harness.state, isA<FoodPhotoReviewingLabel>());
    });

    test('secondary upload uses the private active session and enters review',
        () async {
      client.onStart = (_) async =>
          _mealReview(status: 'NEEDS_SECOND_IMAGE', analysisId: 'meal-session');
      await harness.startPrimary(_upload(1));

      final secondaryToken = harness.notifier.beginSecondaryCapture()!;
      expect((harness.state as FoodPhotoCapturing).isSecondary, isTrue);
      client.onSecondary =
          (_, __) async => _mealReview(analysisId: 'meal-session');
      await harness.notifier.submitSecondary(_upload(2), token: secondaryToken);

      expect(harness.state, isA<FoodPhotoReviewingMeal>());
      expect(client.secondaryAnalysisIds, ['meal-session']);
    });

    test('no persisted consent makes zero analysis calls', () async {
      consent = false;

      await harness.startPrimary(_upload(1));

      expect(harness.state, isA<FoodPhotoConsentRequired>());
      expect(client.photoCallCount, 0);
    });

    test('retry after timeout reuses only the latest secondary upload',
        () async {
      client.onStart = (_) async =>
          _mealReview(status: 'NEEDS_SECOND_IMAGE', analysisId: 'session');
      await harness.startPrimary(_upload(1));

      var secondaryAttempt = 0;
      client.onSecondary = (_, __) async {
        secondaryAttempt++;
        if (secondaryAttempt == 1) {
          throw FoodAnalysisApiException(
            code: 'ANALYSIS_UNAVAILABLE',
            message: 'timeout',
          );
        }
        return _mealReview(analysisId: 'session');
      };
      final secondaryToken = harness.notifier.beginSecondaryCapture()!;
      await harness.notifier.submitSecondary(_upload(9), token: secondaryToken);

      final error = harness.state as FoodPhotoError;
      expect(error.canRetry, isTrue);
      await harness.notifier.retry();

      expect(harness.state, isA<FoodPhotoReviewingMeal>());
      expect(client.secondaryUploads, hasLength(2));
      expect(client.secondaryUploads[0].bytes, [9, 10, 11]);
      expect(client.secondaryUploads[1].bytes, [9, 10, 11]);
      expect(client.startUploads, hasLength(1));
    });

    test('meal edits replace immutable drafts', () async {
      client.onStart = (_) async => _mealReview();
      await harness.startPrimary(_upload(1));
      final original = (harness.state as FoodPhotoReviewingMeal).draft;

      harness.notifier.renameMealComponent('component-1', 'Cơm gạo lứt');
      final renamed = (harness.state as FoodPhotoReviewingMeal).draft;
      expect(original.components.single.nameVi, 'Cơm trắng');
      expect(renamed.components.single.nameVi, 'Cơm gạo lứt');
      expect(renamed.components, isNot(same(original.components)));

      harness.notifier.updateMealComponentPortion(
        'component-1',
        HouseholdPortion(
          unit: HouseholdPortionUnit.bowl,
          quantity: 1.5,
          size: HouseholdPortionSize.large,
        ),
      );
      final portioned = (harness.state as FoodPhotoReviewingMeal).draft;
      expect(
        (portioned.components.single.portion as HouseholdPortion).quantity,
        1.5,
      );

      harness.notifier.addMealComponent(
        nameVi: 'Rau luộc',
        foodId: 'boiled-vegetables',
        portion: HouseholdPortion(
          unit: HouseholdPortionUnit.serving,
          quantity: 1,
          size: HouseholdPortionSize.medium,
        ),
      );
      final added = (harness.state as FoodPhotoReviewingMeal).draft;
      expect(added.components, hasLength(2));
      final addedId = added.components.last.observationId;

      harness.notifier.removeMealComponent(addedId);
      final removed = (harness.state as FoodPhotoReviewingMeal).draft;
      expect(removed.components, hasLength(1));
      expect(added.components, hasLength(2));
    });

    test('manual component id skips an existing provider id', () async {
      client.onStart = (_) async => _mealReview(componentId: 'manual-1');
      await harness.startPrimary(_upload(1));

      harness.notifier.addMealComponent(nameVi: 'Rau luộc');

      final components =
          (harness.state as FoodPhotoReviewingMeal).draft.components;
      expect(
        components.map((component) => component.observationId),
        ['manual-1', 'manual-2'],
      );
      expect(
        components.map((component) => component.observationId).toSet(),
        hasLength(2),
      );
    });

    test('label basis, facts, serving size, and consumed edits are immutable',
        () async {
      client.onStart = (_) async => _labelReview(incomplete: true);
      await harness.startPrimary(_upload(1));
      final original = (harness.state as FoodPhotoReviewingLabel).draft;

      harness.notifier.updateLabelBasis(LabelBasis.perServing);
      harness.notifier.updateLabelFacts(
        calories: 250,
        proteinGrams: 8,
        carbsGrams: 30,
        fatGrams: 10,
      );
      harness.notifier.updateLabelServingSize(50);
      harness.notifier.updateLabelConsumed(
        kind: LabelConsumedKind.servings,
        amount: 1.5,
      );

      final edited = (harness.state as FoodPhotoReviewingLabel).draft;
      expect(original.basis, LabelBasis.unknown);
      expect(original.calories, isNull);
      expect(original.consumed, isNull);
      expect(edited.basis, LabelBasis.perServing);
      expect(edited.calories, 250);
      expect(edited.servingSizeGrams, 50);
      expect(edited.consumed!.amount, 1.5);
    });

    test('manual-required meal component blocks confirmation until completed',
        () async {
      client.onStart = (_) async => _mealReview(manualPortion: true);
      client.onConfirm = (_, confirmation) async => _ready();
      await harness.startPrimary(_upload(1));

      await harness.notifier.confirm();
      expect(harness.state, isA<FoodPhotoReviewingMeal>());
      expect(client.confirmations, isEmpty);

      harness.notifier.updateMealComponentPortion(
        'component-1',
        GramPortion(grams: 180),
      );
      await harness.notifier.confirm();

      expect(harness.state, isA<FoodPhotoReady>());
      expect(client.confirmations, hasLength(1));
    });

    test('deleting a false-positive manual component allows confirmation',
        () async {
      client.onStart =
          (_) async => _mealReview(manualPortion: true, duplicateFoodId: true);
      client.onConfirm = (_, __) async => _ready();
      await harness.startPrimary(_upload(1));

      harness.notifier.removeMealComponent('component-1');
      await harness.notifier.confirm();

      expect(harness.state, isA<FoodPhotoReady>());
      final confirmation = client.confirmations.single as MealConfirmation;
      expect(confirmation.components, hasLength(1));
      expect(confirmation.components.single.observationId, 'component-2');
    });

    test('confirmation sends the edited strict payload', () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => _ready();
      await harness.startPrimary(_upload(1));
      harness.notifier.updateMealName('Bữa trưa mới');
      harness.notifier.renameMealComponent('component-1', 'Cơm mới');
      harness.notifier.updateMealComponentPortion(
        'component-1',
        GramPortion(grams: 220),
      );

      await harness.notifier.confirm();

      final confirmation = client.confirmations.single as MealConfirmation;
      expect(confirmation.nameVi, 'Bữa trưa mới');
      expect(confirmation.components.single.nameVi, 'Cơm mới');
      expect(
        (confirmation.components.single.portion as GramPortion).grams,
        220,
      );
    });

    test('persisted consent is checked again before confirmation', () async {
      client.onStart = (_) async => _mealReview();
      await harness.startPrimary(_upload(1));
      consent = false;

      await harness.notifier.confirm();

      expect(harness.state, isA<FoodPhotoConsentRequired>());
      expect(client.confirmations, isEmpty);
    });

    test('nothing persists before save and double save writes exactly once',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => _ready();
      await harness.startPrimary(_upload(1));
      await harness.notifier.confirm();
      expect(repository.logs, isEmpty);

      repository.saveCompleter = Completer<void>();
      final first = harness.notifier.save();
      final second = harness.notifier.save();
      expect(harness.state, isA<FoodPhotoSaving>());
      expect(repository.logs, hasLength(1));
      repository.saveCompleter!.complete();
      await Future.wait([first, second]);

      expect(harness.state, isA<FoodPhotoSaved>());
      expect(repository.logs, hasLength(1));
      final saved = repository.logs.single;
      expect(saved.epochDay, 20656);
      expect(saved.log.mealTime, 'LUNCH');
      expect(saved.log.estimate.calories.mid, 505);
      expect(saved.log.estimate.calories.min, 430);
      expect(saved.log.estimate.calories.max, 580);
    });

    test('cancel cancels pending client work and ignores its late response',
        () async {
      final response = Completer<FoodAnalysisReview>();
      client.onStart = (_) => response.future;
      final primaryToken = harness.notifier.beginPrimaryCapture();
      final submit =
          harness.notifier.submitPrimary(_upload(1), token: primaryToken);

      harness.notifier.cancel();
      expect(harness.state, isA<FoodPhotoCancelled>());
      expect(client.cancelCount, 1);
      response.complete(_mealReview());
      await submit;

      expect(harness.state, isA<FoodPhotoCancelled>());
      await harness.notifier.retry();
      expect(client.startUploads, isEmpty,
          reason: 'cancel must release retry bytes');
    });

    test('expired analysis requires recapture and is never confirmed',
        () async {
      client.onStart = (_) async => _mealReview(
            expiresAt: now.subtract(const Duration(seconds: 1)),
          );
      await harness.startPrimary(_upload(1));

      final error = harness.state as FoodPhotoError;
      expect(error.code, 'ANALYSIS_EXPIRED');
      expect(error.requiresRecapture, isTrue);
      await harness.notifier.confirm();
      expect(client.confirmations, isEmpty);
    });

    test('malformed upload response retains bytes for retry and manual entry',
        () async {
      var attempts = 0;
      client.onStart = (_) async {
        attempts++;
        if (attempts == 1) {
          throw const FoodAnalysisFormatException('malformed provider output');
        }
        return _mealReview();
      };
      await harness.startPrimary(_upload(1));

      final error = harness.state as FoodPhotoError;
      expect(error.code, 'INVALID_PROVIDER_RESPONSE');
      expect(error.canRetry, isTrue);
      expect(error.canUseManualEntry, isTrue);
      expect(error.requiresRecapture, isFalse);

      await harness.notifier.retry();
      expect(harness.state, isA<FoodPhotoReviewingMeal>());
      expect(client.startUploads, hasLength(2));
      expect(client.startUploads[1].bytes, client.startUploads[0].bytes);
    });

    test('upload provider API error offers retry and manual entry', () async {
      client.onStart = (_) async => throw FoodAnalysisApiException(
            code: 'INVALID_PROVIDER_RESPONSE',
            message: 'invalid provider response',
          );
      await harness.startPrimary(_upload(1));
      expect((harness.state as FoodPhotoError).canRetry, isTrue);

      harness.notifier.useManualEntry();

      expect(harness.state, isA<FoodPhotoManualEntryRequested>());
      expect(client.cancelCount, 1);
    });

    test('double submit and double confirm make one client call each',
        () async {
      final review = Completer<FoodAnalysisReview>();
      client.onStart = (_) => review.future;
      final primaryToken = harness.notifier.beginPrimaryCapture();
      final firstSubmit =
          harness.notifier.submitPrimary(_upload(1), token: primaryToken);
      final secondSubmit =
          harness.notifier.submitPrimary(_upload(2), token: primaryToken);
      review.complete(_mealReview());
      await Future.wait([firstSubmit, secondSubmit]);
      expect(client.startUploads, hasLength(1));

      final ready = Completer<FoodAnalysisReady>();
      client.onConfirm = (_, __) => ready.future;
      final firstConfirm = harness.notifier.confirm();
      final secondConfirm = harness.notifier.confirm();
      ready.complete(_ready());
      await Future.wait([firstConfirm, secondConfirm]);
      expect(client.confirmations, hasLength(1));
    });

    test('mismatched confirmation session cannot become ready', () async {
      client.onStart = (_) async => _mealReview(analysisId: 'expected');
      client.onConfirm = (_, __) async => _ready(analysisId: 'stale');
      await harness.startPrimary(_upload(1));

      await harness.notifier.confirm();

      final error = harness.state as FoodPhotoError;
      expect(error.code, 'INVALID_PROVIDER_RESPONSE');
      expect(error.canRetryConfirm, isFalse);
      expect(error.requiresRecapture, isTrue);
      expect(error.canUseManualEntry, isTrue);
      expect(error.mealDraft, isNull);
      await harness.notifier.retryConfirm();
      expect(client.confirmations, hasLength(1));
      expect(repository.logs, isEmpty);
    });

    test('malformed confirmation response requires recapture, not reconfirm',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async =>
          throw const FoodAnalysisFormatException('malformed ready response');
      await harness.startPrimary(_upload(1));

      await harness.notifier.confirm();

      final error = harness.state as FoodPhotoError;
      expect(error.code, 'INVALID_PROVIDER_RESPONSE');
      expect(error.canRetryConfirm, isFalse);
      expect(error.requiresRecapture, isTrue);
      expect(error.canUseManualEntry, isTrue);
      expect(error.reviewSummary, isNull);
      await harness.notifier.retryConfirm();
      expect(client.confirmations, hasLength(1));
    });

    test('dispose cancels work and late completion has no side effects',
        () async {
      final response = Completer<FoodAnalysisReview>();
      client.onStart = (_) => response.future;
      final primaryToken = harness.notifier.beginPrimaryCapture();
      final submit =
          harness.notifier.submitPrimary(_upload(1), token: primaryToken);

      harness.dispose();
      response.complete(_mealReview());
      await submit;

      expect(client.cancelCount, 1);
      expect(repository.logs, isEmpty);
    });

    test('stale primary capture token cannot submit after reset or new capture',
        () async {
      final staleToken = harness.notifier.beginPrimaryCapture();
      harness.notifier.reset();
      client.onStart = (_) async => _mealReview();

      await harness.notifier.submitPrimary(
        _upload(1),
        token: staleToken,
      );

      expect(client.startUploads, isEmpty);
      expect(harness.state, isA<FoodPhotoIdle>());

      final replacedToken = harness.notifier.beginPrimaryCapture();
      final currentToken = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(2), token: replacedToken);
      expect(client.startUploads, isEmpty);
      expect(harness.state, isA<FoodPhotoCapturing>());

      await harness.notifier.submitPrimary(_upload(3), token: currentToken);
      expect(client.startUploads, hasLength(1));
      expect(harness.state, isA<FoodPhotoReviewingMeal>());
    });

    test(
        'secondary response must match session and cannot loop for another photo',
        () async {
      client.onStart = (_) async => _mealReview(
            status: 'NEEDS_SECOND_IMAGE',
            analysisId: 'expected-session',
          );
      final primaryToken = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: primaryToken);
      final secondaryToken = harness.notifier.beginSecondaryCapture()!;

      client.onSecondary = (_, __) async => _mealReview(
            status: 'NEEDS_CONFIRMATION',
            analysisId: 'different-session',
          );
      await harness.notifier.submitSecondary(
        _upload(2),
        token: secondaryToken,
      );
      final mismatch = harness.state as FoodPhotoError;
      expect(mismatch.code, 'INVALID_PROVIDER_RESPONSE');
      expect(mismatch.canRetry, isTrue);
      expect(mismatch.canUseManualEntry, isTrue);
      client.onSecondary =
          (_, __) async => _mealReview(analysisId: 'expected-session');
      await harness.notifier.retry();
      expect(harness.state, isA<FoodPhotoReviewingMeal>());
      expect(client.secondaryUploads, hasLength(2));
      expect(
          client.secondaryUploads[1].bytes, client.secondaryUploads[0].bytes);

      // A second-photo response is terminal for this capture; it cannot loop.
      client.onStart = (_) async => _mealReview(
            status: 'NEEDS_SECOND_IMAGE',
            analysisId: 'expected-session',
          );
      final nextToken = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(3), token: nextToken);
      final anotherSecondaryToken = harness.notifier.beginSecondaryCapture()!;
      client.onSecondary = (_, __) async => _mealReview(
            status: 'NEEDS_SECOND_IMAGE',
            analysisId: 'expected-session',
          );
      await harness.notifier.submitSecondary(
        _upload(4),
        token: anotherSecondaryToken,
      );
      expect(
          (harness.state as FoodPhotoError).code, 'INVALID_PROVIDER_RESPONSE');
    });

    test('transient confirmation failure retains editable review and retries',
        () async {
      client.onStart = (_) async => _mealReview();
      var confirmations = 0;
      client.onConfirm = (_, __) async {
        confirmations++;
        if (confirmations == 1) {
          throw FoodAnalysisApiException(
            code: 'ANALYSIS_UNAVAILABLE',
            message: 'timeout',
          );
        }
        return _ready();
      };
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);

      await harness.notifier.confirm();
      final failed = harness.state as FoodPhotoError;
      expect(failed.canRetryConfirm, isTrue);
      expect(failed.canUseManualEntry, isTrue);
      expect(failed.mealDraft, isNotNull);
      harness.notifier.renameMealComponent('component-1', 'Đã sửa');
      await harness.notifier.retryConfirm();

      expect(harness.state, isA<FoodPhotoReady>());
      expect(
          (client.confirmations.last as MealConfirmation)
              .components
              .single
              .nameVi,
          'Đã sửa');
    });

    test(
        'database no-match confirmation retains review and accepts food selection',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => throw FoodAnalysisApiException(
            code: 'DATABASE_NO_MATCH',
            message: 'choose a known food',
            details: const {'foodId': 'white-rice'},
          );
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);
      await harness.notifier.confirm();

      final failed = harness.state as FoodPhotoError;
      expect(failed.canRetryConfirm, isTrue);
      expect(failed.canUseManualEntry, isTrue);
      expect(failed.affectedComponentId, 'component-1');
      final knownFood = KnownFoodOption.listFromJson({
        'foods': [
          {
            'foodId': 'known-food',
            'nameVi': 'Món đã chọn',
            'supportsGrams': true,
            'portionOptions': []
          }
        ]
      }).single;
      harness.notifier.selectKnownFood('component-1', knownFood);
      final selected =
          (harness.state as FoodPhotoReviewingMeal).draft.components.single;
      expect(selected.foodId, 'known-food');
      expect(selected.nameVi, 'Món đã chọn');
      expect(selected.portion, isNull,
          reason: 'an incompatible portion must not survive food selection');
      expect(selected.manualPortionCompleted, isFalse);
    });

    test('known food selection retains a compatible current portion', () async {
      client.onStart = (_) async => _mealReview();
      await harness.startPrimary(_upload(1));
      final knownFood = KnownFoodOption.listFromJson({
        'foods': [
          {
            'foodId': 'compatible-rice',
            'nameVi': 'Cơm tương thích',
            'supportsGrams': false,
            'portionOptions': [
              {
                'unit': 'BOWL',
                'sizes': ['MEDIUM']
              }
            ]
          }
        ]
      }).single;

      harness.notifier.selectKnownFood('component-1', knownFood);

      final selected =
          (harness.state as FoodPhotoReviewingMeal).draft.components.single;
      expect(selected.portion, isA<HouseholdPortion>());
      expect(selected.manualPortionCompleted, isTrue);
    });

    for (final code in ['UNSUPPORTED_PORTION', 'UNSUPPORTED_FOOD_DATA']) {
      test('$code keeps the confirmation draft correctable', () async {
        client.onStart = (_) async => _mealReview();
        client.onConfirm = (_, __) async => throw FoodAnalysisApiException(
              code: code,
              message: 'correct the portion',
              details: const {'observationId': 'component-1'},
            );
        await harness.startPrimary(_upload(1));
        await harness.notifier.confirm();

        final reviewing = harness.state as FoodPhotoReviewingMeal;
        expect(reviewing.draft.components.single.observationId, 'component-1');
        expect(reviewing.validationMessage, 'correct the portion');
        expect(reviewing.fieldErrorPath?.componentId, 'component-1');
      });
    }

    test('null-id database mismatch uses observation context for chooser',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => throw FoodAnalysisApiException(
            code: 'DATABASE_NO_MATCH',
            message: 'choose a known food',
            details: const {
              'foodId': 'unknown',
              'observationId': 'component-1',
            },
          );
      await harness.startPrimary(_upload(1));
      await harness.notifier.confirm();

      expect(
          (harness.state as FoodPhotoError).affectedComponentId, 'component-1');
    });

    test('database no-match component is null when foodId is ambiguous',
        () async {
      client.onStart = (_) async => _mealReview(duplicateFoodId: true);
      client.onConfirm = (_, __) async => throw FoodAnalysisApiException(
            code: 'DATABASE_NO_MATCH',
            message: 'choose a known food',
            details: const {'foodId': 'white-rice'},
          );
      await harness.startPrimary(_upload(1));

      await harness.notifier.confirm();

      final failed = harness.state as FoodPhotoError;
      expect(failed.affectedComponentId, isNull);
      expect(failed.mealDraft!.components, hasLength(2));
    });

    test('save failure retains ready result and retrySave writes once',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => _ready();
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);
      await harness.notifier.confirm();
      repository.failSave = true;

      await harness.notifier.save();
      expect(harness.state, isA<FoodPhotoSaveFailed>());
      expect((harness.state as FoodPhotoSaveFailed).result.nameVi,
          'Cơm với ức gà');

      repository.failSave = false;
      await harness.notifier.retrySave();
      expect(harness.state, isA<FoodPhotoSaved>());
      expect(repository.saveCalls, 2);
      expect(repository.logs, hasLength(1));
    });

    test('editFromReady requires recapture and never advertises reconfirmation',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => _ready();
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);
      await harness.notifier.confirm();

      harness.notifier.renameMealComponent('component-1', 'ignored');
      expect(harness.state, isA<FoodPhotoReady>());
      harness.notifier.editFromReady();
      final error = harness.state as FoodPhotoError;
      expect(error.requiresRecapture, isTrue);
      expect(error.canUseManualEntry, isTrue);
      expect(error.canRetryConfirm, isFalse);
      expect(error.reviewSummary, isNull);
      expect(error.mealDraft, isNull);
      expect(repository.logs, isEmpty);
      await harness.notifier.retryConfirm();
      expect(client.confirmations, hasLength(1));
      harness.notifier.renameMealComponent('component-1', 'ignored again');
      expect(harness.state, same(error));
    });

    test('clearing a label consumed amount removes stale value', () async {
      client.onStart = (_) async => _labelReview();
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);
      harness.notifier.updateLabelConsumed(
        kind: null,
        amount: null,
      );

      final state = harness.state as FoodPhotoReviewingLabel;
      expect(state.draft.consumed, isNull);
      expect(state.draft.canConfirm, isFalse);
    });

    test('label field edits preserve or explicitly clear nullable values',
        () async {
      client.onStart = (_) async => _labelReview();
      await harness.startPrimary(_upload(1));
      final originalConsumed =
          (harness.state as FoodPhotoReviewingLabel).draft.consumed;

      harness.notifier.updateLabelName('Updated product');
      harness.notifier.updateLabelBasis(LabelBasis.perServing);
      var draft = (harness.state as FoodPhotoReviewingLabel).draft;
      expect(draft.consumed, same(originalConsumed));

      harness.notifier.updateLabelServingSize(45);
      harness.notifier.updateLabelServingSize(null);
      draft = (harness.state as FoodPhotoReviewingLabel).draft;
      expect(draft.servingSizeGrams, isNull);

      harness.notifier.updateLabelConsumed(
        kind: LabelConsumedKind.grams,
        amount: -1,
      );
      final invalid = harness.state as FoodPhotoReviewingLabel;
      expect(invalid.draft.consumed, isNull);
      expect(invalid.draft.canConfirm, isFalse);
      expect(invalid.validationMessage, isNotNull);
    });

    test('label package metadata is editable but excluded from confirmation',
        () async {
      client.onStart = (_) async => _labelReview();
      await harness.startPrimary(_upload(1));

      var draft = (harness.state as FoodPhotoReviewingLabel).draft;
      expect(draft.netWeightGrams, 57);
      expect(draft.consumed!.amount, 57);
      harness.notifier.updateLabelServingsPerContainer(2.5);
      harness.notifier.updateLabelNetWeight(142.5);
      draft = (harness.state as FoodPhotoReviewingLabel).draft;
      expect(draft.servingsPerContainer, 2.5);
      expect(draft.netWeightGrams, 142.5);
      expect(draft.consumed!.amount, 57,
          reason: 'editing package metadata must not overwrite consumption');
      final json = draft.toConfirmation().toJson();
      expect(json, isNot(contains('servingsPerContainer')));
      expect(json, isNot(contains('netWeightGrams')));
    });

    test('invalid confirmation exposes only a sanitized typed field path',
        () async {
      client.onStart = (_) async => _labelReview();
      client.onConfirm = (_, __) async => throw FoodAnalysisApiException(
            code: 'INVALID_CONFIRMATION',
            message: 'invalid calories',
            details: const {'field': 'facts.calories'},
          );
      await harness.startPrimary(_upload(1));
      await harness.notifier.confirm();

      final state = harness.state as FoodPhotoReviewingLabel;
      expect(state.fieldErrorPath?.kind, FoodPhotoFieldKind.calories);
      expect(
          FoodPhotoFieldErrorPath.fromApiDetails(
              const {'field': '../../../secret'}),
          isNull);
    });

    test('observation-aware component field path has no numeric ambiguity', () {
      final path = FoodPhotoFieldErrorPath.fromApiDetails(
        const {'observationId': 'other', 'field': 'portion.unit'},
        componentObservationIds: const ['1', 'other'],
      );

      expect(path?.kind, FoodPhotoFieldKind.componentPortion);
      expect(path?.componentId, 'other');
      expect(
        FoodPhotoFieldErrorPath.fromApiDetails(
          const {'field': 'components.1.portion'},
          componentObservationIds: const ['1', 'other'],
        ),
        isNull,
      );
      expect(
        FoodPhotoFieldErrorPath.fromApiDetails(
          const {'observationId': '1', 'field': 'portion'},
          componentObservationIds: const ['1', 'other'],
        )?.componentId,
        '1',
      );
    });

    test('renaming a meal component clears its old food selection', () async {
      client.onStart = (_) async => _mealReview();
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);

      harness.notifier.renameMealComponent('component-1', 'Món khác');
      expect(
          (harness.state as FoodPhotoReviewingMeal)
              .draft
              .components
              .single
              .foodId,
          isNull);
    });

    test('cancel during saving is explicitly disallowed and preserves outcome',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => _ready();
      final token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);
      await harness.notifier.confirm();
      repository.saveCompleter = Completer<void>();
      final save = harness.notifier.save();
      harness.notifier.cancel();
      expect(harness.state, isA<FoodPhotoSaving>());
      repository.saveCompleter!.complete();
      await save;
      expect(harness.state, isA<FoodPhotoSaved>());
    });

    test('dispose during save ignores the late repository completion',
        () async {
      client.onStart = (_) async => _mealReview();
      client.onConfirm = (_, __) async => _ready();
      await harness.startPrimary(_upload(1));
      await harness.notifier.confirm();
      repository.saveCompleter = Completer<void>();

      final save = harness.notifier.save();
      expect(harness.state, isA<FoodPhotoSaving>());
      harness.dispose();
      repository.saveCompleter!.complete();
      await save;

      expect(client.cancelCount, 1);
      expect(repository.saveCalls, 1);
    });

    test('reset starts a new workflow and permits its own save', () async {
      client.onStart = (_) async => _mealReview(analysisId: 'same-id');
      client.onConfirm = (_, __) async => _ready(analysisId: 'same-id');
      var token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(1), token: token);
      await harness.notifier.confirm();
      await harness.notifier.save();

      harness.notifier.reset();
      token = harness.notifier.beginPrimaryCapture();
      await harness.notifier.submitPrimary(_upload(2), token: token);
      await harness.notifier.confirm();
      await harness.notifier.save();
      expect(repository.logs, hasLength(2));
    });

    test('controlled consent must resolve before any client call', () async {
      consentGate = Completer<bool>();
      final token = harness.notifier.beginPrimaryCapture();
      final submit = harness.notifier.submitPrimary(_upload(1), token: token);
      await Future<void>.delayed(Duration.zero);
      expect(client.photoCallCount, 0);
      consentGate!.complete(false);
      await submit;
      expect(client.photoCallCount, 0);

      consentGate = Completer<bool>();
      final secondToken = harness.notifier.beginPrimaryCapture();
      final secondSubmit =
          harness.notifier.submitPrimary(_upload(2), token: secondToken);
      consentGate!.complete(true);
      client.onStart = (_) async => _mealReview();
      await secondSubmit;
      expect(client.startUploads, hasLength(1));
    });

    test('secondary upload and retry each recheck controlled consent',
        () async {
      client.onStart = (_) async => _mealReview(
            status: 'NEEDS_SECOND_IMAGE',
            analysisId: 'session',
          );
      await harness.startPrimary(_upload(1));

      consentGate = Completer<bool>();
      final secondaryToken = harness.notifier.beginSecondaryCapture()!;
      client.onSecondary = (_, __) async => throw FoodAnalysisApiException(
            code: 'ANALYSIS_UNAVAILABLE',
            message: 'timeout',
          );
      final secondary = harness.notifier.submitSecondary(
        _upload(2),
        token: secondaryToken,
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.secondaryUploads, isEmpty);
      consentGate!.complete(true);
      await secondary;
      expect(client.secondaryUploads, hasLength(1));

      consentGate = Completer<bool>();
      client.onSecondary = (_, __) async => _mealReview(analysisId: 'session');
      final retry = harness.notifier.retry();
      await Future<void>.delayed(Duration.zero);
      expect(client.secondaryUploads, hasLength(1));
      consentGate!.complete(false);
      await retry;
      expect(client.secondaryUploads, hasLength(1));
      expect(harness.state, isA<FoodPhotoConsentRequired>());
    });
  });
}

final class _NotifierHarness {
  final ProviderContainer container;
  late final ProviderSubscription<FoodPhotoState> _subscription;
  bool _disposed = false;

  _NotifierHarness({
    required FoodAnalysisClient client,
    required NutritionRepository repository,
    required Future<bool> Function() consent,
    required DateTime Function() now,
    required int Function() epochDay,
  }) : container = ProviderContainer(
          overrides: [
            foodAnalysisClientProvider.overrideWithValue(client),
            nutritionRepositoryProvider.overrideWithValue(repository),
            foodPhotoConsentLookupProvider.overrideWithValue(consent),
            foodPhotoClockProvider.overrideWithValue(now),
            foodPhotoEpochDayProvider.overrideWithValue(epochDay),
          ],
        ) {
    _subscription = container.listen(
      foodPhotoNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
  }

  FoodPhotoNotifier get notifier =>
      container.read(foodPhotoNotifierProvider.notifier);

  FoodPhotoState get state => container.read(foodPhotoNotifierProvider);

  Future<void> startPrimary(PreparedUpload upload) async {
    final token = notifier.beginPrimaryCapture();
    await notifier.submitPrimary(upload, token: token);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription.close();
    container.dispose();
  }
}

final class _FakeFoodAnalysisClient implements FoodAnalysisClient {
  Future<FoodAnalysisReview> Function(PreparedUpload)? onStart;
  Future<FoodAnalysisReview> Function(String, PreparedUpload)? onSecondary;
  Future<FoodAnalysisReady> Function(String, FoodAnalysisConfirmation)?
      onConfirm;

  final List<PreparedUpload> startUploads = [];
  final List<PreparedUpload> secondaryUploads = [];
  final List<String> secondaryAnalysisIds = [];
  final List<FoodAnalysisConfirmation> confirmations = [];
  int cancelCount = 0;

  int get photoCallCount =>
      startUploads.length + secondaryUploads.length + confirmations.length;

  @override
  Future<List<KnownFoodOption>> listKnownFoods() async => const [];

  @override
  Future<FoodAnalysisReview> startPhotoAnalysis(PreparedUpload upload) {
    startUploads.add(upload);
    return onStart!(upload);
  }

  @override
  Future<FoodAnalysisReview> addSecondaryPhoto(
    String analysisId,
    PreparedUpload upload,
  ) {
    secondaryAnalysisIds.add(analysisId);
    secondaryUploads.add(upload);
    return onSecondary!(analysisId, upload);
  }

  @override
  Future<FoodAnalysisReady> confirmAnalysis(
    String analysisId,
    FoodAnalysisConfirmation confirmation,
  ) {
    confirmations.add(confirmation);
    return onConfirm!(analysisId, confirmation);
  }

  @override
  void cancelPending() {
    cancelCount++;
  }

  @override
  Future<ScanResult?> analyze(Uint8List imageBytes) =>
      throw UnsupportedError('legacy API is outside this fake');

  @override
  Future<bool> registerBarcode(String barcode, ScanResult result) =>
      throw UnsupportedError('legacy API is outside this fake');

  @override
  Future<ScanResult?> scanBarcode(String barcode) =>
      throw UnsupportedError('legacy API is outside this fake');
}

final class _SavedPhotoLog {
  final int epochDay;
  final PhotoNutritionLog log;

  const _SavedPhotoLog(this.epochDay, this.log);
}

final class _FakeNutritionRepository implements NutritionRepository {
  final List<_SavedPhotoLog> logs = [];
  Completer<void>? saveCompleter;
  bool failSave = false;
  int saveCalls = 0;

  @override
  Future<void> logPhotoEstimate({
    required int epochDay,
    required PhotoNutritionLog log,
  }) async {
    saveCalls++;
    if (failSave) {
      throw StateError('save failed');
    }
    logs.add(_SavedPhotoLog(epochDay, log));
    await saveCompleter?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused fake repository member');
}

PreparedUpload _upload(int seed) => PreparedUpload(
      bytes: Uint8List.fromList([seed, seed + 1, seed + 2]),
      mimeType: 'image/jpeg',
      filename: 'food-$seed.jpg',
    );

FoodAnalysisReview _mealReview({
  String status = 'NEEDS_CONFIRMATION',
  String analysisId = 'analysis-1',
  String componentId = 'component-1',
  bool manualPortion = false,
  bool duplicateFoodId = false,
  DateTime? expiresAt,
}) {
  return FoodAnalysisReview.fromJson({
    'analysisId': analysisId,
    'imageType': 'MEAL',
    'status': status,
    'components': [
      {
        'id': componentId,
        'nameVi': 'Cơm trắng',
        'matchedFoodId': 'white-rice',
        'confidence': manualPortion ? 0.4 : 0.91,
        'isMajor': true,
        'requiresManualPortion': manualPortion,
        'suggestedPortion': manualPortion
            ? null
            : {
                'kind': 'HOUSEHOLD',
                'unit': 'BOWL',
                'quantity': 1,
                'size': 'MEDIUM',
              },
      },
      if (duplicateFoodId)
        {
          'id': 'component-2',
          'nameVi': 'Cơm trắng thêm',
          'matchedFoodId': 'white-rice',
          'confidence': 0.9,
          'isMajor': false,
          'requiresManualPortion': false,
          'suggestedPortion': {
            'kind': 'HOUSEHOLD',
            'unit': 'BOWL',
            'quantity': 0.5,
            'size': 'SMALL',
          },
        },
    ],
    'labelFacts': null,
    'confidence': 0.82,
    'uncertaintyReasons': ['HIDDEN_OIL'],
    'expiresAt':
        (expiresAt ?? DateTime(2026, 7, 22, 13, 0)).toUtc().toIso8601String(),
  });
}

FoodAnalysisReview _labelReview({
  String analysisId = 'analysis-label',
  bool incomplete = false,
}) {
  return FoodAnalysisReview.fromJson({
    'analysisId': analysisId,
    'imageType': 'NUTRITION_LABEL',
    'status': 'NEEDS_CONFIRMATION',
    'components': null,
    'labelFacts': {
      'nameVi': 'Sản phẩm mẫu',
      'basis': incomplete ? 'UNKNOWN' : 'PER_100G',
      'facts': {
        'calories': incomplete ? null : 498,
        'proteinGrams': incomplete ? null : 4.4,
        'carbsGrams': incomplete ? null : 49.8,
        'fatGrams': incomplete ? null : 31.1,
      },
      'servingSizeGrams': null,
      'servingsPerContainer': null,
      'netWeightGrams': incomplete ? null : 57,
      'confidence': 0.94,
      'missingFields': incomplete
          ? [
              'BASIS',
              'CALORIES',
              'PROTEIN_GRAMS',
              'CARBS_GRAMS',
              'FAT_GRAMS',
              'CONSUMED_AMOUNT',
            ]
          : [],
    },
    'confidence': 0.94,
    'uncertaintyReasons': [],
    'expiresAt': DateTime(2026, 7, 22, 13).toUtc().toIso8601String(),
  });
}

FoodAnalysisReady _ready({String analysisId = 'analysis-1'}) {
  return FoodAnalysisReady.fromJson({
    'analysisId': analysisId,
    'imageType': 'MEAL',
    'status': 'READY',
    'nameVi': 'Cơm với ức gà',
    'estimate': {
      'calories': {'min': 430, 'mid': 505, 'max': 580},
      'proteinGrams': {'min': 34, 'mid': 39, 'max': 44},
      'carbsGrams': {'min': 48, 'mid': 55, 'max': 62},
      'fatGrams': {'min': 8, 'mid': 12, 'max': 16},
    },
    'confidenceLevel': 'MEDIUM',
    'uncertaintyReasons': ['HIDDEN_OIL'],
    'calculationSummary': '1 bát cơm vừa + 1 phần ức gà vừa.',
  });
}
