const {
  FoodAnalysisError,
  labelConfirmationSchema,
  mealEstimationSchema,
  parseConfirmation,
} = require('./contracts');

const NUTRIENTS = ['calories', 'proteinGrams', 'carbsGrams', 'fatGrams'];
// Product safety envelope for one confirmed photo result. These are rejection
// limits for obviously implausible calculations, not nutrition advice.
const TOTAL_NUTRIENT_MAXIMA = Object.freeze({
  calories: 5000,
  proteinGrams: 500,
  carbsGrams: 500,
  fatGrams: 500,
});
const RANGE_MULTIPLIERS = {
  HIDDEN_OIL: { min: 0.85, max: 1.2 },
  SAUCE: { min: 0.9, max: 1.15 },
  OVERLAP: { min: 0.9, max: 1.1 },
  WEAK_DATABASE_MATCH: { min: 0.85, max: 1.15 },
};

function rounded(value, nutrient) {
  return nutrient === 'calories' ? Math.round(value) : Math.round(value * 10) / 10;
}

function zeroRange() {
  return { min: 0, mid: 0, max: 0 };
}

function addRange(left, right) {
  return { min: left.min + right.min, mid: left.mid + right.mid, max: left.max + right.max };
}

function toEstimate(values) {
  return Object.fromEntries(NUTRIENTS.map((nutrient) => [nutrient, {
    min: rounded(values[nutrient].min, nutrient),
    mid: rounded(values[nutrient].mid, nutrient),
    max: rounded(values[nutrient].max, nutrient),
  }]));
}

class NutritionEstimator {
  constructor({ database }) {
    this.database = database;
  }

  estimateMeal(input) {
    const confirmation = parseConfirmation(mealEstimationSchema, input);
    const total = Object.fromEntries(NUTRIENTS.map((nutrient) => [nutrient, zeroRange()]));
    for (const component of confirmation.components) {
      const record = this.database.require(component);
      for (const nutrient of NUTRIENTS) {
        const range = this.#portionNutrientRange(
          record,
          component.portion,
          nutrient,
          component.observationId,
        );
        total[nutrient] = addRange(total[nutrient], range);
      }
    }
    this.#widen(total, confirmation.uncertaintyReasons);
    this.#assertPlausibleTotals(total);
    const estimate = toEstimate(total);
    return {
      estimate,
      confidenceLevel: confirmation.uncertaintyReasons.length === 0 ? 'HIGH' : confirmation.uncertaintyReasons.length === 1 ? 'MEDIUM' : 'LOW',
      calculationSummaryVi: `Ước tính từ ${confirmation.components.map((component) => this.#formatConfirmedPortion(component)).join('; ')}.`,
    };
  }

  estimateLabel(input) {
    const confirmation = parseConfirmation(labelConfirmationSchema, input);
    this.#assertPlausibleFacts(confirmation.facts);
    const multiplier = confirmation.basis === 'PER_100G'
      ? confirmation.consumed.amount / 100
      : confirmation.consumed.kind === 'SERVINGS'
        ? confirmation.consumed.amount
        : confirmation.consumed.amount / confirmation.servingSizeGrams;
    const calculated = {};
    for (const nutrient of NUTRIENTS) {
      const value = confirmation.facts[nutrient] * multiplier;
      calculated[nutrient] = { min: value, mid: value, max: value };
    }
    this.#assertPlausibleTotals(calculated);
    const estimate = toEstimate(calculated);
    const consumedGrams = confirmation.basis === 'PER_100G'
      ? confirmation.consumed.amount
      : confirmation.consumed.kind === 'GRAMS'
        ? confirmation.consumed.amount
        : confirmation.consumed.amount * confirmation.servingSizeGrams;
    return {
      estimate,
      consumedGrams: rounded(consumedGrams, 'proteinGrams'),
      confidenceLevel: 'HIGH',
      calculationSummaryVi: `Tính theo nhãn đã xác nhận cho ${rounded(consumedGrams, 'proteinGrams')} g.`,
    };
  }

  #portionNutrientRange(record, portion, nutrient, observationId) {
    if (portion.kind === 'GRAMS') {
      if (!record.nutrientsPer100g) {
        throw new FoodAnalysisError('UNSUPPORTED_FOOD_DATA', 'Thực phẩm chưa có dữ liệu theo gram để ước tính.', 422, { foodId: record.id, observationId });
      }
      return this.#per100gRange(record.nutrientsPer100g[nutrient], { min: portion.grams, mid: portion.grams, max: portion.grams });
    }
    if (record.nutrientsPerUnit && record.directUnit === portion.unit && portion.size === 'MEDIUM') {
      const value = record.nutrientsPerUnit[nutrient] * portion.quantity;
      return { min: value, mid: value, max: value };
    }
    const weights = record.householdPortions?.[portion.unit]?.[portion.size];
    if (!weights) {
      throw new FoodAnalysisError('UNSUPPORTED_PORTION', 'Khẩu phần gia dụng chưa được hỗ trợ cho thực phẩm này.', 422, { unit: portion.unit, observationId });
    }
    if (!record.nutrientsPer100g) {
      throw new FoodAnalysisError('UNSUPPORTED_FOOD_DATA', 'Thực phẩm chưa có dữ liệu theo gram để ước tính.', 422, { foodId: record.id, observationId });
    }
    const grams = Object.fromEntries(['min', 'mid', 'max'].map((bound) => [bound, weights[`${bound}Grams`] * portion.quantity]));
    return this.#per100gRange(record.nutrientsPer100g[nutrient], grams);
  }

  #per100gRange(value, grams) {
    return Object.fromEntries(['min', 'mid', 'max'].map((bound) => [bound, value * grams[bound] / 100]));
  }

  #formatConfirmedPortion(component) {
    if (component.portion.kind === 'GRAMS') return `${component.nameVi}: ${component.portion.grams} g`;
    const unit = { BOWL: 'bát', PIECE: 'cái', SPOON: 'muỗng', SERVING: 'phần' }[component.portion.unit];
    const size = { SMALL: 'nhỏ', MEDIUM: 'vừa', LARGE: 'lớn' }[component.portion.size];
    return `${component.nameVi}: ${component.portion.quantity} ${unit} ${size}`;
  }

  #widen(total, reasons) {
    for (const reason of reasons) {
      const multiplier = RANGE_MULTIPLIERS[reason];
      for (const nutrient of NUTRIENTS) {
        total[nutrient].min *= multiplier.min;
        total[nutrient].max *= multiplier.max;
      }
    }
  }

  #assertPlausibleFacts(facts) {
    const macroCalories = facts.proteinGrams * 4 + facts.carbsGrams * 4 + facts.fatGrams * 9;
    // Labels are accepted within 25% or 40 kcal (whichever is greater) for fibre and rounding differences.
    const tolerance = Math.max(40, macroCalories * 0.25);
    if (Math.abs(facts.calories - macroCalories) > tolerance) {
      throw new FoodAnalysisError('INVALID_CONFIRMATION', 'Năng lượng trên nhãn không phù hợp với các chất đa lượng.', 400, { field: 'facts.calories' });
    }
  }

  #assertPlausibleTotals(estimate) {
    for (const nutrient of NUTRIENTS) {
      const maximum = TOTAL_NUTRIENT_MAXIMA[nutrient];
      for (const bound of ['max', 'mid', 'min']) {
        if (estimate[nutrient][bound] > maximum) {
          throw new FoodAnalysisError(
            'INVALID_CONFIRMATION',
            'Tổng dinh dưỡng vượt giới hạn kiểm tra của tính năng. Vui lòng kiểm tra lại khẩu phần.',
            400,
            { field: `estimate.${nutrient}.${bound}` },
          );
        }
      }
    }
  }
}

module.exports = { NutritionEstimator, TOTAL_NUTRIENT_MAXIMA };
