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

  String get wireValue => switch (this) {
        basis => 'BASIS',
        calories => 'CALORIES',
        proteinGrams => 'PROTEIN_GRAMS',
        carbsGrams => 'CARBS_GRAMS',
        fatGrams => 'FAT_GRAMS',
        servingSizeGrams => 'SERVING_SIZE_GRAMS',
        servingsPerContainer => 'SERVINGS_PER_CONTAINER',
        netWeightGrams => 'NET_WEIGHT_GRAMS',
        consumedAmount => 'CONSUMED_AMOUNT',
      };
}

enum FoodUncertaintyReason {
  hiddenOil,
  sauce,
  overlap,
  weakDatabaseMatch;

  static FoodUncertaintyReason fromWire(Object? value) => switch (value) {
        'HIDDEN_OIL' => hiddenOil,
        'SAUCE' => sauce,
        'OVERLAP' => overlap,
        'WEAK_DATABASE_MATCH' => weakDatabaseMatch,
        _ => throw FoodAnalysisFormatException(
            'uncertaintyReasons contains an unknown value.',
          ),
      };

  String get wireValue => switch (this) {
        hiddenOil => 'HIDDEN_OIL',
        sauce => 'SAUCE',
        overlap => 'OVERLAP',
        weakDatabaseMatch => 'WEAK_DATABASE_MATCH',
      };
}

final class KnownFoodPortionOption {
  final HouseholdPortionUnit unit;
  final List<HouseholdPortionSize> sizes;

  KnownFoodPortionOption._(
      {required this.unit, required List<HouseholdPortionSize> sizes})
      : sizes = List.unmodifiable(sizes);

  factory KnownFoodPortionOption.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'known food portion option',
      const {'unit', 'sizes'},
    );
    final unit = HouseholdPortionUnit.fromWire(json['unit']);
    final rawSizes = _jsonList(json['sizes'], 'knownFood.portionOptions.sizes');
    if (rawSizes.isEmpty ||
        rawSizes.length > HouseholdPortionSize.values.length) {
      throw const FoodAnalysisFormatException(
        'Known food portion sizes must contain 1 to 3 values.',
      );
    }
    final sizes =
        rawSizes.map(HouseholdPortionSize.fromWire).toList(growable: false);
    if (sizes.toSet().length != sizes.length) {
      throw const FoodAnalysisFormatException(
        'Known food portion sizes must be unique.',
      );
    }
    return KnownFoodPortionOption._(unit: unit, sizes: sizes);
  }
}

final class KnownFoodOption {
  final String foodId;
  final String nameVi;
  final bool supportsGrams;
  final List<KnownFoodPortionOption> portionOptions;

  KnownFoodOption._({
    required this.foodId,
    required this.nameVi,
    required this.supportsGrams,
    required List<KnownFoodPortionOption> portionOptions,
  }) : portionOptions = List.unmodifiable(portionOptions);

  factory KnownFoodOption.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'known food',
      const {'foodId', 'nameVi', 'supportsGrams', 'portionOptions'},
    );
    final rawOptions = _jsonList(
      json['portionOptions'],
      'knownFood.portionOptions',
    );
    if (rawOptions.length > HouseholdPortionUnit.values.length) {
      throw const FoodAnalysisFormatException(
        'Known food has too many portion options.',
      );
    }
    final options =
        rawOptions.map(KnownFoodPortionOption.fromJson).toList(growable: false);
    if (options.map((option) => option.unit).toSet().length != options.length) {
      throw const FoodAnalysisFormatException(
        'Known food portion units must be unique.',
      );
    }
    return KnownFoodOption._(
      foodId: _requiredText(json['foodId'], 'knownFood.foodId', maxLength: 100),
      nameVi: _requiredText(json['nameVi'], 'knownFood.nameVi', maxLength: 160),
      supportsGrams: _requiredBool(
        json['supportsGrams'],
        'knownFood.supportsGrams',
      ),
      portionOptions: options,
    );
  }

  static List<KnownFoodOption> listFromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'known food catalog',
      const {'foods'},
    );
    final rawFoods = _jsonList(json['foods'], 'knownFoodCatalog.foods');
    if (rawFoods.length > 100) {
      throw const FoodAnalysisFormatException(
        'Known food catalog cannot exceed 100 entries.',
      );
    }
    final foods =
        rawFoods.map(KnownFoodOption.fromJson).toList(growable: false);
    if (foods.map((food) => food.foodId).toSet().length != foods.length) {
      throw const FoodAnalysisFormatException(
        'Known food identifiers must be unique.',
      );
    }
    return List.unmodifiable(foods);
  }

  bool supportsPortion(FoodPortion? portion) {
    if (portion == null) return false;
    return switch (portion) {
      GramPortion() => supportsGrams,
      HouseholdPortion(:final unit, :final size) => portionOptions.any(
          (option) => option.unit == unit && option.sizes.contains(size),
        ),
    };
  }
}

final class PreparedUpload {
  static const int maxBytes = 5 * 1024 * 1024;
  static const Set<String> supportedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  final Uint8List _bytes;
  final String mimeType;
  final String filename;

  factory PreparedUpload({
    required Uint8List bytes,
    required String mimeType,
    required String filename,
  }) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FoodAnalysisFormatException(
        'Upload bytes must be between 1 byte and 5 MB.',
      );
    }
    if (!supportedMimeTypes.contains(mimeType)) {
      throw const FoodAnalysisFormatException(
        'Upload MIME type must be JPEG, PNG, or WebP.',
      );
    }
    final cleanFilename = _validatedText(
      filename,
      'upload.filename',
      maxLength: 255,
    );
    return PreparedUpload._(
      bytes: Uint8List.fromList(bytes),
      mimeType: mimeType,
      filename: cleanFilename,
    );
  }

  PreparedUpload._({
    required Uint8List bytes,
    required this.mimeType,
    required this.filename,
  }) : _bytes = bytes;

  Uint8List get bytes => Uint8List.fromList(_bytes);
}

/// Product safety envelope for one confirmed photo result.
///
/// These constants reject obviously implausible calculated totals and are not
/// nutrition recommendations or medical guidance.
abstract final class PhotoNutritionSafetyEnvelope {
  static const double maxCalories = 5000;
  static const double maxMacroGrams = 500;
}

final class NutritionRange {
  final double min;
  final double mid;
  final double max;

  factory NutritionRange({
    required double min,
    required double mid,
    required double max,
  }) {
    final cleanMin = _finiteNonNegative(min, 'range.min');
    final cleanMid = _finiteNonNegative(mid, 'range.mid');
    final cleanMax = _finiteNonNegative(max, 'range.max');
    if (cleanMin > cleanMid || cleanMid > cleanMax) {
      throw const FoodAnalysisFormatException(
        'Nutrition range must satisfy min <= mid <= max.',
      );
    }
    return NutritionRange._(
      min: cleanMin,
      mid: cleanMid,
      max: cleanMax,
    );
  }

  const NutritionRange._({
    required this.min,
    required this.mid,
    required this.max,
  });

  factory NutritionRange.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'nutrition range',
      const {'min', 'mid', 'max'},
    );
    final min = _finiteNonNegative(json['min'], 'range.min');
    final mid = _finiteNonNegative(json['mid'], 'range.mid');
    final max = _finiteNonNegative(json['max'], 'range.max');
    if (min > mid || mid > max) {
      throw FoodAnalysisFormatException(
        'Nutrition range must satisfy min <= mid <= max.',
      );
    }
    return NutritionRange._(min: min, mid: mid, max: max);
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

  factory HouseholdPortion({
    required HouseholdPortionUnit unit,
    required double quantity,
    required HouseholdPortionSize size,
  }) {
    final cleanQuantity = _finitePositive(
      quantity,
      'portion.quantity',
      max: 20,
    );
    return HouseholdPortion._(
      unit: unit,
      quantity: cleanQuantity,
      size: size,
    );
  }

  const HouseholdPortion._({
    required this.unit,
    required this.quantity,
    required this.size,
  });

  factory HouseholdPortion.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'household portion',
      const {'kind', 'unit', 'quantity', 'size'},
    );
    if (FoodPortionKind.fromWire(json['kind']) != FoodPortionKind.household) {
      throw FoodAnalysisFormatException(
        'Household portion kind must be HOUSEHOLD.',
      );
    }
    return HouseholdPortion._(
      unit: HouseholdPortionUnit.fromWire(json['unit']),
      quantity: _finitePositive(
        json['quantity'],
        'portion.quantity',
        max: 20,
      ),
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

  factory GramPortion({required double grams}) {
    return GramPortion._(
      grams: _finitePositive(
        grams,
        'portion.grams',
        max: 5000,
      ),
    );
  }

  const GramPortion._({required this.grams});

  factory GramPortion.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'gram portion',
      const {'kind', 'grams'},
    );
    if (FoodPortionKind.fromWire(json['kind']) != FoodPortionKind.grams) {
      throw FoodAnalysisFormatException('Gram portion kind must be GRAMS.');
    }
    return GramPortion._(
      grams: _finitePositive(
        json['grams'],
        'portion.grams',
        max: 5000,
      ),
    );
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

  factory NutrientFacts({
    required double calories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
  }) {
    return NutrientFacts._(
      calories: _finiteNonNegative(
        calories,
        'facts.calories',
        max: 1000,
      ),
      proteinGrams: _finiteNonNegative(
        proteinGrams,
        'facts.proteinGrams',
        max: 100,
      ),
      carbsGrams: _finiteNonNegative(
        carbsGrams,
        'facts.carbsGrams',
        max: 100,
      ),
      fatGrams: _finiteNonNegative(
        fatGrams,
        'facts.fatGrams',
        max: 100,
      ),
    );
  }

  const NutrientFacts._({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  factory NutrientFacts.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'nutrient facts',
      const {'calories', 'proteinGrams', 'carbsGrams', 'fatGrams'},
    );
    return NutrientFacts._(
      calories: _finiteNonNegative(
        json['calories'],
        'facts.calories',
        max: 1000,
      ),
      proteinGrams: _finiteNonNegative(
        json['proteinGrams'],
        'facts.proteinGrams',
        max: 100,
      ),
      carbsGrams: _finiteNonNegative(
        json['carbsGrams'],
        'facts.carbsGrams',
        max: 100,
      ),
      fatGrams: _finiteNonNegative(
        json['fatGrams'],
        'facts.fatGrams',
        max: 100,
      ),
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
    final json = _strictJsonMap(
      value,
      'observed nutrient facts',
      const {'calories', 'proteinGrams', 'carbsGrams', 'fatGrams'},
    );
    return ObservedNutrientFacts(
      calories: _nullableFiniteNonNegative(
        json['calories'],
        'facts.calories',
        max: 1000,
      ),
      proteinGrams: _nullableFiniteNonNegative(
        json['proteinGrams'],
        'facts.proteinGrams',
        max: 100,
      ),
      carbsGrams: _nullableFiniteNonNegative(
        json['carbsGrams'],
        'facts.carbsGrams',
        max: 100,
      ),
      fatGrams: _nullableFiniteNonNegative(
        json['fatGrams'],
        'facts.fatGrams',
        max: 100,
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
    final json = _strictJsonMap(
      value,
      'food component',
      const {
        'id',
        'nameVi',
        'matchedFoodId',
        'confidence',
        'isMajor',
        'requiresManualPortion',
        'suggestedPortion',
      },
    );
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
    final json = _strictJsonMap(
      value,
      'label facts',
      const {
        'nameVi',
        'basis',
        'facts',
        'servingSizeGrams',
        'servingsPerContainer',
        'netWeightGrams',
        'confidence',
        'missingFields',
      },
    );
    final missingValues = _jsonList(
      json['missingFields'],
      'labelFacts.missingFields',
    );
    if (missingValues.length > 9) {
      throw const FoodAnalysisFormatException(
        'labelFacts.missingFields has too many values.',
      );
    }
    final missingFields =
        missingValues.map(LabelMissingField.fromWire).toList(growable: false);
    final basis = LabelBasis.fromWire(json['basis']);
    final facts = ObservedNutrientFacts.fromJson(json['facts']);
    final servingSizeGrams = _nullableFinitePositive(
      json['servingSizeGrams'],
      'labelFacts.servingSizeGrams',
      max: 5000,
    );
    final servingsPerContainer = _nullableFinitePositive(
      json['servingsPerContainer'],
      'labelFacts.servingsPerContainer',
      max: 100,
    );
    final netWeightGrams = _nullableFinitePositive(
      json['netWeightGrams'],
      'labelFacts.netWeightGrams',
      max: 5000,
    );
    final requiredMissingFields = <LabelMissingField>{
      if (basis == LabelBasis.unknown) LabelMissingField.basis,
      if (facts.calories == null) LabelMissingField.calories,
      if (facts.proteinGrams == null) LabelMissingField.proteinGrams,
      if (facts.carbsGrams == null) LabelMissingField.carbsGrams,
      if (facts.fatGrams == null) LabelMissingField.fatGrams,
      if (basis == LabelBasis.perServing && servingSizeGrams == null)
        LabelMissingField.servingSizeGrams,
      if (netWeightGrams == null) LabelMissingField.consumedAmount,
    };
    if (!missingFields.toSet().containsAll(requiredMissingFields)) {
      throw const FoodAnalysisFormatException(
        'labelFacts.missingFields is inconsistent with missing values.',
      );
    }
    return ObservedLabelFacts(
      nameVi: _requiredText(
        json['nameVi'],
        'labelFacts.nameVi',
        maxLength: 160,
      ),
      basis: basis,
      facts: facts,
      servingSizeGrams: servingSizeGrams,
      servingsPerContainer: servingsPerContainer,
      netWeightGrams: netWeightGrams,
      confidence: _confidence(
        json['confidence'],
        'labelFacts.confidence',
      ),
      missingFields: missingFields,
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
  final List<FoodUncertaintyReason> uncertaintyReasons;
  final DateTime expiresAt;

  FoodAnalysisReview._({
    required this.analysisId,
    required this.imageType,
    required this.status,
    required List<ObservedFoodComponent>? components,
    required this.labelFacts,
    required this.confidence,
    required List<FoodUncertaintyReason> uncertaintyReasons,
    required this.expiresAt,
  })  : components = components == null ? null : List.unmodifiable(components),
        uncertaintyReasons = List.unmodifiable(uncertaintyReasons);

  factory FoodAnalysisReview.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'food analysis review',
      const {
        'analysisId',
        'imageType',
        'status',
        'components',
        'labelFacts',
        'confidence',
        'uncertaintyReasons',
        'expiresAt',
      },
    );
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
        if (values.isEmpty ||
            values.length > 20 ||
            json['labelFacts'] != null) {
          throw FoodAnalysisFormatException(
            'MEAL requires components and null labelFacts.',
          );
        }
        components =
            values.map(ObservedFoodComponent.fromJson).toList(growable: false);
        if (components.map((component) => component.id).toSet().length !=
            components.length) {
          throw const FoodAnalysisFormatException(
            'Food component identifiers must be unique.',
          );
        }
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
      analysisId: _requiredNonEmptyText(json['analysisId'], 'analysisId'),
      imageType: imageType,
      status: status,
      components: components,
      labelFacts: labelFacts,
      confidence: _confidence(json['confidence'], 'confidence'),
      uncertaintyReasons: _uncertaintyReasons(
        json['uncertaintyReasons'],
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

  factory ConfirmedFoodComponent({
    required String observationId,
    required String? foodId,
    required String nameVi,
    required FoodPortion portion,
  }) {
    return ConfirmedFoodComponent._(
      observationId: _validatedText(
        observationId,
        'component.observationId',
        maxLength: 100,
      ),
      foodId: foodId == null
          ? null
          : _validatedText(foodId, 'component.foodId', maxLength: 100),
      nameVi: _validatedText(
        nameVi,
        'component.nameVi',
        maxLength: 160,
      ),
      portion: portion,
    );
  }

  const ConfirmedFoodComponent._({
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

  factory MealConfirmation({
    required String nameVi,
    required List<ConfirmedFoodComponent> components,
  }) {
    if (components.isEmpty || components.length > 20) {
      throw const FoodAnalysisFormatException(
        'Meal confirmation requires 1 to 20 components.',
      );
    }
    return MealConfirmation._(
      nameVi: _validatedText(nameVi, 'confirmation.nameVi', maxLength: 160),
      components: List.unmodifiable(components),
    );
  }

  MealConfirmation._({
    required this.nameVi,
    required this.components,
  });

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

  factory LabelConsumedAmount({
    required LabelConsumedKind kind,
    required double amount,
  }) {
    return LabelConsumedAmount._(
      kind: kind,
      amount: _finitePositive(
        amount,
        'consumed.amount',
        max: kind == LabelConsumedKind.grams ? 5000 : 20,
      ),
    );
  }

  const LabelConsumedAmount._({
    required this.kind,
    required this.amount,
  });

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

  factory LabelConfirmation({
    required String nameVi,
    required LabelBasis basis,
    required NutrientFacts facts,
    required double? servingSizeGrams,
    required LabelConsumedAmount consumed,
  }) {
    if (basis == LabelBasis.unknown) {
      throw const FoodAnalysisFormatException(
        'Label confirmation basis cannot be UNKNOWN.',
      );
    }
    final cleanServingSize = servingSizeGrams == null
        ? null
        : _finitePositive(
            servingSizeGrams,
            'confirmation.servingSizeGrams',
            max: 5000,
          );
    if (basis == LabelBasis.perServing && cleanServingSize == null) {
      throw const FoodAnalysisFormatException(
        'PER_SERVING requires servingSizeGrams.',
      );
    }
    if (basis == LabelBasis.per100g &&
        consumed.kind == LabelConsumedKind.servings) {
      throw const FoodAnalysisFormatException(
        'PER_100G requires consumed grams.',
      );
    }
    return LabelConfirmation._(
      nameVi: _validatedText(nameVi, 'confirmation.nameVi', maxLength: 160),
      basis: basis,
      facts: facts,
      servingSizeGrams: cleanServingSize,
      consumed: consumed,
    );
  }

  const LabelConfirmation._({
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
    final json = _strictJsonMap(
      value,
      'nutrition estimate',
      const {'calories', 'proteinGrams', 'carbsGrams', 'fatGrams'},
    );
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
  final List<FoodUncertaintyReason> uncertaintyReasons;
  final String calculationSummary;

  FoodAnalysisReady._({
    required this.analysisId,
    required this.imageType,
    required this.status,
    required this.nameVi,
    required this.estimate,
    required this.confidenceLevel,
    required List<FoodUncertaintyReason> uncertaintyReasons,
    required this.calculationSummary,
  }) : uncertaintyReasons = List.unmodifiable(uncertaintyReasons);

  factory FoodAnalysisReady.fromJson(Object? value) {
    final json = _strictJsonMap(
      value,
      'ready food analysis',
      const {
        'analysisId',
        'imageType',
        'status',
        'nameVi',
        'estimate',
        'confidenceLevel',
        'uncertaintyReasons',
        'calculationSummary',
      },
    );
    final status = FoodAnalysisStatus.fromWire(json['status']);
    final imageType = FoodImageType.fromWire(json['imageType']);
    if (status != FoodAnalysisStatus.ready ||
        imageType == FoodImageType.unknown) {
      throw FoodAnalysisFormatException(
        'Ready response requires READY and a recognized image type.',
      );
    }
    final uncertaintyReasons = _uncertaintyReasons(
      json['uncertaintyReasons'],
    );
    if (imageType == FoodImageType.nutritionLabel &&
        uncertaintyReasons.isNotEmpty) {
      throw const FoodAnalysisFormatException(
        'NUTRITION_LABEL ready results cannot have meal uncertainty codes.',
      );
    }
    return FoodAnalysisReady._(
      analysisId: _requiredNonEmptyText(json['analysisId'], 'analysisId'),
      imageType: imageType,
      status: status,
      nameVi: _requiredText(json['nameVi'], 'nameVi', maxLength: 160),
      estimate: NutritionEstimate.fromJson(json['estimate']),
      confidenceLevel:
          AnalysisConfidenceLevel.fromWire(json['confidenceLevel']),
      uncertaintyReasons: uncertaintyReasons,
      calculationSummary: _requiredNonEmptyText(
        json['calculationSummary'],
        'calculationSummary',
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

final class FoodAnalysisCancelledException implements Exception {
  final String message;

  const FoodAnalysisCancelledException([
    this.message = 'Food photo analysis was cancelled.',
  ]);

  @override
  String toString() => 'FoodAnalysisCancelledException: $message';
}

final class FoodAnalysisFormatException implements Exception {
  final String message;

  const FoodAnalysisFormatException(this.message);

  @override
  String toString() => 'FoodAnalysisFormatException: $message';
}

Map<String, Object?> _strictJsonMap(
  Object? value,
  String field,
  Set<String> expectedKeys,
) {
  final json = _jsonMap(value, field);
  final actualKeys = json.keys.toSet();
  final missingKeys = expectedKeys.difference(actualKeys);
  final extraKeys = actualKeys.difference(expectedKeys);
  if (missingKeys.isNotEmpty || extraKeys.isNotEmpty) {
    throw FoodAnalysisFormatException(
      '$field has missing or unknown keys.',
    );
  }
  return json;
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

List<FoodUncertaintyReason> _uncertaintyReasons(Object? value) {
  final values = _jsonList(value, 'uncertaintyReasons');
  if (values.length > 4) {
    throw const FoodAnalysisFormatException(
      'uncertaintyReasons has too many values.',
    );
  }
  return values.map(FoodUncertaintyReason.fromWire).toList(growable: false);
}

List<Object?> _jsonList(Object? value, String field) {
  if (value is! List) {
    throw FoodAnalysisFormatException('$field must be a JSON array.');
  }
  return List<Object?>.from(value);
}

String _requiredText(
  Object? value,
  String field, {
  required int maxLength,
}) {
  if (value is! String) {
    throw FoodAnalysisFormatException(
      '$field must be a non-empty bounded string.',
    );
  }
  return _validatedText(value, field, maxLength: maxLength);
}

String _requiredNonEmptyText(Object? value, String field) {
  if (value is! String) {
    throw FoodAnalysisFormatException(
      '$field must be a non-empty string.',
    );
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw FoodAnalysisFormatException(
      '$field must be a non-empty string.',
    );
  }
  return trimmed;
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

double _finiteNonNegative(
  Object? value,
  String field, {
  double? max,
}) {
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      (max != null && value > max)) {
    throw FoodAnalysisFormatException(
      '$field must be a finite non-negative number within its limit.',
    );
  }
  return value.toDouble();
}

String _validatedText(
  String value,
  String field, {
  required int maxLength,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > maxLength) {
    throw FoodAnalysisFormatException(
      '$field must be a non-empty bounded string.',
    );
  }
  return trimmed;
}

double _finitePositive(
  Object? value,
  String field, {
  double? max,
}) {
  final parsed = _finiteNonNegative(value, field, max: max);
  if (parsed <= 0) {
    throw FoodAnalysisFormatException('$field must be positive.');
  }
  return parsed;
}

double? _nullableFiniteNonNegative(
  Object? value,
  String field, {
  double? max,
}) {
  if (value == null) return null;
  return _finiteNonNegative(value, field, max: max);
}

double? _nullableFinitePositive(
  Object? value,
  String field, {
  double? max,
}) {
  if (value == null) return null;
  return _finitePositive(value, field, max: max);
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
