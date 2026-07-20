import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/food_photo_analysis_models.dart';
import 'package:gym_app/core/model/nutrition_models.dart';
import 'package:gym_app/data/remote/food_analysis_client.dart';

void main() {
  group('canonical enum parsing', () {
    test('parses every canonical enum value', () {
      expect(FoodImageType.fromWire('MEAL'), FoodImageType.meal);
      expect(
        FoodImageType.fromWire('NUTRITION_LABEL'),
        FoodImageType.nutritionLabel,
      );
      expect(FoodImageType.fromWire('UNKNOWN'), FoodImageType.unknown);

      expect(
        FoodAnalysisStatus.fromWire('NEEDS_SECOND_IMAGE'),
        FoodAnalysisStatus.needsSecondImage,
      );
      expect(
        FoodAnalysisStatus.fromWire('NEEDS_CONFIRMATION'),
        FoodAnalysisStatus.needsConfirmation,
      );
      expect(
        FoodAnalysisStatus.fromWire('READY'),
        FoodAnalysisStatus.ready,
      );
      expect(
        FoodAnalysisStatus.fromWire('UNRECOGNIZED'),
        FoodAnalysisStatus.unrecognized,
      );

      expect(
        AnalysisConfidenceLevel.fromWire('HIGH'),
        AnalysisConfidenceLevel.high,
      );
      expect(
        AnalysisConfidenceLevel.fromWire('MEDIUM'),
        AnalysisConfidenceLevel.medium,
      );
      expect(
        AnalysisConfidenceLevel.fromWire('LOW'),
        AnalysisConfidenceLevel.low,
      );

      expect(
        FoodPortionKind.fromWire('HOUSEHOLD'),
        FoodPortionKind.household,
      );
      expect(FoodPortionKind.fromWire('GRAMS'), FoodPortionKind.grams);
      expect(
        HouseholdPortionUnit.fromWire('BOWL'),
        HouseholdPortionUnit.bowl,
      );
      expect(
        HouseholdPortionUnit.fromWire('PIECE'),
        HouseholdPortionUnit.piece,
      );
      expect(
        HouseholdPortionUnit.fromWire('SPOON'),
        HouseholdPortionUnit.spoon,
      );
      expect(
        HouseholdPortionUnit.fromWire('SERVING'),
        HouseholdPortionUnit.serving,
      );
      expect(
        HouseholdPortionSize.fromWire('SMALL'),
        HouseholdPortionSize.small,
      );
      expect(
        HouseholdPortionSize.fromWire('MEDIUM'),
        HouseholdPortionSize.medium,
      );
      expect(
        HouseholdPortionSize.fromWire('LARGE'),
        HouseholdPortionSize.large,
      );

      expect(LabelBasis.fromWire('PER_100G'), LabelBasis.per100g);
      expect(LabelBasis.fromWire('PER_SERVING'), LabelBasis.perServing);
      expect(LabelBasis.fromWire('UNKNOWN'), LabelBasis.unknown);
      expect(
        LabelConsumedKind.fromWire('GRAMS'),
        LabelConsumedKind.grams,
      );
      expect(
        LabelConsumedKind.fromWire('SERVINGS'),
        LabelConsumedKind.servings,
      );
      expect(
        FoodNutritionSource.fromWire('MANUAL'),
        FoodNutritionSource.manual,
      );
      expect(
        FoodNutritionSource.fromWire('CAMERA_ANALYSIS'),
        FoodNutritionSource.cameraAnalysis,
      );
    });

    test('rejects every unknown enum value with the typed format error', () {
      final parsers = <Object? Function()>[
        () => FoodImageType.fromWire('PLATE'),
        () => FoodAnalysisStatus.fromWire('PENDING'),
        () => AnalysisConfidenceLevel.fromWire('CERTAIN'),
        () => FoodPortionKind.fromWire('VOLUME'),
        () => HouseholdPortionUnit.fromWire('CUP'),
        () => HouseholdPortionSize.fromWire('HUGE'),
        () => LabelBasis.fromWire('PER_PACKAGE'),
        () => LabelConsumedKind.fromWire('PACKAGES'),
        () => FoodNutritionSource.fromWire('MODEL'),
      ];

      for (final parse in parsers) {
        expect(parse, throwsA(isA<FoodAnalysisFormatException>()));
      }
    });
  });

  group('strict response parsing', () {
    test('accepts shapes that match each image discriminator', () {
      final meal = FoodAnalysisReview.fromJson(_mealReviewJson());
      final label = FoodAnalysisReview.fromJson(_labelReviewJson());
      final unknown = FoodAnalysisReview.fromJson(_unknownReviewJson());

      expect(meal.components, hasLength(1));
      expect(meal.labelFacts, isNull);
      expect(label.components, isNull);
      expect(label.labelFacts?.facts.calories, 498);
      expect(unknown.components, isNull);
      expect(unknown.labelFacts, isNull);
    });

    test('rejects nullable fields that conflict with imageType', () {
      final invalidMeal = _mealReviewJson()..['components'] = null;
      final invalidLabel = _labelReviewJson()..['labelFacts'] = null;
      final invalidUnknown = _unknownReviewJson()..['components'] = <Object?>[];

      for (final json in [invalidMeal, invalidLabel, invalidUnknown]) {
        expect(
          () => FoodAnalysisReview.fromJson(json),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('rejects malformed discriminators, ids, expiry, and confidence', () {
      final cases = [
        _mealReviewJson()..['imageType'] = 'PLATE',
        _mealReviewJson()..['analysisId'] = ' ',
        _mealReviewJson()..['expiresAt'] = 'tomorrow',
        _mealReviewJson()..['expiresAt'] = '2026-02-30T10:15:00.000Z',
        _mealReviewJson()..['confidence'] = 1.01,
        _mealReviewJson()
          ..['components'] = [
            {
              ...(_mealReviewJson()['components'] as List).single
                  as Map<String, Object?>,
              'id': '',
            },
          ],
        _mealReviewJson()
          ..['components'] = [
            {
              ...(_mealReviewJson()['components'] as List).single
                  as Map<String, Object?>,
              'confidence': -0.01,
            },
          ],
      ];

      for (final json in cases) {
        expect(
          () => FoodAnalysisReview.fromJson(json),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('rejects unordered ranges and invalid nutrient numbers', () {
      final minAboveMid = _readyJson();
      (minAboveMid['estimate'] as Map<String, Object?>)['calories'] = {
        'min': 510,
        'mid': 505,
        'max': 580,
      };
      final midAboveMax = _readyJson();
      (midAboveMax['estimate'] as Map<String, Object?>)['fatGrams'] = {
        'min': 8,
        'mid': 17,
        'max': 16,
      };
      final negative = _readyJson();
      (negative['estimate'] as Map<String, Object?>)['proteinGrams'] = {
        'min': -1,
        'mid': 39,
        'max': 44,
      };
      final nonFinite = _readyJson();
      (nonFinite['estimate'] as Map<String, Object?>)['carbsGrams'] = {
        'min': 48,
        'mid': double.infinity,
        'max': double.infinity,
      };

      for (final json in [minAboveMid, midAboveMax, negative, nonFinite]) {
        expect(
          () => FoodAnalysisReady.fromJson(json),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('parses a strict READY result', () {
      final ready = FoodAnalysisReady.fromJson(_readyJson());

      expect(ready.status, FoodAnalysisStatus.ready);
      expect(ready.estimate.calories.mid, 505);
      expect(ready.confidenceLevel, AnalysisConfidenceLevel.medium);
      expect(ready.calculationSummary, contains('cơm'));
    });
  });

  group('DioFoodAnalysisClient', () {
    test('startPhotoAnalysis sends primaryImage to the collection path',
        () async {
      late RequestOptions captured;
      final adapter = _StubAdapter((options, _, __) async {
        captured = options;
        return _jsonResponse(_mealReviewJson(), 201);
      });
      final client = _client(adapter);

      final review = await client.startPhotoAnalysis(_upload('primary.jpg'));

      expect(captured.method, 'POST');
      expect(captured.uri.toString(), 'https://backend.test/api/food-analyses');
      final form = captured.data as FormData;
      expect(form.files.single.key, 'primaryImage');
      expect(form.files.single.value.filename, 'primary.jpg');
      expect(review.analysisId, 'analysis-1');
    });

    test('addSecondaryPhoto sends secondaryImage to the analysis path',
        () async {
      late RequestOptions captured;
      final adapter = _StubAdapter((options, _, __) async {
        captured = options;
        return _jsonResponse(_mealReviewJson(), 200);
      });
      final client = _client(adapter);

      await client.addSecondaryPhoto('analysis-1', _upload('side.webp'));

      expect(
        captured.uri.toString(),
        'https://backend.test/api/food-analyses/analysis-1/images',
      );
      final form = captured.data as FormData;
      expect(form.files.single.key, 'secondaryImage');
      expect(form.files.single.value.filename, 'side.webp');
    });

    test('confirmAnalysis posts canonical JSON to the requested analysis id',
        () async {
      late RequestOptions captured;
      final adapter = _StubAdapter((options, _, __) async {
        captured = options;
        return _jsonResponse(_readyJson(), 200);
      });
      final client = _client(adapter);
      final confirmation = MealConfirmation(
        nameVi: 'Cơm với ức gà',
        components: [
          ConfirmedFoodComponent(
            observationId: 'component-1',
            foodId: 'white-rice',
            nameVi: 'Cơm trắng',
            portion: const HouseholdPortion(
              unit: HouseholdPortionUnit.bowl,
              quantity: 1,
              size: HouseholdPortionSize.medium,
            ),
          ),
        ],
      );

      final ready = await client.confirmAnalysis('analysis-1', confirmation);

      expect(
        captured.uri.toString(),
        'https://backend.test/api/food-analyses/analysis-1/confirmations',
      );
      expect(captured.data, confirmation.toJson());
      expect(captured.contentType, Headers.jsonContentType);
      expect(ready.status, FoodAnalysisStatus.ready);
    });

    test('preserves the canonical nested API error', () async {
      final adapter = _StubAdapter((options, _, __) async {
        return _jsonResponse({
          'error': {
            'code': 'INVALID_CONFIRMATION',
            'message': 'Xác nhận dinh dưỡng không hợp lệ.',
            'details': {'field': 'components.0.portion'},
          },
        }, 400);
      });
      final client = _client(adapter);

      await expectLater(
        client.confirmAnalysis(
          'analysis-1',
          MealConfirmation(nameVi: 'Cơm', components: []),
        ),
        throwsA(
          isA<FoodAnalysisApiException>()
              .having((error) => error.code, 'code', 'INVALID_CONFIRMATION')
              .having(
                (error) => error.message,
                'message',
                'Xác nhận dinh dưỡng không hợp lệ.',
              )
              .having(
            (error) => error.details,
            'details',
            {'field': 'components.0.portion'},
          ),
        ),
      );
    });

    test('maps Dio timeouts to ANALYSIS_UNAVAILABLE', () async {
      final adapter = _StubAdapter((options, _, __) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });
      final client = _client(adapter);

      await expectLater(
        client.startPhotoAnalysis(_upload('meal.jpg')),
        throwsA(
          isA<FoodAnalysisApiException>().having(
            (error) => error.code,
            'code',
            'ANALYSIS_UNAVAILABLE',
          ),
        ),
      );
    });

    test('cancelPending cancels active photo calls', () async {
      final started = Completer<void>();
      var adapterObservedCancellation = false;
      final adapter = _StubAdapter((options, _, cancelFuture) async {
        started.complete();
        await cancelFuture;
        adapterObservedCancellation = true;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        );
      });
      final client = _client(adapter);

      final pending = client.startPhotoAnalysis(_upload('meal.jpg'));
      await started.future;
      client.cancelPending();

      await expectLater(pending, throwsA(isA<FoodAnalysisApiException>()));
      expect(adapterObservedCancellation, isTrue);
    });

    test('legacy barcode and image methods remain callable', () {
      final FoodAnalysisClient client = _client(
        _StubAdapter((_, __, ___) async => _jsonResponse({}, 200)),
      );

      final Future<ScanResult?> Function(Uint8List) analyze = client.analyze;
      final Future<ScanResult?> Function(String) scanBarcode =
          client.scanBarcode;
      final Future<bool> Function(String, ScanResult) registerBarcode =
          client.registerBarcode;

      expect(analyze, isA<Function>());
      expect(scanBarcode, isA<Function>());
      expect(registerBarcode, isA<Function>());
    });
  });
}

DioFoodAnalysisClient _client(HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return DioFoodAnalysisClient(
    dio: dio,
    endpointProvider: () => 'https://backend.test',
  );
}

PreparedUpload _upload(String filename) {
  return PreparedUpload(
    bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
    mimeType: filename.endsWith('.webp') ? 'image/webp' : 'image/jpeg',
    filename: filename,
  );
}

Map<String, Object?> _mealReviewJson() => {
      'analysisId': 'analysis-1',
      'imageType': 'MEAL',
      'status': 'NEEDS_CONFIRMATION',
      'components': [
        {
          'id': 'component-1',
          'nameVi': 'Cơm trắng',
          'matchedFoodId': 'white-rice',
          'confidence': 0.91,
          'isMajor': true,
          'requiresManualPortion': false,
          'suggestedPortion': {
            'kind': 'HOUSEHOLD',
            'unit': 'BOWL',
            'quantity': 1,
            'size': 'MEDIUM',
          },
        },
      ],
      'labelFacts': null,
      'confidence': 0.82,
      'uncertaintyReasons': ['HIDDEN_OIL'],
      'expiresAt': '2026-07-20T10:15:00.000Z',
    };

Map<String, Object?> _labelReviewJson() => {
      'analysisId': 'analysis-2',
      'imageType': 'NUTRITION_LABEL',
      'status': 'NEEDS_CONFIRMATION',
      'components': null,
      'labelFacts': {
        'nameVi': 'Tên sản phẩm',
        'basis': 'PER_100G',
        'facts': {
          'calories': 498,
          'proteinGrams': 4.4,
          'carbsGrams': 49.8,
          'fatGrams': 31.1,
        },
        'servingSizeGrams': null,
        'servingsPerContainer': null,
        'netWeightGrams': 57,
        'confidence': 0.94,
        'missingFields': <String>[],
      },
      'confidence': 0.94,
      'uncertaintyReasons': <String>[],
      'expiresAt': '2026-07-20T10:15:00.000Z',
    };

Map<String, Object?> _unknownReviewJson() => {
      'analysisId': 'analysis-3',
      'imageType': 'UNKNOWN',
      'status': 'UNRECOGNIZED',
      'components': null,
      'labelFacts': null,
      'confidence': 0.2,
      'uncertaintyReasons': <String>[],
      'expiresAt': '2026-07-20T10:15:00.000Z',
    };

Map<String, Object?> _readyJson() => {
      'analysisId': 'analysis-1',
      'imageType': 'MEAL',
      'status': 'READY',
      'nameVi': 'Cơm với ức gà',
      'estimate': <String, Object?>{
        'calories': <String, Object?>{'min': 430, 'mid': 505, 'max': 580},
        'proteinGrams': <String, Object?>{'min': 34, 'mid': 39, 'max': 44},
        'carbsGrams': <String, Object?>{'min': 48, 'mid': 55, 'max': 62},
        'fatGrams': <String, Object?>{'min': 8, 'mid': 12, 'max': 16},
      },
      'confidenceLevel': 'MEDIUM',
      'uncertaintyReasons': ['HIDDEN_OIL'],
      'calculationSummary':
          '1 bát cơm vừa + 1 phần ức gà vừa; khoảng được nới rộng do dầu.',
    };

ResponseBody _jsonResponse(Object? body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _AdapterHandler = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

final class _StubAdapter implements HttpClientAdapter {
  final _AdapterHandler handler;

  _StubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
