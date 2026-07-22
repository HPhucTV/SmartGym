import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/model/food_photo_analysis_models.dart';
import '../../../data/providers/data_providers.dart';
import '../../../data/providers/remote_providers.dart';
import '../../../data/remote/food_analysis_client.dart';
import '../../../data/repositories/nutrition_repository.dart';
import 'food_photo_state.dart';

typedef FoodPhotoConsentLookup = Future<bool> Function();
typedef FoodPhotoClock = DateTime Function();
typedef FoodPhotoEpochDay = int Function();

final foodPhotoConsentLookupProvider = Provider<FoodPhotoConsentLookup>((ref) {
  final consentRepository = ref.watch(foodPhotoConsentRepositoryProvider);
  return consentRepository.hasConsent;
});

final foodPhotoClockProvider = Provider<FoodPhotoClock>((ref) => DateTime.now);

final foodPhotoEpochDayProvider =
    Provider<FoodPhotoEpochDay>((ref) => currentLocalEpochDay);

final foodPhotoNotifierProvider =
    NotifierProvider.autoDispose<FoodPhotoNotifier, FoodPhotoState>(
  FoodPhotoNotifier.new,
);

enum _UploadKind { primary, secondary }

final class FoodPhotoNotifier extends Notifier<FoodPhotoState> {
  late FoodAnalysisClient _client;
  late NutritionRepository _repository;
  late FoodPhotoConsentLookup _lookupConsent;
  late FoodPhotoClock _clock;
  late FoodPhotoEpochDay _epochDay;

  PreparedUpload? _pendingUpload;
  _UploadKind? _pendingUploadKind;
  String? _activeAnalysisId;
  DateTime? _activeExpiresAt;
  FoodAnalysisReady? _readyResult;
  String? _savedAnalysisId;
  FoodPhotoCaptureToken? _activeCaptureToken;
  int _manualComponentSequence = 0;
  int _operationGeneration = 0;
  bool _disposed = false;
  bool _checkingConsent = false;

  @override
  FoodPhotoState build() {
    _client = ref.watch(foodAnalysisClientProvider);
    _repository = ref.watch(nutritionRepositoryProvider);
    _lookupConsent = ref.watch(foodPhotoConsentLookupProvider);
    _clock = ref.watch(foodPhotoClockProvider);
    _epochDay = ref.watch(foodPhotoEpochDayProvider);
    _disposed = false;

    final client = _client;
    ref.onDispose(() {
      _disposed = true;
      _operationGeneration++;
      client.cancelPending();
      _clearTransientData();
      _savedAnalysisId = null;
      _activeCaptureToken = null;
    });
    return const FoodPhotoIdle();
  }

  FoodPhotoCaptureToken beginPrimaryCapture() {
    if (_isBusy) {
      throw StateError('A food-photo operation is already in progress.');
    }
    _operationGeneration++;
    _startNewWorkflow();
    final token = FoodPhotoCaptureToken.create();
    _activeCaptureToken = token;
    state = const FoodPhotoCapturing(isSecondary: false);
    return token;
  }

  Future<FoodPhotoCaptureToken?> requestPrimaryCapture() async {
    if (_isBusy || _checkingConsent) return null;
    _checkingConsent = true;
    final generation = ++_operationGeneration;
    final hasConsent = await _readConsent(generation);
    _checkingConsent = false;
    if (!_isCurrent(generation)) return null;
    if (!hasConsent) {
      _clearTransientData();
      state = const FoodPhotoConsentRequired();
      return null;
    }
    return beginPrimaryCapture();
  }

  FoodPhotoCaptureToken? beginSecondaryCapture() {
    if (state is! FoodPhotoNeedsSecondPhoto || _isExpired) {
      if (_isExpired) _setExpired();
      return null;
    }
    final token = FoodPhotoCaptureToken.create();
    _activeCaptureToken = token;
    state = const FoodPhotoCapturing(isSecondary: true);
    return token;
  }

  Future<void> submitPrimary(
    PreparedUpload upload, {
    required FoodPhotoCaptureToken token,
  }) async {
    final current = state;
    if (_isBusy ||
        current is! FoodPhotoCapturing ||
        current.isSecondary ||
        !identical(token, _activeCaptureToken)) {
      return;
    }
    _startNewWorkflow(clearSavedId: false);
    await _submitUpload(upload, _UploadKind.primary);
  }

  Future<void> submitSecondary(
    PreparedUpload upload, {
    required FoodPhotoCaptureToken token,
  }) async {
    final current = state;
    final validState = current is FoodPhotoNeedsSecondPhoto ||
        (current is FoodPhotoCapturing && current.isSecondary);
    if (!validState || _isBusy || _activeAnalysisId == null) return;
    if (!identical(token, _activeCaptureToken) ||
        current is! FoodPhotoCapturing) {
      return;
    }
    if (_isExpired) {
      _setExpired();
      return;
    }
    await _submitUpload(upload, _UploadKind.secondary);
  }

  Future<void> retry() async {
    final current = state;
    final upload = _pendingUpload;
    final kind = _pendingUploadKind;
    if (current is! FoodPhotoError ||
        (current.code != 'ANALYSIS_UNAVAILABLE' &&
            current.code != 'INVALID_PROVIDER_RESPONSE') ||
        !current.canRetry ||
        upload == null ||
        kind == null) {
      return;
    }
    if (kind == _UploadKind.secondary && _isExpired) {
      _setExpired();
      return;
    }
    await _submitUpload(upload, kind, isRetry: true);
  }

  Future<void> _submitUpload(
    PreparedUpload upload,
    _UploadKind kind, {
    bool isRetry = false,
  }) async {
    if (!isRetry) {
      _pendingUpload = upload;
      _pendingUploadKind = kind;
    }
    final analysisId = _activeAnalysisId;
    if (kind == _UploadKind.secondary && analysisId == null) {
      _clearPendingUpload();
      _setExpired();
      return;
    }

    final generation = ++_operationGeneration;
    state = FoodPhotoUploading(isSecondary: kind == _UploadKind.secondary);

    final hasConsent = await _readConsent(generation);
    if (!_isCurrent(generation)) return;
    if (!hasConsent) {
      _clearTransientData();
      state = const FoodPhotoConsentRequired();
      return;
    }

    try {
      final review = switch (kind) {
        _UploadKind.primary => await _client.startPhotoAnalysis(upload),
        _UploadKind.secondary =>
          await _client.addSecondaryPhoto(analysisId!, upload),
      };
      if (!_isCurrent(generation)) return;
      _applyReview(
        review,
        kind: kind,
        expectedAnalysisId: analysisId,
      );
    } on FoodAnalysisCancelledException {
      if (!_isCurrent(generation)) return;
      _clearTransientData();
      state = const FoodPhotoCancelled();
    } on FoodAnalysisApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _handleApiError(error);
    } on FoodAnalysisFormatException {
      if (!_isCurrent(generation)) return;
      _handleApiError(
        FoodAnalysisApiException(
          code: 'INVALID_PROVIDER_RESPONSE',
          message: 'Phản hồi phân tích ảnh không hợp lệ.',
        ),
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _handleApiError(
        FoodAnalysisApiException(
          code: 'ANALYSIS_UNAVAILABLE',
          message: 'Không thể phân tích ảnh lúc này.',
        ),
      );
    }
  }

  void _applyReview(
    FoodAnalysisReview review, {
    required _UploadKind kind,
    required String? expectedAnalysisId,
  }) {
    _activeCaptureToken = null;
    final invalidSecondary = kind == _UploadKind.secondary &&
        (expectedAnalysisId == null ||
            review.analysisId != expectedAnalysisId ||
            review.status == FoodAnalysisStatus.needsSecondImage);
    final invalidReview = invalidSecondary ||
        review.status == FoodAnalysisStatus.ready ||
        (review.status == FoodAnalysisStatus.needsConfirmation &&
            review.imageType == FoodImageType.unknown);
    if (invalidReview) {
      _handleApiError(
        FoodAnalysisApiException(
          code: 'INVALID_PROVIDER_RESPONSE',
          message: invalidSecondary
              ? 'Phản hồi ảnh thứ hai không khớp phiên phân tích.'
              : 'Phản hồi phân tích ảnh không hợp lệ.',
        ),
      );
      return;
    }
    if (!review.expiresAt.isAfter(_clock())) {
      _clearSessionData();
      _setExpired();
      return;
    }

    _clearPendingUpload();
    _activeAnalysisId = review.analysisId;
    _activeExpiresAt = review.expiresAt;
    final summary = FoodPhotoReviewSummary.fromReview(review);

    switch (review.status) {
      case FoodAnalysisStatus.needsSecondImage:
        state = FoodPhotoNeedsSecondPhoto(summary);
      case FoodAnalysisStatus.needsConfirmation:
        switch (review.imageType) {
          case FoodImageType.meal:
            final mealState = FoodPhotoReviewingMeal(
              summary,
              _mealDraftFromReview(review),
            );
            state = mealState;
          case FoodImageType.nutritionLabel:
            final labelState = FoodPhotoReviewingLabel(
              summary,
              _labelDraftFromReview(review),
            );
            state = labelState;
          case FoodImageType.unknown:
            _clearSessionData();
            state = const FoodPhotoError(
              code: 'INVALID_PROVIDER_RESPONSE',
              message: 'Phản hồi phân tích ảnh không hợp lệ.',
              canRetry: false,
              requiresRecapture: false,
            );
        }
      case FoodAnalysisStatus.unrecognized:
        _clearSessionData();
        state = const FoodPhotoError(
          code: 'UNRECOGNIZED',
          message: 'Không nhận diện được món ăn hoặc nhãn dinh dưỡng.',
          canRetry: false,
          requiresRecapture: true,
        );
      case FoodAnalysisStatus.ready:
        _clearSessionData();
        state = const FoodPhotoError(
          code: 'INVALID_PROVIDER_RESPONSE',
          message: 'Phản hồi phân tích ảnh không hợp lệ.',
          canRetry: false,
          requiresRecapture: false,
        );
    }
  }

  FoodPhotoMealDraft _mealDraftFromReview(FoodAnalysisReview review) {
    final components = review.components!;
    return FoodPhotoMealDraft(
      nameVi: components.map((component) => component.nameVi).join(' + '),
      components: components
          .map(
            (component) => FoodPhotoMealComponentDraft(
              observationId: component.id,
              foodId: component.matchedFoodId,
              nameVi: component.nameVi,
              portion: component.suggestedPortion,
              requiresManualPortion: component.requiresManualPortion ||
                  component.suggestedPortion == null,
              manualPortionCompleted: !component.requiresManualPortion &&
                  component.suggestedPortion != null,
            ),
          )
          .toList(growable: false),
    );
  }

  FoodPhotoLabelDraft _labelDraftFromReview(FoodAnalysisReview review) {
    final label = review.labelFacts!;
    final consumed = label.netWeightGrams == null
        ? null
        : LabelConsumedAmount(
            kind: LabelConsumedKind.grams,
            amount: label.netWeightGrams!,
          );
    return FoodPhotoLabelDraft(
      nameVi: label.nameVi,
      basis: label.basis,
      calories: label.facts.calories,
      proteinGrams: label.facts.proteinGrams,
      carbsGrams: label.facts.carbsGrams,
      fatGrams: label.facts.fatGrams,
      servingSizeGrams: label.servingSizeGrams,
      servingsPerContainer: label.servingsPerContainer,
      netWeightGrams: label.netWeightGrams,
      consumed: consumed,
    );
  }

  void updateMealName(String nameVi) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    _setMealDraft(
      current,
      FoodPhotoMealDraft(nameVi: nameVi, components: current.draft.components),
    );
  }

  void renameMealComponent(String observationId, String nameVi) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    final components = current.draft.components
        .map(
          (component) => component.observationId == observationId
              ? component.copyWith(nameVi: nameVi, foodId: null)
              : component,
        )
        .toList(growable: false);
    _setMealDraft(
      current,
      FoodPhotoMealDraft(nameVi: current.draft.nameVi, components: components),
    );
  }

  void updateMealComponentPortion(
    String observationId,
    FoodPortion portion,
  ) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    final components = current.draft.components
        .map(
          (component) => component.observationId == observationId
              ? component.copyWith(
                  portion: portion,
                  manualPortionCompleted: true,
                )
              : component,
        )
        .toList(growable: false);
    _setMealDraft(
      current,
      FoodPhotoMealDraft(nameVi: current.draft.nameVi, components: components),
    );
  }

  void addMealComponent({
    required String nameVi,
    String? foodId,
    FoodPortion? portion,
  }) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    final usedIds = current.draft.components
        .map((component) => component.observationId)
        .toSet();
    String observationId;
    do {
      observationId = 'manual-${++_manualComponentSequence}';
    } while (usedIds.contains(observationId));
    final component = FoodPhotoMealComponentDraft(
      observationId: observationId,
      foodId: foodId,
      nameVi: nameVi,
      portion: portion,
      requiresManualPortion: portion == null,
      manualPortionCompleted: portion != null,
    );
    _setMealDraft(
      current,
      FoodPhotoMealDraft(
        nameVi: current.draft.nameVi,
        components: [...current.draft.components, component],
      ),
    );
  }

  void removeMealComponent(String observationId) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    _setMealDraft(
      current,
      FoodPhotoMealDraft(
        nameVi: current.draft.nameVi,
        components: current.draft.components
            .where((component) => component.observationId != observationId)
            .toList(growable: false),
      ),
    );
  }

  void _setMealDraft(
    FoodPhotoReviewingMeal current,
    FoodPhotoMealDraft draft,
  ) {
    final next = FoodPhotoReviewingMeal(current.review, draft);
    if (state is FoodPhotoError) {
      final error = state as FoodPhotoError;
      state = FoodPhotoError(
        code: error.code,
        message: error.message,
        canRetry: error.canRetry,
        requiresRecapture: error.requiresRecapture,
        canRetryConfirm: error.canRetryConfirm,
        canUseManualEntry: error.canUseManualEntry,
        reviewSummary: error.reviewSummary,
        mealDraft: draft,
        labelDraft: null,
        affectedComponentId: error.affectedComponentId,
      );
    } else {
      state = next;
    }
  }

  FoodPhotoReviewingMeal? _mealReviewForEditing() {
    final current = state;
    if (current is FoodPhotoReviewingMeal) return current;
    if (current is FoodPhotoError &&
        current.mealDraft != null &&
        current.reviewSummary != null) {
      return FoodPhotoReviewingMeal(current.reviewSummary!, current.mealDraft!);
    }
    return null;
  }

  void updateMealComponentFoodId(String observationId, String? foodId) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    final components = current.draft.components
        .map(
          (component) => component.observationId == observationId
              ? component.copyWith(foodId: foodId)
              : component,
        )
        .toList(growable: false);
    _setMealDraft(
      current,
      FoodPhotoMealDraft(nameVi: current.draft.nameVi, components: components),
    );
  }

  void selectKnownFood(String observationId, KnownFoodOption food) {
    final current = _mealReviewForEditing();
    if (current == null) return;
    final components = current.draft.components.map((component) {
      if (component.observationId != observationId) return component;
      final compatible = food.supportsPortion(component.portion);
      return component.copyWith(
        foodId: food.foodId,
        nameVi: food.nameVi,
        portion: compatible ? component.portion : null,
        requiresManualPortion: !compatible,
        manualPortionCompleted: compatible,
      );
    }).toList(growable: false);
    final draft = FoodPhotoMealDraft(
        nameVi: current.draft.nameVi, components: components);
    state = FoodPhotoReviewingMeal(current.review, draft);
  }

  void updateLabelName(String nameVi) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    _setLabelDraft(
      current,
      current.draft.copyWith(nameVi: nameVi),
    );
  }

  void updateLabelBasis(LabelBasis basis) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    _setLabelDraft(
      current,
      current.draft.copyWith(basis: basis),
    );
  }

  void updateLabelFacts({
    required double? calories,
    required double? proteinGrams,
    required double? carbsGrams,
    required double? fatGrams,
  }) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    final draft = current.draft;
    _setLabelDraft(
      current,
      FoodPhotoLabelDraft(
        nameVi: draft.nameVi,
        basis: draft.basis,
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
        servingSizeGrams: draft.servingSizeGrams,
        servingsPerContainer: draft.servingsPerContainer,
        netWeightGrams: draft.netWeightGrams,
        consumed: draft.consumed,
      ),
    );
  }

  void updateLabelServingSize(double? servingSizeGrams) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    final draft = current.draft;
    _setLabelDraft(
      current,
      FoodPhotoLabelDraft(
        nameVi: draft.nameVi,
        basis: draft.basis,
        calories: draft.calories,
        proteinGrams: draft.proteinGrams,
        carbsGrams: draft.carbsGrams,
        fatGrams: draft.fatGrams,
        servingSizeGrams: servingSizeGrams,
        servingsPerContainer: draft.servingsPerContainer,
        netWeightGrams: draft.netWeightGrams,
        consumed: draft.consumed,
      ),
    );
  }

  void updateLabelServingsPerContainer(double? value) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    _setLabelDraft(
        current, current.draft.copyWith(servingsPerContainer: value));
  }

  void updateLabelNetWeight(double? value) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    _setLabelDraft(current, current.draft.copyWith(netWeightGrams: value));
  }

  void updateLabelConsumed({
    required LabelConsumedKind? kind,
    required double? amount,
  }) {
    final current = _labelReviewForEditing();
    if (current == null) return;
    try {
      final consumed = kind == null || amount == null
          ? null
          : LabelConsumedAmount(kind: kind, amount: amount);
      _setLabelDraft(
        current,
        current.draft.copyWith(consumed: consumed),
      );
    } on FoodAnalysisFormatException catch (error) {
      final cleared = current.draft.copyWith(consumed: null);
      _setLabelDraft(current, cleared);
      if (state is FoodPhotoReviewingLabel) {
        state = FoodPhotoReviewingLabel(
          current.review,
          cleared,
          validationMessage: error.message,
        );
      }
    }
  }

  void _setLabelDraft(
    FoodPhotoReviewingLabel current,
    FoodPhotoLabelDraft draft,
  ) {
    final next = FoodPhotoReviewingLabel(current.review, draft);
    if (state is FoodPhotoError) {
      final error = state as FoodPhotoError;
      state = FoodPhotoError(
        code: error.code,
        message: error.message,
        canRetry: error.canRetry,
        requiresRecapture: error.requiresRecapture,
        canRetryConfirm: error.canRetryConfirm,
        canUseManualEntry: error.canUseManualEntry,
        reviewSummary: error.reviewSummary,
        mealDraft: null,
        labelDraft: draft,
        affectedComponentId: error.affectedComponentId,
      );
    } else {
      state = next;
    }
  }

  FoodPhotoReviewingLabel? _labelReviewForEditing() {
    final current = state;
    if (current is FoodPhotoReviewingLabel) return current;
    if (current is FoodPhotoError &&
        current.labelDraft != null &&
        current.reviewSummary != null) {
      return FoodPhotoReviewingLabel(
        current.reviewSummary!,
        current.labelDraft!,
      );
    }
    return null;
  }

  Future<void> confirm() async {
    final reviewState = switch (state) {
      FoodPhotoReviewingMeal() => state as FoodPhotoReviewingMeal,
      FoodPhotoReviewingLabel() => state as FoodPhotoReviewingLabel,
      FoodPhotoError(canRetryConfirm: true) =>
        _mealReviewForEditing() ?? _labelReviewForEditing(),
      _ => null,
    };
    if (reviewState == null) return;
    FoodAnalysisConfirmation confirmation;
    try {
      if (reviewState case FoodPhotoReviewingMeal(:final draft)) {
        confirmation = draft.toConfirmation();
      } else if (reviewState case FoodPhotoReviewingLabel(:final draft)) {
        confirmation = draft.toConfirmation();
      } else {
        return;
      }
    } on FoodAnalysisFormatException catch (error) {
      switch (reviewState) {
        case FoodPhotoReviewingMeal(:final review, :final draft):
          state = FoodPhotoReviewingMeal(
            review,
            draft,
            validationMessage: error.message,
          );
        case FoodPhotoReviewingLabel(:final review, :final draft):
          state = FoodPhotoReviewingLabel(
            review,
            draft,
            validationMessage: error.message,
          );
        default:
      }
      return;
    }

    final analysisId = _activeAnalysisId;
    if (analysisId == null || _isExpired) {
      _setExpired();
      return;
    }

    final generation = ++_operationGeneration;
    state = const FoodPhotoConfirming();
    final hasConsent = await _readConsent(generation);
    if (!_isCurrent(generation)) return;
    if (!hasConsent) {
      _clearTransientData();
      state = const FoodPhotoConsentRequired();
      return;
    }

    try {
      final ready = await _client.confirmAnalysis(analysisId, confirmation);
      if (!_isCurrent(generation)) return;
      if (ready.analysisId != analysisId) {
        _setConfirmationRecaptureRequired(
          message: 'Phản hồi xác nhận không khớp phiên phân tích.',
        );
        return;
      }
      _readyResult = ready;
      state = FoodPhotoReady(FoodPhotoEstimateResult.fromReady(ready));
    } on FoodAnalysisApiException catch (error) {
      if (!_isCurrent(generation)) return;
      if (error.code == 'INVALID_CONFIRMATION') {
        switch (reviewState) {
          case FoodPhotoReviewingMeal(:final review, :final draft):
            state = FoodPhotoReviewingMeal(
              review,
              draft,
              validationMessage: error.message,
              fieldErrorPath: FoodPhotoFieldErrorPath.fromApiDetails(
                error.details,
                componentObservationIds: draft.components
                    .map((component) => component.observationId)
                    .toList(growable: false),
              ),
            );
          case FoodPhotoReviewingLabel(:final review, :final draft):
            state = FoodPhotoReviewingLabel(
              review,
              draft,
              validationMessage: error.message,
              fieldErrorPath:
                  FoodPhotoFieldErrorPath.fromApiDetails(error.details),
            );
          default:
        }
      } else {
        _handleConfirmApiError(error, reviewState);
      }
    } on FoodAnalysisCancelledException {
      if (!_isCurrent(generation)) return;
      _clearTransientData();
      state = const FoodPhotoCancelled();
    } on FoodAnalysisFormatException {
      if (!_isCurrent(generation)) return;
      _setConfirmationRecaptureRequired(
        message: 'Phản hồi xác nhận không hợp lệ.',
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _retainConfirmationError(
        FoodAnalysisApiException(
          code: 'ANALYSIS_UNAVAILABLE',
          message: 'Không thể xác nhận kết quả lúc này.',
        ),
        reviewState,
      );
    }
  }

  Future<void> retryConfirm() async {
    final current = state;
    if (current is FoodPhotoError && current.canRetryConfirm) {
      await confirm();
    }
  }

  void _handleConfirmApiError(
    FoodAnalysisApiException error,
    FoodPhotoState reviewState,
  ) {
    if (error.code == 'ANALYSIS_EXPIRED') {
      _setExpired(message: error.message);
      return;
    }
    if (error.code == 'INVALID_PROVIDER_RESPONSE') {
      _setConfirmationRecaptureRequired(message: error.message);
      return;
    }
    if ((error.code == 'UNSUPPORTED_PORTION' ||
            error.code == 'UNSUPPORTED_FOOD_DATA') &&
        reviewState is FoodPhotoReviewingMeal) {
      final componentId = _affectedComponentId(error, reviewState.draft);
      state = FoodPhotoReviewingMeal(
        reviewState.review,
        reviewState.draft,
        validationMessage: error.message,
        fieldErrorPath: componentId == null
            ? null
            : FoodPhotoFieldErrorPath(
                FoodPhotoFieldKind.componentPortion,
                componentId: componentId,
              ),
      );
      return;
    }
    if (error.code == 'ANALYSIS_UNAVAILABLE' ||
        error.code == 'DATABASE_NO_MATCH') {
      _retainConfirmationError(error, reviewState);
      return;
    }
    _handleApiError(error);
  }

  void _retainConfirmationError(
    FoodAnalysisApiException error,
    FoodPhotoState reviewState,
  ) {
    final summary = reviewState is FoodPhotoReviewingMeal
        ? reviewState.review
        : (reviewState as FoodPhotoReviewingLabel).review;
    final mealDraft =
        reviewState is FoodPhotoReviewingMeal ? reviewState.draft : null;
    final labelDraft =
        reviewState is FoodPhotoReviewingLabel ? reviewState.draft : null;
    state = FoodPhotoError(
      code: error.code,
      message: error.message,
      canRetry: false,
      requiresRecapture: false,
      canRetryConfirm: true,
      canUseManualEntry: true,
      reviewSummary: summary,
      mealDraft: mealDraft,
      labelDraft: labelDraft,
      affectedComponentId: _affectedComponentId(error, mealDraft),
    );
  }

  String? _affectedComponentId(
    FoodAnalysisApiException error,
    FoodPhotoMealDraft? draft,
  ) {
    if (draft == null ||
        !const {
          'DATABASE_NO_MATCH',
          'UNSUPPORTED_PORTION',
          'UNSUPPORTED_FOOD_DATA',
        }.contains(error.code)) {
      return null;
    }
    final observationId = error.details['observationId'];
    if (observationId is String &&
        draft.components
                .where((component) => component.observationId == observationId)
                .length ==
            1) {
      return observationId;
    }
    final foodId = error.details['foodId'];
    if (foodId is! String) return null;
    final matches = draft.components
        .where((component) => component.foodId == foodId)
        .toList(growable: false);
    return matches.length == 1 ? matches.single.observationId : null;
  }

  Future<void> save() async {
    final current = state;
    final ready = _readyResult;
    if (current is! FoodPhotoReady ||
        ready == null ||
        _savedAnalysisId == ready.analysisId) {
      return;
    }

    final generation = ++_operationGeneration;
    state = FoodPhotoSaving(current.result);
    try {
      await _repository.logPhotoEstimate(
        epochDay: _epochDay(),
        log: PhotoNutritionLog(
          name: ready.nameVi,
          mealTime: _mealTimeFor(_clock()),
          imageType: ready.imageType,
          estimate: ready.estimate,
          confidenceLevel: ready.confidenceLevel,
          calculationSummary: ready.calculationSummary,
        ),
      );
      if (!_isCurrent(generation)) return;
      _savedAnalysisId = ready.analysisId;
      _clearTransientData();
      state = const FoodPhotoSaved();
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = FoodPhotoSaveFailed(current.result);
    }
  }

  Future<void> retrySave() async {
    final current = state;
    if (current is! FoodPhotoSaveFailed || _readyResult == null) return;
    state = FoodPhotoReady(current.result);
    await save();
  }

  void editFromReady() {
    final current = state;
    if (current is! FoodPhotoReady && current is! FoodPhotoSaveFailed) return;
    _setConfirmationRecaptureRequired(
      code: 'EDIT_REQUIRES_RECAPTURE',
      message: 'Kết quả đã được xác nhận. Hãy chụp ảnh mới để chỉnh sửa.',
    );
  }

  void useManualEntry() {
    if (state is FoodPhotoSaving) return;
    _operationGeneration++;
    _client.cancelPending();
    _clearTransientData();
    state = const FoodPhotoManualEntryRequested();
  }

  void cancel() {
    if (state is FoodPhotoSaving) return;
    _operationGeneration++;
    _client.cancelPending();
    _clearTransientData();
    state = const FoodPhotoCancelled();
  }

  void reset() {
    if (_isBusy) return;
    _operationGeneration++;
    _startNewWorkflow();
    state = const FoodPhotoIdle();
  }

  Future<bool> _readConsent(int generation) async {
    try {
      final hasConsent = await _lookupConsent();
      return _isCurrent(generation) && hasConsent;
    } catch (_) {
      return false;
    }
  }

  void _handleApiError(FoodAnalysisApiException error) {
    if (error.code == 'ANALYSIS_EXPIRED') {
      _clearTransientData();
      _setExpired(message: error.message);
      return;
    }

    final canRetry = (error.code == 'ANALYSIS_UNAVAILABLE' ||
            error.code == 'INVALID_PROVIDER_RESPONSE') &&
        _pendingUpload != null &&
        _pendingUploadKind != null;
    if (!canRetry) {
      _clearTransientData();
    }
    state = FoodPhotoError(
      code: error.code,
      message: error.message,
      canRetry: canRetry,
      requiresRecapture: _requiresRecapture(error.code),
      canUseManualEntry: true,
    );
  }

  bool _requiresRecapture(String code) => switch (code) {
        'ANALYSIS_EXPIRED' ||
        'INVALID_IMAGE' ||
        'IMAGE_TOO_LARGE' ||
        'UNSUPPORTED_IMAGE_TYPE' ||
        'UNRECOGNIZED' =>
          true,
        _ => false,
      };

  void _setExpired({
    String message = 'Phiên phân tích đã hết hạn. Hãy chụp ảnh mới.',
  }) {
    _clearTransientData();
    state = FoodPhotoError(
      code: 'ANALYSIS_EXPIRED',
      message: message,
      canRetry: false,
      requiresRecapture: true,
    );
  }

  void _setConfirmationRecaptureRequired({
    String code = 'INVALID_PROVIDER_RESPONSE',
    required String message,
  }) {
    _clearTransientData();
    state = FoodPhotoError(
      code: code,
      message: message,
      canRetry: false,
      requiresRecapture: true,
      canUseManualEntry: true,
    );
  }

  bool get _isExpired {
    final expiresAt = _activeExpiresAt;
    return expiresAt != null && !expiresAt.isAfter(_clock());
  }

  bool get _isBusy =>
      state is FoodPhotoUploading ||
      state is FoodPhotoConfirming ||
      state is FoodPhotoSaving;

  bool _isCurrent(int generation) =>
      !_disposed && generation == _operationGeneration;

  void _clearPendingUpload() {
    _pendingUpload = null;
    _pendingUploadKind = null;
  }

  void _clearSessionData() {
    _activeAnalysisId = null;
    _activeExpiresAt = null;
    _readyResult = null;
  }

  void _clearTransientData() {
    _clearPendingUpload();
    _clearSessionData();
    _activeCaptureToken = null;
  }

  void _startNewWorkflow({bool clearSavedId = true}) {
    _clearTransientData();
    if (clearSavedId) _savedAnalysisId = null;
  }

  String _mealTimeFor(DateTime now) {
    if (now.hour < 10) return 'BREAKFAST';
    if (now.hour < 14) return 'LUNCH';
    if (now.hour < 17) return 'SNACK';
    return 'DINNER';
  }
}
