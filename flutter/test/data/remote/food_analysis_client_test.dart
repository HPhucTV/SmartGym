import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/model/food_photo_analysis_models.dart';
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

  group('known food capability catalog', () {
    test('strictly parses bounded public capability entries', () {
      final foods = KnownFoodOption.listFromJson({
        'foods': [
          {
            'foodId': 'white-rice',
            'nameVi': 'Cơm trắng',
            'supportsGrams': true,
            'portionOptions': [
              {
                'unit': 'BOWL',
                'sizes': ['SMALL', 'MEDIUM', 'LARGE'],
              }
            ],
          }
        ],
      });

      expect(foods.single.foodId, 'white-rice');
      expect(foods.single.supportsGrams, isTrue);
      expect(
          foods.single.portionOptions.single.unit, HouseholdPortionUnit.bowl);
      expect(foods.single.portionOptions.single.sizes,
          HouseholdPortionSize.values);
    });

    test(
        'rejects unknown keys, duplicate ids, duplicate units and oversized catalogs',
        () {
      Map<String, Object?> food(String id) => {
            'foodId': id,
            'nameVi': 'Món $id',
            'supportsGrams': true,
            'portionOptions': <Object?>[],
          };
      final invalid = <Object?>[
        {
          'foods': [food('one')..['nutrientsPer100g'] = {}],
        },
        {
          'foods': [food('same'), food('same')],
        },
        {
          'foods': [
            {
              ...food('one'),
              'portionOptions': [
                {
                  'unit': 'BOWL',
                  'sizes': ['MEDIUM']
                },
                {
                  'unit': 'BOWL',
                  'sizes': ['SMALL']
                },
              ],
            }
          ],
        },
        {'foods': List.generate(101, (index) => food('food-$index'))},
      ];
      for (final value in invalid) {
        expect(() => KnownFoodOption.listFromJson(value),
            throwsA(isA<FoodAnalysisFormatException>()));
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

    test('rejects duplicate provider component identifiers', () {
      final json = _mealReviewJson();
      final component = Map<String, Object?>.from(
        (json['components'] as List).single as Map<String, Object?>,
      );
      json['components'] = [
        component,
        {...component, 'nameVi': 'Trứng luộc'},
      ];

      expect(
        () => FoodAnalysisReview.fromJson(json),
        throwsA(isA<FoodAnalysisFormatException>()),
      );
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

    test('rejects extra keys at every parsed object boundary', () {
      final cases = <Map<String, Object?> Function()>[
        () => _mealReviewJson()..['extra'] = true,
        () {
          final json = _mealReviewJson();
          _mealComponent(json)['extra'] = true;
          return json;
        },
        () {
          final json = _mealReviewJson();
          _suggestedPortion(json)['extra'] = true;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['extra'] = true;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _observedFacts(json)['extra'] = true;
          return json;
        },
        () => _readyJson()..['extra'] = true,
        () {
          final json = _readyJson();
          _estimate(json)['extra'] = true;
          return json;
        },
        () {
          final json = _readyJson();
          _range(json, 'calories')['extra'] = true;
          return json;
        },
      ];

      for (final createJson in cases) {
        expect(
          () {
            final json = createJson();
            if (json['status'] == 'READY') {
              FoodAnalysisReady.fromJson(json);
            } else {
              FoodAnalysisReview.fromJson(json);
            }
          },
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('requires every canonical nullable key to be present', () {
      final cases = <Map<String, Object?> Function()>[
        () => _mealReviewJson()..remove('labelFacts'),
        () => _labelReviewJson()..remove('components'),
        () => _unknownReviewJson()..remove('labelFacts'),
        () {
          final json = _mealReviewJson();
          _mealComponent(json).remove('matchedFoodId');
          return json;
        },
        () {
          final json = _mealReviewJson();
          _mealComponent(json).remove('suggestedPortion');
          return json;
        },
        for (final key in [
          'servingSizeGrams',
          'servingsPerContainer',
          'netWeightGrams',
        ])
          () {
            final json = _labelReviewJson();
            _labelFacts(json).remove(key);
            return json;
          },
        for (final key in [
          'calories',
          'proteinGrams',
          'carbsGrams',
          'fatGrams',
        ])
          () {
            final json = _labelReviewJson();
            _observedFacts(json).remove(key);
            return json;
          },
      ];

      for (final createJson in cases) {
        expect(
          () => FoodAnalysisReview.fromJson(createJson()),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('mirrors backend response limits', () {
      final cases = <Map<String, Object?> Function()>[
        () => _mealReviewJson()..['components'] = <Object?>[],
        () => _mealReviewJson()
          ..['components'] =
              List<Object?>.generate(21, (_) => _validMealComponent()),
        () {
          final json = _mealReviewJson();
          _mealComponent(json)['id'] = _text(101);
          return json;
        },
        () {
          final json = _mealReviewJson();
          _mealComponent(json)['nameVi'] = _text(161);
          return json;
        },
        () {
          final json = _mealReviewJson();
          _mealComponent(json)['matchedFoodId'] = _text(101);
          return json;
        },
        () {
          final json = _mealReviewJson();
          _suggestedPortion(json)['quantity'] = 20.01;
          return json;
        },
        () {
          final json = _mealReviewJson();
          _mealComponent(json)['suggestedPortion'] = {
            'kind': 'GRAMS',
            'grams': 5000.01,
          };
          return json;
        },
        () => _mealReviewJson()
          ..['uncertaintyReasons'] = [
            'HIDDEN_OIL',
            'SAUCE',
            'OVERLAP',
            'WEAK_DATABASE_MATCH',
            'HIDDEN_OIL',
          ],
        () => _mealReviewJson()..['uncertaintyReasons'] = ['UNBOUNDED_REASON'],
        () {
          final json = _labelReviewJson();
          _observedFacts(json)['calories'] = 1000.01;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _observedFacts(json)['proteinGrams'] = 100.01;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['servingSizeGrams'] = 5000.01;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['servingsPerContainer'] = 100.01;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['netWeightGrams'] = 5000.01;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['missingFields'] =
              List<String>.filled(10, 'CALORIES');
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['missingFields'] = ['RAW_PROVIDER_TEXT'];
          return json;
        },
      ];

      for (final createJson in cases) {
        expect(
          () => FoodAnalysisReview.fromJson(createJson()),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('enforces label missingFields consistency', () {
      final cases = <Map<String, Object?> Function()>[
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['basis'] = 'UNKNOWN';
          return json;
        },
        () {
          final json = _labelReviewJson();
          _observedFacts(json)['calories'] = null;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)
            ..['basis'] = 'PER_SERVING'
            ..['servingSizeGrams'] = null;
          return json;
        },
        () {
          final json = _labelReviewJson();
          _labelFacts(json)['netWeightGrams'] = null;
          return json;
        },
      ];

      for (final createJson in cases) {
        expect(
          () => FoodAnalysisReview.fromJson(createJson()),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }

      final validMissing = _labelReviewJson();
      _labelFacts(validMissing)
        ..['basis'] = 'UNKNOWN'
        ..['netWeightGrams'] = null
        ..['missingFields'] = ['BASIS', 'CONSUMED_AMOUNT'];
      expect(
          FoodAnalysisReview.fromJson(validMissing), isA<FoodAnalysisReview>());
    });

    test('rejects invalid discriminator and status combinations', () {
      final cases = [
        _mealReviewJson()..['status'] = 'UNRECOGNIZED',
        _labelReviewJson()..['status'] = 'UNRECOGNIZED',
        _unknownReviewJson()..['status'] = 'NEEDS_CONFIRMATION',
        _mealReviewJson()..['status'] = 'READY',
      ];

      for (final json in cases) {
        expect(
          () => FoodAnalysisReview.fromJson(json),
          throwsA(isA<FoodAnalysisFormatException>()),
        );
      }
    });

    test('requires label READY results to have no meal uncertainty codes', () {
      final json = _readyJson()
        ..['imageType'] = 'NUTRITION_LABEL'
        ..['uncertaintyReasons'] = ['HIDDEN_OIL'];

      expect(
        () => FoodAnalysisReady.fromJson(json),
        throwsA(isA<FoodAnalysisFormatException>()),
      );
    });

    test('does not invent limits absent from backend session responses', () {
      final review = _mealReviewJson()..['analysisId'] = _text(201);
      final ready = _readyJson()
        ..['analysisId'] = _text(201)
        ..['calculationSummary'] = _text(1001);

      expect(FoodAnalysisReview.fromJson(review), isA<FoodAnalysisReview>());
      expect(FoodAnalysisReady.fromJson(ready), isA<FoodAnalysisReady>());
    });
  });

  group('strict confirmation serialization', () {
    test('rejects portions the backend rejects with typed format errors', () {
      final cases = <Object? Function()>[
        () => HouseholdPortion(
              unit: HouseholdPortionUnit.bowl,
              quantity: double.nan,
              size: HouseholdPortionSize.medium,
            ),
        () => HouseholdPortion(
              unit: HouseholdPortionUnit.bowl,
              quantity: 0,
              size: HouseholdPortionSize.medium,
            ),
        () => HouseholdPortion(
              unit: HouseholdPortionUnit.bowl,
              quantity: 20.01,
              size: HouseholdPortionSize.medium,
            ),
        () => GramPortion(grams: double.infinity),
        () => GramPortion(grams: 0),
        () => GramPortion(grams: 5000.01),
      ];

      for (final create in cases) {
        expect(create, throwsA(isA<FoodAnalysisFormatException>()));
      }
    });

    test('rejects invalid meal confirmation fields and counts', () {
      final portion = HouseholdPortion(
        unit: HouseholdPortionUnit.bowl,
        quantity: 1,
        size: HouseholdPortionSize.medium,
      );
      final validComponent = ConfirmedFoodComponent(
        observationId: 'component-1',
        foodId: 'white-rice',
        nameVi: 'Cơm trắng',
        portion: portion,
      );
      final cases = <Object? Function()>[
        () => ConfirmedFoodComponent(
              observationId: '',
              foodId: 'white-rice',
              nameVi: 'Cơm',
              portion: portion,
            ),
        () => ConfirmedFoodComponent(
              observationId: _text(101),
              foodId: 'white-rice',
              nameVi: 'Cơm',
              portion: portion,
            ),
        () => ConfirmedFoodComponent(
              observationId: 'component-1',
              foodId: '',
              nameVi: 'Cơm',
              portion: portion,
            ),
        () => ConfirmedFoodComponent(
              observationId: 'component-1',
              foodId: 'white-rice',
              nameVi: _text(161),
              portion: portion,
            ),
        () => MealConfirmation(nameVi: '', components: [validComponent]),
        () => MealConfirmation(nameVi: 'Cơm', components: []),
        () => MealConfirmation(
              nameVi: 'Cơm',
              components: List.filled(21, validComponent),
            ),
      ];

      for (final create in cases) {
        expect(create, throwsA(isA<FoodAnalysisFormatException>()));
      }
    });

    test('rejects nutrient and label confirmation values outside schemas', () {
      final validFacts = _nutrientFacts();
      final grams = LabelConsumedAmount(
        kind: LabelConsumedKind.grams,
        amount: 57,
      );
      final servings = LabelConsumedAmount(
        kind: LabelConsumedKind.servings,
        amount: 1,
      );
      final cases = <Object? Function()>[
        () => NutrientFacts(
              calories: 1000.01,
              proteinGrams: 4,
              carbsGrams: 5,
              fatGrams: 6,
            ),
        () => NutrientFacts(
              calories: 100,
              proteinGrams: 100.01,
              carbsGrams: 5,
              fatGrams: 6,
            ),
        () => LabelConsumedAmount(
              kind: LabelConsumedKind.grams,
              amount: 5000.01,
            ),
        () => LabelConsumedAmount(
              kind: LabelConsumedKind.servings,
              amount: 20.01,
            ),
        () => LabelConsumedAmount(
              kind: LabelConsumedKind.grams,
              amount: double.nan,
            ),
        () => LabelConfirmation(
              nameVi: 'Nhãn',
              basis: LabelBasis.unknown,
              facts: validFacts,
              servingSizeGrams: null,
              consumed: grams,
            ),
        () => LabelConfirmation(
              nameVi: 'Nhãn',
              basis: LabelBasis.perServing,
              facts: validFacts,
              servingSizeGrams: null,
              consumed: servings,
            ),
        () => LabelConfirmation(
              nameVi: 'Nhãn',
              basis: LabelBasis.perServing,
              facts: validFacts,
              servingSizeGrams: 5000.01,
              consumed: servings,
            ),
        () => LabelConfirmation(
              nameVi: 'Nhãn',
              basis: LabelBasis.per100g,
              facts: validFacts,
              servingSizeGrams: null,
              consumed: servings,
            ),
      ];

      for (final create in cases) {
        expect(create, throwsA(isA<FoodAnalysisFormatException>()));
      }
    });

    test('serializes only backend-valid meal and label confirmations', () {
      final meal = MealConfirmation(
        nameVi: 'Cơm',
        components: [
          ConfirmedFoodComponent(
            observationId: 'component-1',
            foodId: null,
            nameVi: 'Cơm',
            portion: GramPortion(grams: 150),
          ),
        ],
      );
      final label = LabelConfirmation(
        nameVi: 'Sữa chua',
        basis: LabelBasis.perServing,
        facts: _nutrientFacts(),
        servingSizeGrams: 100,
        consumed: LabelConsumedAmount(
          kind: LabelConsumedKind.servings,
          amount: 1.5,
        ),
      );

      expect(meal.toJson()['kind'], 'MEAL');
      expect(
        (meal.toJson()['components'] as List).single,
        isNot(contains('foodId')),
      );
      expect(label.toJson(), {
        'kind': 'NUTRITION_LABEL',
        'nameVi': 'Sữa chua',
        'basis': 'PER_SERVING',
        'facts': <String, Object?>{
          'calories': 120.0,
          'proteinGrams': 5.0,
          'carbsGrams': 18.0,
          'fatGrams': 3.0,
        },
        'servingSizeGrams': 100.0,
        'consumed': {'kind': 'SERVINGS', 'amount': 1.5},
      });
    });

    test('NutritionRange validates direct construction without assertions', () {
      expect(
        () => NutritionRange(min: 2, mid: 1, max: 3),
        throwsA(isA<FoodAnalysisFormatException>()),
      );
      expect(
        () => NutritionRange(min: 0, mid: double.nan, max: 3),
        throwsA(isA<FoodAnalysisFormatException>()),
      );
    });
  });

  group('DioFoodAnalysisClient', () {
    test('listKnownFoods gets and strictly parses the public catalog',
        () async {
      late RequestOptions captured;
      final adapter = _StubAdapter((options, _, __) async {
        captured = options;
        return _jsonResponse({
          'foods': [
            {
              'foodId': 'white-rice',
              'nameVi': 'Cơm trắng',
              'supportsGrams': true,
              'portionOptions': [
                {
                  'unit': 'BOWL',
                  'sizes': ['SMALL', 'MEDIUM', 'LARGE'],
                }
              ],
            }
          ],
        }, 200);
      });

      final foods = await _client(adapter).listKnownFoods();

      expect(captured.method, 'GET');
      expect(captured.uri.toString(),
          'https://backend.test/api/food-analyses/foods');
      expect(foods.single.foodId, 'white-rice');
    });
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
            portion: HouseholdPortion(
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
            'details': {'observationId': 'component-1', 'field': 'portion'},
          },
        }, 400);
      });
      final client = _client(adapter);

      await expectLater(
        client.confirmAnalysis(
          'analysis-1',
          _mealConfirmation(),
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
            {'observationId': 'component-1', 'field': 'portion'},
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

    test('cancelPending exposes a distinct cancellation outcome', () async {
      final started = Completer<void>();
      final adapter = _StubAdapter((options, _, cancelFuture) async {
        started.complete();
        await cancelFuture;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        );
      });
      final client = _client(adapter);

      final pending = client.startPhotoAnalysis(_upload('meal.jpg'));
      await started.future;
      client.cancelPending();

      await expectLater(
        pending,
        throwsA(isA<FoodAnalysisCancelledException>()),
      );
    });

    test('cancelPending cancels every concurrent photo call and then clears',
        () async {
      var started = 0;
      final bothStarted = Completer<void>();
      final adapter = _StubAdapter((options, _, cancelFuture) async {
        started += 1;
        if (started == 2) bothStarted.complete();
        if (started <= 2) {
          await cancelFuture;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          );
        }
        return _jsonResponse(_mealReviewJson(), 201);
      });
      final client = _client(adapter);

      final first = client.startPhotoAnalysis(_upload('one.jpg'));
      final second = client.startPhotoAnalysis(_upload('two.jpg'));
      await bothStarted.future;
      client.cancelPending();

      await expectLater(
        Future.wait([first, second]),
        throwsA(isA<FoodAnalysisCancelledException>()),
      );
      expect(
        await client.startPhotoAnalysis(_upload('three.jpg')),
        isA<FoodAnalysisReview>(),
      );
    });

    test('PreparedUpload snapshots bytes and validates the upload boundary',
        () async {
      final callerBytes = Uint8List.fromList([11, 22, 33, 44, 55]);
      final upload = PreparedUpload(
        bytes: callerBytes,
        mimeType: 'image/jpeg',
        filename: 'meal.jpg',
      );
      callerBytes.fillRange(0, callerBytes.length, 99);
      final exposedBytes = upload.bytes;
      exposedBytes.fillRange(0, exposedBytes.length, 88);

      late List<int> requestBody;
      final adapter = _StubAdapter((_, requestStream, __) async {
        requestBody = [
          for (final chunk in await requestStream!.toList()) ...chunk,
        ];
        return _jsonResponse(_mealReviewJson(), 201);
      });
      final client = _client(adapter);
      final pending = client.startPhotoAnalysis(upload);
      exposedBytes.fillRange(0, exposedBytes.length, 77);
      await pending;

      expect(_containsSequence(requestBody, [11, 22, 33, 44, 55]), isTrue);
      expect(upload.bytes, [11, 22, 33, 44, 55]);

      final invalid = <Object? Function()>[
        () => PreparedUpload(
              bytes: Uint8List(0),
              mimeType: 'image/jpeg',
              filename: 'meal.jpg',
            ),
        () => PreparedUpload(
              bytes: Uint8List.fromList([1]),
              mimeType: 'image/gif',
              filename: 'meal.gif',
            ),
        () => PreparedUpload(
              bytes: Uint8List.fromList([1]),
              mimeType: 'image/jpeg',
              filename: ' ',
            ),
        () => PreparedUpload(
              bytes: Uint8List(5 * 1024 * 1024 + 1),
              mimeType: 'image/jpeg',
              filename: 'large.jpg',
            ),
      ];
      for (final create in invalid) {
        expect(create, throwsA(isA<FoodAnalysisFormatException>()));
      }
    });

    test('bounds and deep-freezes nested API error details', () async {
      final nested = <String, Object?>{
        'message': _text(200),
        'list': [
          {'secret': _text(200)},
          2,
          3,
          4,
          5,
        ],
        'nonFinite': double.infinity,
        'unsupported': Object(),
        'fifth': 'discarded',
      };
      final adapter = _StubAdapter((options, _, __) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {
              'error': {
                'code': 'INVALID_CONFIRMATION',
                'message': 'Xác nhận không hợp lệ.',
                'details': nested,
              },
            },
          ),
          type: DioExceptionType.badResponse,
        );
      });
      final client = _client(adapter);

      late FoodAnalysisApiException captured;
      try {
        await client.confirmAnalysis('analysis-1', _mealConfirmation());
        fail('Expected a typed API error.');
      } on FoodAnalysisApiException catch (error) {
        captured = error;
      }
      nested['message'] = 'mutated';
      (nested['list'] as List).clear();

      expect(captured.details, hasLength(3));
      expect(captured.details['message'], _text(120));
      expect(captured.details['list'], hasLength(4));
      expect(
        () => (captured.details['list'] as List).add('mutate'),
        throwsUnsupportedError,
      );
      expect(
        () => captured.details['new'] = 'mutate',
        throwsUnsupportedError,
      );
    });

  });
}

Map<String, Object?> _mealComponent(Map<String, Object?> review) {
  return (review['components'] as List).single as Map<String, Object?>;
}

Map<String, Object?> _suggestedPortion(Map<String, Object?> review) {
  return _mealComponent(review)['suggestedPortion'] as Map<String, Object?>;
}

Map<String, Object?> _labelFacts(Map<String, Object?> review) {
  return review['labelFacts'] as Map<String, Object?>;
}

Map<String, Object?> _observedFacts(Map<String, Object?> review) {
  return _labelFacts(review)['facts'] as Map<String, Object?>;
}

Map<String, Object?> _estimate(Map<String, Object?> ready) {
  return ready['estimate'] as Map<String, Object?>;
}

Map<String, Object?> _range(Map<String, Object?> ready, String nutrient) {
  return _estimate(ready)[nutrient] as Map<String, Object?>;
}

Map<String, Object?> _validMealComponent() => {
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
    };

NutrientFacts _nutrientFacts() => NutrientFacts(
      calories: 120,
      proteinGrams: 5,
      carbsGrams: 18,
      fatGrams: 3,
    );

MealConfirmation _mealConfirmation() => MealConfirmation(
      nameVi: 'Cơm',
      components: [
        ConfirmedFoodComponent(
          observationId: 'component-1',
          foodId: 'white-rice',
          nameVi: 'Cơm',
          portion: GramPortion(grams: 150),
        ),
      ],
    );

String _text(int length) => List.filled(length, 'x').join();

bool _containsSequence(List<int> source, List<int> sequence) {
  if (sequence.isEmpty) return true;
  for (var start = 0; start <= source.length - sequence.length; start += 1) {
    var matches = true;
    for (var index = 0; index < sequence.length; index += 1) {
      if (source[start + index] != sequence[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
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
        'facts': <String, Object?>{
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
