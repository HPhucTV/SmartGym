import 'dart:typed_data';

enum FoodImageType {
  meal,
  nutritionLabel,
  unknown;

  static FoodImageType fromWire(Object? value) => switch (value) {
        'MEAL' => meal,
        'NUTRITION_LABEL' => nutritionLabel,
        'UNKNOWN' => unknown,
        _ => throw FoodAnalysisFormatException(
            'imageType must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        meal => 'MEAL',
        nutritionLabel => 'NUTRITION_LABEL',
        unknown => 'UNKNOWN',
      };
}

enum FoodAnalysisStatus {
  needsSecondImage,
  needsConfirmation,
  ready,
  unrecognized;

  static FoodAnalysisStatus fromWire(Object? value) => switch (value) {
        'NEEDS_SECOND_IMAGE' => needsSecondImage,
        'NEEDS_CONFIRMATION' => needsConfirmation,
        'READY' => ready,
        'UNRECOGNIZED' => unrecognized,
        _ => throw FoodAnalysisFormatException(
            'status must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        needsSecondImage => 'NEEDS_SECOND_IMAGE',
        needsConfirmation => 'NEEDS_CONFIRMATION',
        ready => 'READY',
        unrecognized => 'UNRECOGNIZED',
      };
}

enum AnalysisConfidenceLevel {
  high,
  medium,
  low;

  static AnalysisConfidenceLevel fromWire(Object? value) => switch (value) {
        'HIGH' => high,
        'MEDIUM' => medium,
        'LOW' => low,
        _ => throw FoodAnalysisFormatException(
            'confidenceLevel must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        high => 'HIGH',
        medium => 'MEDIUM',
        low => 'LOW',
      };
}

enum FoodPortionKind {
  household,
  grams;

  static FoodPortionKind fromWire(Object? value) => switch (value) {
        'HOUSEHOLD' => household,
        'GRAMS' => grams,
        _ => throw FoodAnalysisFormatException(
            'portion.kind must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        household => 'HOUSEHOLD',
        grams => 'GRAMS',
      };
}

enum HouseholdPortionUnit {
  bowl,
  piece,
  spoon,
  serving;

  static HouseholdPortionUnit fromWire(Object? value) => switch (value) {
        'BOWL' => bowl,
        'PIECE' => piece,
        'SPOON' => spoon,
        'SERVING' => serving,
        _ => throw FoodAnalysisFormatException(
            'portion.unit must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        bowl => 'BOWL',
        piece => 'PIECE',
        spoon => 'SPOON',
        serving => 'SERVING',
      };
}

enum HouseholdPortionSize {
  small,
  medium,
  large;

  static HouseholdPortionSize fromWire(Object? value) => switch (value) {
        'SMALL' => small,
        'MEDIUM' => medium,
        'LARGE' => large,
        _ => throw FoodAnalysisFormatException(
            'portion.size must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        small => 'SMALL',
        medium => 'MEDIUM',
        large => 'LARGE',
      };
}

enum LabelBasis {
  per100g,
  perServing,
  unknown;

  static LabelBasis fromWire(Object? value) => switch (value) {
        'PER_100G' => per100g,
        'PER_SERVING' => perServing,
        'UNKNOWN' => unknown,
        _ => throw FoodAnalysisFormatException(
            'label basis must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        per100g => 'PER_100G',
        perServing => 'PER_SERVING',
        unknown => 'UNKNOWN',
      };
}

enum LabelConsumedKind {
  grams,
  servings;

  static LabelConsumedKind fromWire(Object? value) => switch (value) {
        'GRAMS' => grams,
        'SERVINGS' => servings,
        _ => throw FoodAnalysisFormatException(
            'consumed.kind must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        grams => 'GRAMS',
        servings => 'SERVINGS',
      };
}

enum FoodNutritionSource {
  manual,
  cameraAnalysis;

  static FoodNutritionSource fromWire(Object? value) => switch (value) {
        'MANUAL' => manual,
        'CAMERA_ANALYSIS' => cameraAnalysis,
        _ => throw FoodAnalysisFormatException(
            'source must be a canonical value.',
          ),
      };

  String get wireValue => switch (this) {
        manual => 'MANUAL',
        cameraAnalysis => 'CAMERA_ANALYSIS',
      };
}

enum LabelMissingField {
  basis,
  calories,
  proteinGrams,
  carbsGrams,
  fatGrams,
  servingSizeGrams,
  servingsPerContainer,
  netWeightGrams,
  consumedAmount;

  static LabelMissingField fromWire(Object? value) => switch (value) {
        'BASIS' => basis,
        'CALORIES' => calories,
        'PROTEIN_GRAMS' => proteinGrams,
        'CARBS_GRAMS' => carbsGrams,
        'FAT_GRAMS' => fatGrams,
        'SERVING_SIZE_GRAMS' => servingSizeGrams,
        'SERVINGS_PER_CONTAINER' => servingsPerContainer,
        'NET_WEIGHT_GRAMS' => netWeightGrams,
        'CONSUMED_AMOUNT' => consumedAmount,
        _ => throw FoodAnalysisFormatException(
            'missingFields contains an unknown value.',
          ),
      };
}

final class PreparedUpload {
  final Uint8List bytes;
  final String mimeType;
  final String filename;

  const PreparedUpload({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });
}

final class NutritionRange {
  final double min;
  final double mid;
  final double max;

  const NutritionRange({
    required this.min,
    required this.mid,
    required this.max,
  }) : assert(min <= mid && mid <= max);

  factory NutritionRange.fromJson(Object? value) {
    final json = _jsonMap(value, 'nutrition range');
    final min = _finiteNonNegative(json['min'], 'range.min');
    final mid = _finiteNonNegative(json['mid'], 'range.mid');
    final max = _finiteNonNegative(json['max'], 'range.max');
    if (min > mid || mid > max) {
      throw FoodAnalysisFormatException(
        'Nutrition range must satisfy min <= mid <= max.',
      );
    }
    return NutritionRange(min: min, mid: mid, max: max);
  }

  Map<String, Object?> toJson() => {'min': min, 'mid': mid, 'max': max};
}

sealed class FoodPortion {
  const FoodPortion();

  factory FoodPortion.fromJson(Object? value) {
    final json = _jsonMap(value, 'portion');
    return switch (FoodPortionKind.fromWire(json['kind'])) {
      FoodPortionKind.household => HouseholdPortion.fromJson(json),
      FoodPortionKind.grams => GramPortion.fromJson(json),
    };
  }

  Map<String, Object?> toJson();
}

final class HouseholdPortion extends FoodPortion {
  final HouseholdPortionUnit unit;
  final double quantity;
  final HouseholdPortionSize size;

  const HouseholdPortion({
    required this.unit,
    required this.quantity,
    required this.size,
  }) : assert(quantity > 0 && quantity <= 20);

  factory HouseholdPortion.fromJson(Object? value) {
    final json = _jsonMap(value, 'household portion');
    if (FoodPortionKind.fromWire(json['kind']) != FoodPortionKind.household) {
      throw FoodAnalysisFormatException(
        'Household portion kind must be HOUSEHOLD.',
      );
    }
    final quantity = _finitePositive(json['quantity'], 'portion.quantity');
    if (quantity > 20) {
      throw FoodAnalysisFormatException(
        'portion.quantity exceeds the supported limit.',
      );
    }
    return HouseholdPortion(
      unit: HouseholdPortionUnit.fromWire(json['unit']),
      quantity: quantity,
      size: HouseholdPortionSize.fromWire(json['size']),
    );
  }

  @override
  Map<String, Object?> toJson() => {
        'kind': FoodPortionKind.household.wireValue,
        'unit': unit.wireValue,
        'quantity': quantity,
        'size': size.wireValue,
      };
}

final class GramPortion extends FoodPortion {
  final double grams;

  const GramPortion({required this.grams}) : assert(grams > 0 && grams <= 5000);

  factory GramPortion.fromJson(Object? value) {
    final json = _jsonMap(value, 'gram portion');
    if (FoodPortionKind.fromWire(json['kind']) != FoodPortionKind.grams) {
      throw FoodAnalysisFormatException('Gram portion kind must be GRAMS.');
    }
    final grams = _finitePositive(json['grams'], 'portion.grams');
    if (grams > 5000) {
      throw FoodAnalysisFormatException(
        'portion.grams exceeds the supported limit.',
      );
    }
    return GramPortion(grams: grams);
  }

  @override
  Map<String, Object?> toJson() => {
        'kind': FoodPortionKind.grams.wireValue,
        'grams': grams,
      };
}

final class NutrientFacts {
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const NutrientFacts({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  }) : assert(
          calories >= 0 &&
              proteinGrams >= 0 &&
              carbsGrams >= 0 &&
              fatGrams >= 0,
        );

  factory NutrientFacts.fromJson(Object? value) {
    final json = _jsonMap(value, 'nutrient facts');
    return NutrientFacts(
      calories: _finiteNonNegative(json['calories'], 'facts.calories'),
      proteinGrams:
          _finiteNonNegative(json['proteinGrams'], 'facts.proteinGrams'),
      carbsGrams: _finiteNonNegative(json['carbsGrams'], 'facts.carbsGrams'),
      fatGrams: _finiteNonNegative(json['fatGrams'], 'facts.fatGrams'),
    );
  }

  Map<String, Object?> toJson() => {
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
      };
}

final class ObservedNutrientFacts {
  final double? calories;
  final double? proteinGrams;
  final double? carbsGrams;
  final double? fatGrams;

  const ObservedNutrientFacts({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  factory ObservedNutrientFacts.fromJson(Object? value) {
    final json = _jsonMap(value, 'observed nutrient facts');
    return ObservedNutrientFacts(
      calories: _nullableFiniteNonNegative(
        json['calories'],
        'facts.calories',
      ),
      proteinGrams: _nullableFiniteNonNegative(
        json['proteinGrams'],
        'facts.proteinGrams',
      ),
      carbsGrams: _nullableFiniteNonNegative(
        json['carbsGrams'],
        'facts.carbsGrams',
      ),
      fatGrams: _nullableFiniteNonNegative(
        json['fatGrams'],
        'facts.fatGrams',
      ),
    );
  }
}

final class ObservedFoodComponent {
  final String id;
  final String nameVi;
  final String? matchedFoodId;
  final double confidence;
  final bool isMajor;
  final bool requiresManualPortion;
  final FoodPortion? suggestedPortion;

  const ObservedFoodComponent({
    required this.id,
    required this.nameVi,
    required this.matchedFoodId,
    required this.confidence,
    required this.isMajor,
    required this.requiresManualPortion,
    required this.suggestedPortion,
  });

  factory ObservedFoodComponent.fromJson(Object? value) {
    final json = _jsonMap(value, 'food component');
    return ObservedFoodComponent(
      id: _requiredText(json['id'], 'component.id', maxLength: 100),
      nameVi: _requiredText(json['nameVi'], 'component.nameVi', maxLength: 160),
      matchedFoodId: _nullableRequiredText(
        json['matchedFoodId'],
        'component.matchedFoodId',
        maxLength: 100,
      ),
      confidence: _confidence(json['confidence'], 'component.confidence'),
      isMajor: _requiredBool(json['isMajor'], 'component.isMajor'),
      requiresManualPortion: _requiredBool(
        json['requiresManualPortion'],
        'component.requiresManualPortion',
      ),
      suggestedPortion: json['suggestedPortion'] == null
          ? null
          : FoodPortion.fromJson(json['suggestedPortion']),
    );
  }
}

final class ObservedLabelFacts {
  final String nameVi;
  final LabelBasis basis;
  final ObservedNutrientFacts facts;
  final double? servingSizeGrams;
  final double? servingsPerContainer;
  final double? netWeightGrams;
  final double confidence;
  final List<LabelMissingField> missingFields;

  ObservedLabelFacts({
    required this.nameVi,
    required this.basis,
    required this.facts,
    required this.servingSizeGrams,
    required this.servingsPerContainer,
    required this.netWeightGrams,
    required this.confidence,
    required List<LabelMissingField> missingFields,
  }) : missingFields = List.unmodifiable(missingFields);

  factory ObservedLabelFacts.fromJson(Object? value) {
    final json = _jsonMap(value, 'label facts');
    final missingFields = _jsonList(
      json['missingFields'],
      'labelFacts.missingFields',
    ).map(LabelMissingField.fromWire);
    return ObservedLabelFacts(
      nameVi: _requiredText(
        json['nameVi'],
        'labelFacts.nameVi',
        maxLength: 160,
      ),
      basis: LabelBasis.fromWire(json['basis']),
      facts: ObservedNutrientFacts.fromJson(json['facts']),
      servingSizeGrams: _nullableFinitePositive(
        json['servingSizeGrams'],
        'labelFacts.servingSizeGrams',
      ),
      servingsPerContainer: _nullableFinitePositive(
        json['servingsPerContainer'],
        'labelFacts.servingsPerContainer',
      ),
      netWeightGrams: _nullableFinitePositive(
        json['netWeightGrams'],
        'labelFacts.netWeightGrams',
      ),
      confidence: _confidence(
        json['confidence'],
        'labelFacts.confidence',
      ),
      missingFields: missingFields.toList(growable: false),
    );
  }
}

final class FoodAnalysisReview {
  final String analysisId;
  final FoodImageType imageType;
  final FoodAnalysisStatus status;
  final List<ObservedFoodComponent>? components;
  final ObservedLabelFacts? labelFacts;
  final double confidence;
  final List<String> uncertaintyReasons;
  final DateTime expiresAt;

  FoodAnalysisReview._({
    required this.analysisId,
    required this.imageType,
    required this.status,
    required List<ObservedFoodComponent>? components,
    required this.labelFacts,
    required this.confidence,
    required List<String> uncertaintyReasons,
    required this.expiresAt,
  })  : components = components == null ? null : List.unmodifiable(components),
        uncertaintyReasons = List.unmodifiable(uncertaintyReasons);

  factory FoodAnalysisReview.fromJson(Object? value) {
    final json = _jsonMap(value, 'food analysis review');
    final imageType = FoodImageType.fromWire(json['imageType']);
    final status = FoodAnalysisStatus.fromWire(json['status']);
    if (status == FoodAnalysisStatus.ready) {
      throw FoodAnalysisFormatException(
        'A review response cannot have READY status.',
      );
    }

    List<ObservedFoodComponent>? components;
    ObservedLabelFacts? labelFacts;
    switch (imageType) {
      case FoodImageType.meal:
        final values = _jsonList(json['components'], 'components');
        if (values.isEmpty || json['labelFacts'] != null) {
          throw FoodAnalysisFormatException(
            'MEAL requires components and null labelFacts.',
          );
        }
        components =
            values.map(ObservedFoodComponent.fromJson).toList(growable: false);
        if (status == FoodAnalysisStatus.unrecognized) {
          throw FoodAnalysisFormatException(
            'MEAL cannot have UNRECOGNIZED status.',
          );
        }
      case FoodImageType.nutritionLabel:
        if (json['components'] != null || json['labelFacts'] == null) {
          throw FoodAnalysisFormatException(
            'NUTRITION_LABEL requires labelFacts and null components.',
          );
        }
        labelFacts = ObservedLabelFacts.fromJson(json['labelFacts']);
        if (status == FoodAnalysisStatus.unrecognized) {
          throw FoodAnalysisFormatException(
            'NUTRITION_LABEL cannot have UNRECOGNIZED status.',
          );
        }
      case FoodImageType.unknown:
        if (json['components'] != null ||
            json['labelFacts'] != null ||
            status != FoodAnalysisStatus.unrecognized) {
          throw FoodAnalysisFormatException(
            'UNKNOWN requires UNRECOGNIZED and null observations.',
          );
        }
    }

    return FoodAnalysisReview._(
      analysisId: _requiredText(
        json['analysisId'],
        'analysisId',
        maxLength: 200,
      ),
      imageType: imageType,
      status: status,
      components: components,
      labelFacts: labelFacts,
      confidence: _confidence(json['confidence'], 'confidence'),
      uncertaintyReasons: _stringList(
        json['uncertaintyReasons'],
        'uncertaintyReasons',
        maxItems: 20,
        maxItemLength: 240,
      ),
      expiresAt: _isoDateTime(json['expiresAt'], 'expiresAt'),
    );
  }
}

sealed class FoodAnalysisConfirmation {
  const FoodAnalysisConfirmation();

  Map<String, Object?> toJson();
}

final class ConfirmedFoodComponent {
  final String observationId;
  final String? foodId;
  final String nameVi;
  final FoodPortion portion;

  const ConfirmedFoodComponent({
    required this.observationId,
    required this.foodId,
    required this.nameVi,
    required this.portion,
  });

  Map<String, Object?> toJson() => {
        'observationId': observationId,
        if (foodId != null) 'foodId': foodId,
        'nameVi': nameVi,
        'portion': portion.toJson(),
      };
}

final class MealConfirmation extends FoodAnalysisConfirmation {
  final String nameVi;
  final List<ConfirmedFoodComponent> components;

  MealConfirmation({
    required this.nameVi,
    required List<ConfirmedFoodComponent> components,
  }) : components = List.unmodifiable(components);

  @override
  Map<String, Object?> toJson() => {
        'kind': FoodImageType.meal.wireValue,
        'nameVi': nameVi,
        'components':
            components.map((component) => component.toJson()).toList(),
      };
}

final class LabelConsumedAmount {
  final LabelConsumedKind kind;
  final double amount;

  const LabelConsumedAmount({
    required this.kind,
    required this.amount,
  }) : assert(amount > 0);

  Map<String, Object?> toJson() => {
        'kind': kind.wireValue,
        'amount': amount,
      };
}

final class LabelConfirmation extends FoodAnalysisConfirmation {
  final String nameVi;
  final LabelBasis basis;
  final NutrientFacts facts;
  final double? servingSizeGrams;
  final LabelConsumedAmount consumed;

  const LabelConfirmation({
    required this.nameVi,
    required this.basis,
    required this.facts,
    required this.servingSizeGrams,
    required this.consumed,
  });

  @override
  Map<String, Object?> toJson() => {
        'kind': FoodImageType.nutritionLabel.wireValue,
        'nameVi': nameVi,
        'basis': basis.wireValue,
        'facts': facts.toJson(),
        if (servingSizeGrams != null) 'servingSizeGrams': servingSizeGrams,
        'consumed': consumed.toJson(),
      };
}

final class NutritionEstimate {
  final NutritionRange calories;
  final NutritionRange proteinGrams;
  final NutritionRange carbsGrams;
  final NutritionRange fatGrams;

  const NutritionEstimate({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  factory NutritionEstimate.fromJson(Object? value) {
    final json = _jsonMap(value, 'nutrition estimate');
    return NutritionEstimate(
      calories: NutritionRange.fromJson(json['calories']),
      proteinGrams: NutritionRange.fromJson(json['proteinGrams']),
      carbsGrams: NutritionRange.fromJson(json['carbsGrams']),
      fatGrams: NutritionRange.fromJson(json['fatGrams']),
    );
  }
}

final class FoodAnalysisReady {
  final String analysisId;
  final FoodImageType imageType;
  final FoodAnalysisStatus status;
  final String nameVi;
  final NutritionEstimate estimate;
  final AnalysisConfidenceLevel confidenceLevel;
  final List<String> uncertaintyReasons;
  final String calculationSummary;

  FoodAnalysisReady._({
    required this.analysisId,
    required this.imageType,
    required this.status,
    required this.nameVi,
    required this.estimate,
    required this.confidenceLevel,
    required List<String> uncertaintyReasons,
    required this.calculationSummary,
  }) : uncertaintyReasons = List.unmodifiable(uncertaintyReasons);

  factory FoodAnalysisReady.fromJson(Object? value) {
    final json = _jsonMap(value, 'ready food analysis');
    final status = FoodAnalysisStatus.fromWire(json['status']);
    final imageType = FoodImageType.fromWire(json['imageType']);
    if (status != FoodAnalysisStatus.ready ||
        imageType == FoodImageType.unknown) {
      throw FoodAnalysisFormatException(
        'Ready response requires READY and a recognized image type.',
      );
    }
    return FoodAnalysisReady._(
      analysisId: _requiredText(
        json['analysisId'],
        'analysisId',
        maxLength: 200,
      ),
      imageType: imageType,
      status: status,
      nameVi: _requiredText(json['nameVi'], 'nameVi', maxLength: 160),
      estimate: NutritionEstimate.fromJson(json['estimate']),
      confidenceLevel:
          AnalysisConfidenceLevel.fromWire(json['confidenceLevel']),
      uncertaintyReasons: _stringList(
        json['uncertaintyReasons'],
        'uncertaintyReasons',
        maxItems: 20,
        maxItemLength: 240,
      ),
      calculationSummary: _requiredText(
        json['calculationSummary'],
        'calculationSummary',
        maxLength: 1000,
      ),
    );
  }
}

final class FoodAnalysisApiException implements Exception {
  final String code;
  final String message;
  final Map<String, Object?> details;

  FoodAnalysisApiException({
    required this.code,
    required this.message,
    Map<String, Object?> details = const {},
  }) : details = Map.unmodifiable(details);

  @override
  String toString() => 'FoodAnalysisApiException($code): $message';
}

final class FoodAnalysisFormatException implements Exception {
  final String message;

  const FoodAnalysisFormatException(this.message);

  @override
  String toString() => 'FoodAnalysisFormatException: $message';
}

Map<String, Object?> _jsonMap(Object? value, String field) {
  if (value is! Map) {
    throw FoodAnalysisFormatException('$field must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FoodAnalysisFormatException('$field contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _jsonList(Object? value, String field) {
  if (value is! List) {
    throw FoodAnalysisFormatException('$field must be a JSON array.');
  }
  return List<Object?>.from(value);
}

List<String> _stringList(
  Object? value,
  String field, {
  required int maxItems,
  required int maxItemLength,
}) {
  final values = _jsonList(value, field);
  if (values.length > maxItems) {
    throw FoodAnalysisFormatException('$field has too many values.');
  }
  return values
      .map(
        (item) => _requiredText(
          item,
          field,
          maxLength: maxItemLength,
        ),
      )
      .toList(growable: false);
}

String _requiredText(
  Object? value,
  String field, {
  required int maxLength,
}) {
  if (value is! String || value.trim().isEmpty || value.length > maxLength) {
    throw FoodAnalysisFormatException(
      '$field must be a non-empty bounded string.',
    );
  }
  return value;
}

String? _nullableRequiredText(
  Object? value,
  String field, {
  required int maxLength,
}) {
  if (value == null) return null;
  return _requiredText(value, field, maxLength: maxLength);
}

bool _requiredBool(Object? value, String field) {
  if (value is! bool) {
    throw FoodAnalysisFormatException('$field must be a boolean.');
  }
  return value;
}

double _finiteNonNegative(Object? value, String field) {
  if (value is! num || !value.isFinite || value < 0) {
    throw FoodAnalysisFormatException(
      '$field must be a finite non-negative number.',
    );
  }
  return value.toDouble();
}

double _finitePositive(Object? value, String field) {
  final parsed = _finiteNonNegative(value, field);
  if (parsed <= 0) {
    throw FoodAnalysisFormatException('$field must be positive.');
  }
  return parsed;
}

double? _nullableFiniteNonNegative(Object? value, String field) {
  if (value == null) return null;
  return _finiteNonNegative(value, field);
}

double? _nullableFinitePositive(Object? value, String field) {
  if (value == null) return null;
  return _finitePositive(value, field);
}

double _confidence(Object? value, String field) {
  final parsed = _finiteNonNegative(value, field);
  if (parsed > 1) {
    throw FoodAnalysisFormatException('$field must be between 0 and 1.');
  }
  return parsed;
}

DateTime _isoDateTime(Object? value, String field) {
  final text = value is String ? value : null;
  final match = text != null
      ? RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](\d{2}):(\d{2}))$',
        ).firstMatch(text)
      : null;
  if (match == null) {
    throw FoodAnalysisFormatException('$field must be an ISO timestamp.');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  final offsetHour = match.group(7) == null ? 0 : int.parse(match.group(7)!);
  final offsetMinute = match.group(8) == null ? 0 : int.parse(match.group(8)!);
  final monthIsValid = month >= 1 && month <= 12;
  final maxDay = monthIsValid ? DateTime.utc(year, month + 1, 0).day : 0;
  if (!monthIsValid ||
      day < 1 ||
      day > maxDay ||
      hour > 23 ||
      minute > 59 ||
      second > 59 ||
      offsetHour > 23 ||
      offsetMinute > 59) {
    throw FoodAnalysisFormatException('$field must be an ISO timestamp.');
  }

  final parsed = DateTime.tryParse(text!);
  if (parsed == null) {
    throw FoodAnalysisFormatException('$field must be an ISO timestamp.');
  }
  return parsed;
}
