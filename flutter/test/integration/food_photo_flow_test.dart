import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/food_photo_analysis_models.dart';
import 'package:gym_app/data/providers/data_providers.dart';
import 'package:gym_app/data/providers/remote_providers.dart';
import 'package:gym_app/data/remote/food_analysis_client.dart';
import 'package:gym_app/data/repositories/nutrition_repository.dart';
import 'package:gym_app/feature/nutrition/photo/food_camera_gateway.dart';
import 'package:gym_app/feature/nutrition/photo/food_capture_screen.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_flow_screen.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_notifier.dart';
import 'package:gym_app/feature/nutrition/photo/food_photo_preprocessor.dart';
import 'package:gym_app/ui/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clear meal confirms and saves exactly once', (tester) async {
    final client = _FakeClient()..startResult = _mealReview();
    client.confirmResult = _ready();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true, launcher: true);

    await tester.tap(find.byKey(const Key('flow-launcher-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-photo-primary-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meal-component-rice')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('food-analysis-confirm')));
    await tester.tap(find.byKey(const Key('food-analysis-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('food-analysis-save')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('food-analysis-save')));
    await tester.tap(find.byKey(const Key('food-analysis-save')));
    await tester.tap(find.byKey(const Key('food-analysis-save')));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 1);
    expect(client.confirmCalls, 1);
    expect(find.byKey(const Key('food-analysis-done')), findsOneWidget);
    await tester.tap(find.byKey(const Key('food-analysis-done')));
    await tester.pumpAndSettle();
    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('save state disables cancellation until repository completes',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _mealReview()
      ..confirmResult = _ready();
    final repository = _FakeRepository()..saveGate = Completer<void>();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);
    await tester.tap(find.byKey(const Key('food-photo-primary-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-food-photo')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('food-analysis-confirm')));
    await tester.tap(find.byKey(const Key('food-analysis-confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('food-analysis-save')));
    await tester.tap(find.byKey(const Key('food-analysis-save')));
    await tester.pump();

    final cancel = tester
        .widget<IconButton>(find.byKey(const Key('food-analysis-cancel')));
    expect(cancel.onPressed, isNull);
    final save = tester
        .widget<FilledButton>(find.byKey(const Key('food-analysis-save')));
    expect(save.onPressed, isNull);
    repository.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 1);
  });

  testWidgets('ambiguous meal requests second photo then correction and save',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _mealReview(status: 'NEEDS_SECOND_IMAGE')
      ..secondaryResult = _mealReview(manualPortion: true)
      ..confirmResult = _ready();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);

    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');
    expect(
        find.byKey(const Key('food-photo-secondary-action')), findsOneWidget);
    expect(find.textContaining('góc bên'), findsOneWidget);
    await _captureCurrentPhoto(tester,
        actionKey: 'food-photo-secondary-action');
    expect(client.secondaryCalls, 1);

    await tester
        .tap(find.byKey(const Key('portion-choice-rice-bowl-1-medium')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('food-analysis-confirm')));
    await tester.tap(find.byKey(const Key('food-analysis-confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('food-analysis-save')));
    await tester.tap(find.byKey(const Key('food-analysis-save')));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 1);
  });

  testWidgets('false-positive manual component can be deleted then confirmed',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _mealReview(status: 'NEEDS_SECOND_IMAGE')
      ..secondaryResult = _mealReview(
        manualPortion: true,
        includeRetainedComponent: true,
      )
      ..confirmResult = _ready();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);

    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');
    await _captureCurrentPhoto(tester,
        actionKey: 'food-photo-secondary-action');
    await tester
        .ensureVisible(find.byKey(const Key('meal-component-remove-rice')));
    await tester.tap(find.byKey(const Key('meal-component-remove-rice')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('food-analysis-confirm')));
    await tester.tap(find.byKey(const Key('food-analysis-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food-analysis-save')), findsOneWidget);
    final confirmation = client.confirmations.single as MealConfirmation;
    expect(confirmation.components, hasLength(1));
    expect(confirmation.components.single.observationId, 'retained');
  });

  testWidgets(
      'clear label accepts consumed correction and saves deterministic result',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _labelReview()
      ..confirmResult = _labelReady();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);
    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');

    await tester.enterText(
        find.byKey(const Key('label-consumed-amount')), '30');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('food-analysis-confirm')));
    await tester.tap(find.byKey(const Key('food-analysis-confirm')));
    await tester.pumpAndSettle();
    final confirmation = client.confirmations.single as LabelConfirmation;
    expect(confirmation.consumed.kind, LabelConsumedKind.grams);
    expect(confirmation.consumed.amount, 30);
    await tester.ensureVisible(find.byKey(const Key('food-analysis-save')));
    await tester.tap(find.byKey(const Key('food-analysis-save')));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 1);
  });

  testWidgets(
      'ambiguous label cannot confirm until basis facts and amount are corrected',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _labelReview(ambiguous: true)
      ..confirmResult = _labelReady();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);
    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');

    var confirm = tester
        .widget<FilledButton>(find.byKey(const Key('food-analysis-confirm')));
    expect(confirm.onPressed, isNull);
    await tester.tap(find.byKey(const Key('label-basis-per-100g')));
    await tester.enterText(find.byKey(const Key('label-calories')), '100');
    await tester.enterText(find.byKey(const Key('label-protein')), '3');
    await tester.enterText(find.byKey(const Key('label-carbs')), '12');
    await tester.enterText(find.byKey(const Key('label-fat')), '4');
    await tester.enterText(
        find.byKey(const Key('label-consumed-amount')), '80');
    await tester.pump();
    confirm = tester
        .widget<FilledButton>(find.byKey(const Key('food-analysis-confirm')));
    expect(confirm.onPressed, isNotNull);
  });

  testWidgets(
      'analysis unavailable offers retry and reuses latest prepared upload',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _mealReview()
      ..failFirstStart = true;
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);
    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');

    expect(find.byKey(const Key('food-analysis-retry')), findsOneWidget);
    expect(find.byKey(const Key('food-analysis-manual')), findsOneWidget);
    await tester.tap(find.byKey(const Key('food-analysis-retry')));
    await tester.pumpAndSettle();
    expect(client.startCalls, 2);
    expect(identical(client.startUploads[0], client.startUploads[1]), isTrue);
    expect(find.byKey(const Key('meal-component-rice')), findsOneWidget);
  });

  testWidgets('blur error maps to recapture', (tester) async {
    final client = _FakeClient()
      ..startResult = _mealReview()
      ..startFailure = FoodAnalysisApiException(
        code: 'IMAGE_TOO_BLURRY',
        message: 'Ảnh bị mờ.',
      );
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);
    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');
    expect(find.byKey(const Key('food-analysis-recapture')), findsOneWidget);
    expect(find.byKey(const Key('food-analysis-manual')), findsOneWidget);
  });

  testWidgets(
      'database no match identifies unique component and offers correction',
      (tester) async {
    final client = _FakeClient()
      ..startResult = _mealReview()
      ..confirmFailure = FoodAnalysisApiException(
        code: 'DATABASE_NO_MATCH',
        message: 'Không có món khớp.',
        details: {'foodId': 'white-rice'},
      );
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true);
    await _captureCurrentPhoto(tester, actionKey: 'food-photo-primary-action');
    await tester.ensureVisible(find.byKey(const Key('food-analysis-confirm')));
    await tester.tap(find.byKey(const Key('food-analysis-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('food-analysis-choose-known-food')),
        findsOneWidget);
    expect(find.byKey(const Key('food-analysis-manual')), findsOneWidget);
  });

  testWidgets(
      'no consent opens no camera/provider and profile fallback returns typed result',
      (tester) async {
    final client = _FakeClient()..startResult = _mealReview();
    final repository = _FakeRepository();
    final gateway = _FakeGateway();
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(client, repository, false),
      child: MaterialApp(
        theme: getGymLightTheme(),
        home:
            _FlowLauncher(gateway: gateway, preprocessor: _FakePreprocessor()),
      ),
    ));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-photo-primary-action')));
    await tester.pumpAndSettle();
    expect(client.startCalls, 0);
    expect((find.byType(FoodCaptureScreen)), findsNothing);
    expect(gateway.initializeCalls, 0);
    expect(find.textContaining('chưa đồng ý tải ảnh'), findsOneWidget);
    expect(find.textContaining('đồng ý AI đám mây'), findsNothing);
    expect(find.textContaining('Hồ sơ'), findsWidgets);
    expect(find.textContaining('nhà cung cấp AI'), findsOneWidget);
    expect(find.textContaining('không được bảo đảm ẩn danh'), findsOneWidget);
    expect(find.textContaining('tiếp tục nhập tay'), findsOneWidget);
    await tester.tap(find.byKey(const Key('food-analysis-open-profile')));
    await tester.pumpAndSettle();
    expect(find.text('openProfile'), findsOneWidget);
    expect(repository.saveCalls, 0);
  });

  testWidgets('cancellation writes nothing', (tester) async {
    final client = _FakeClient()..startResult = _mealReview();
    final repository = _FakeRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(client, repository, true),
      child: MaterialApp(
        theme: getGymLightTheme(),
        home: _FlowLauncher(
          gateway: _FakeGateway(),
          preprocessor: _FakePreprocessor(),
        ),
      ),
    ));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-analysis-cancel')));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 0);
    expect(find.text('cancelled'), findsOneWidget);
  });

  testWidgets('camera route cancellation resets flow with one cancelled result',
      (tester) async {
    final client = _FakeClient()..startResult = _mealReview();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true, launcher: true);
    await tester.tap(find.byKey(const Key('flow-launcher-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-photo-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodCaptureScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('close-food-camera')));
    await tester.pumpAndSettle();
    expect(find.text('cancelled'), findsOneWidget);
    expect(client.startCalls, 0);
    expect(repository.saveCalls, 0);
  });

  testWidgets('manual fallback returns exactly one typed result',
      (tester) async {
    final client = _FakeClient()..startResult = _mealReview();
    final repository = _FakeRepository();
    await _pumpFlow(tester,
        client: client, repository: repository, consent: true, launcher: true);
    await tester.tap(find.byKey(const Key('flow-launcher-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('food-photo-manual-fallback')));
    await tester.pumpAndSettle();
    expect(find.text('manualEntry'), findsOneWidget);
    expect(client.startCalls, 0);
    expect(repository.saveCalls, 0);
  });
}

Future<void> _pumpFlow(
  WidgetTester tester, {
  required _FakeClient client,
  required _FakeRepository repository,
  required bool consent,
  bool launcher = false,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: _overrides(client, repository, consent),
    child: MaterialApp(
      theme: getGymLightTheme(),
      home: launcher
          ? _FlowLauncher(
              gateway: _FakeGateway(), preprocessor: _FakePreprocessor())
          : FoodPhotoFlowScreen(
              gateway: _FakeGateway(), preprocessor: _FakePreprocessor()),
    ),
  ));
  await tester.pump();
}

Future<void> _captureCurrentPhoto(
  WidgetTester tester, {
  required String actionKey,
}) async {
  await tester.tap(find.byKey(Key(actionKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('capture-food-photo')));
  await tester.pumpAndSettle();
}

dynamic _overrides(
        _FakeClient client, _FakeRepository repository, bool consent) =>
    [
      foodAnalysisClientProvider.overrideWithValue(client),
      nutritionRepositoryProvider.overrideWithValue(repository),
      foodPhotoConsentLookupProvider.overrideWithValue(() async => consent),
      foodPhotoClockProvider.overrideWithValue(() => DateTime(2026, 7, 22, 12)),
      foodPhotoEpochDayProvider.overrideWithValue(() => 20000),
    ];

final class _FakeGateway implements FoodCameraGateway {
  int initializeCalls = 0;
  @override
  Widget buildPreview() => const ColoredBox(color: Colors.black);
  @override
  Future<void> dispose() async {}
  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<Uint8List> takePicture() async => Uint8List.fromList([1, 2, 3]);
}

final class _FakePreprocessor implements FoodPhotoPreprocessor {
  @override
  Future<PhotoPreparationResult> prepare(Uint8List sourceBytes) async =>
      PhotoPreparationResult(
        upload: PreparedUpload(
            bytes: sourceBytes, mimeType: 'image/jpeg', filename: 'test.jpg'),
        issues: const {},
      );
}

final class _FakeClient implements FoodAnalysisClient {
  late FoodAnalysisReview startResult;
  FoodAnalysisReview? secondaryResult;
  FoodAnalysisReady? confirmResult;
  bool failFirstStart = false;
  FoodAnalysisApiException? startFailure;
  FoodAnalysisApiException? confirmFailure;
  int startCalls = 0;
  int secondaryCalls = 0;
  int confirmCalls = 0;
  final List<PreparedUpload> startUploads = [];
  final List<FoodAnalysisConfirmation> confirmations = [];

  @override
  Future<List<KnownFoodOption>> listKnownFoods() async =>
      KnownFoodOption.listFromJson({
        'foods': [
          {
            'foodId': 'white-rice',
            'nameVi': 'Cơm trắng',
            'supportsGrams': true,
            'portionOptions': [
              {
                'unit': 'BOWL',
                'sizes': ['SMALL', 'MEDIUM', 'LARGE']
              }
            ]
          }
        ]
      });

  @override
  Future<FoodAnalysisReview> startPhotoAnalysis(PreparedUpload upload) async {
    startCalls++;
    startUploads.add(upload);
    if (failFirstStart && startCalls == 1) {
      throw FoodAnalysisApiException(
        code: 'ANALYSIS_UNAVAILABLE',
        message: 'Dịch vụ tạm thời không khả dụng.',
      );
    }
    final failure = startFailure;
    if (failure != null) {
      throw failure;
    }
    return startResult;
  }

  @override
  Future<FoodAnalysisReady> confirmAnalysis(
      String analysisId, FoodAnalysisConfirmation confirmation) async {
    confirmCalls++;
    confirmations.add(confirmation);
    final failure = confirmFailure;
    if (failure != null) throw failure;
    return confirmResult!;
  }

  @override
  Future<FoodAnalysisReview> addSecondaryPhoto(
      String analysisId, PreparedUpload upload) async {
    secondaryCalls++;
    return secondaryResult ?? startResult;
  }

  @override
  void cancelPending() {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('legacy API not used');
}

final class _FakeRepository implements NutritionRepository {
  int saveCalls = 0;
  Completer<void>? saveGate;

  @override
  Future<void> logPhotoEstimate(
      {required int epochDay, required PhotoNutritionLog log}) async {
    saveCalls++;
    await saveGate?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused repository API');
}

class _FlowLauncher extends StatefulWidget {
  final FoodCameraGateway gateway;
  final FoodPhotoPreprocessor preprocessor;
  const _FlowLauncher({required this.gateway, required this.preprocessor});
  @override
  State<_FlowLauncher> createState() => _FlowLauncherState();
}

class _FlowLauncherState extends State<_FlowLauncher> {
  String result = 'none';
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Text(result),
          FilledButton(
            key: const Key('flow-launcher-open'),
            onPressed: () async {
              final value = await Navigator.of(context)
                  .push<FoodPhotoFlowResult>(MaterialPageRoute(
                builder: (_) => FoodPhotoFlowScreen(
                    gateway: widget.gateway, preprocessor: widget.preprocessor),
              ));
              if (mounted) {
                setState(() => result = value?.action.name ?? 'none');
              }
            },
            child: const Text('Mở'),
          ),
        ]),
      );
}

FoodAnalysisReview _mealReview({
  String status = 'NEEDS_CONFIRMATION',
  bool manualPortion = false,
  bool includeRetainedComponent = false,
}) =>
    FoodAnalysisReview.fromJson({
      'analysisId': 'analysis-1',
      'imageType': 'MEAL',
      'status': status,
      'components': [
        {
          'id': 'rice',
          'nameVi': 'Cơm trắng',
          'matchedFoodId': 'white-rice',
          'confidence': manualPortion ? .4 : .9,
          'isMajor': true,
          'requiresManualPortion': manualPortion,
          'suggestedPortion': manualPortion
              ? null
              : {
                  'kind': 'HOUSEHOLD',
                  'unit': 'BOWL',
                  'quantity': 1,
                  'size': 'MEDIUM'
                },
        },
        if (includeRetainedComponent)
          {
            'id': 'retained',
            'nameVi': 'Cơm trắng',
            'matchedFoodId': 'white-rice',
            'confidence': .9,
            'isMajor': true,
            'requiresManualPortion': false,
            'suggestedPortion': {
              'kind': 'HOUSEHOLD',
              'unit': 'BOWL',
              'quantity': 1,
              'size': 'MEDIUM'
            },
          },
      ],
      'labelFacts': null,
      'confidence': .9,
      'uncertaintyReasons': ['HIDDEN_OIL'],
      'expiresAt': DateTime(2026, 7, 22, 13).toUtc().toIso8601String(),
    });

FoodAnalysisReview _labelReview({bool ambiguous = false}) =>
    FoodAnalysisReview.fromJson({
      'analysisId': 'analysis-label',
      'imageType': 'NUTRITION_LABEL',
      'status': 'NEEDS_CONFIRMATION',
      'components': null,
      'labelFacts': {
        'nameVi': 'Sữa chua',
        'basis': ambiguous ? 'UNKNOWN' : 'PER_100G',
        'facts': {
          'calories': ambiguous ? null : 90,
          'proteinGrams': ambiguous ? null : 3,
          'carbsGrams': ambiguous ? null : 12,
          'fatGrams': ambiguous ? null : 3,
        },
        'servingSizeGrams': null,
        'servingsPerContainer': null,
        'netWeightGrams': ambiguous ? null : 100,
        'confidence': .92,
        'missingFields': ambiguous
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
      'confidence': .92,
      'uncertaintyReasons': [],
      'expiresAt': DateTime(2026, 7, 22, 13).toUtc().toIso8601String(),
    });

FoodAnalysisReady _ready() => FoodAnalysisReady.fromJson({
      'analysisId': 'analysis-1',
      'imageType': 'MEAL',
      'status': 'READY',
      'nameVi': 'Cơm trắng',
      'estimate': {
        'calories': {'min': 180, 'mid': 200, 'max': 230},
        'proteinGrams': {'min': 3, 'mid': 4, 'max': 5},
        'carbsGrams': {'min': 40, 'mid': 44, 'max': 48},
        'fatGrams': {'min': 0, 'mid': 1, 'max': 2},
      },
      'confidenceLevel': 'MEDIUM',
      'uncertaintyReasons': ['HIDDEN_OIL'],
      'calculationSummary': '1 bát cơm vừa.',
    });

FoodAnalysisReady _labelReady() => FoodAnalysisReady.fromJson({
      'analysisId': 'analysis-label',
      'imageType': 'NUTRITION_LABEL',
      'status': 'READY',
      'nameVi': 'Sữa chua',
      'estimate': {
        'calories': {'min': 27, 'mid': 27, 'max': 27},
        'proteinGrams': {'min': .9, 'mid': .9, 'max': .9},
        'carbsGrams': {'min': 3.6, 'mid': 3.6, 'max': 3.6},
        'fatGrams': {'min': .9, 'mid': .9, 'max': .9},
      },
      'confidenceLevel': 'HIGH',
      'uncertaintyReasons': [],
      'calculationSummary': '30 g theo giá trị mỗi 100 g.',
    });
