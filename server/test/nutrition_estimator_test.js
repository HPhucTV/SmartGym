const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  NutritionEstimator,
  TOTAL_NUTRIENT_MAXIMA,
} = require('../src/food-analysis/nutrition_estimator');
const { FoodDatabase } = require('../src/food-analysis/food_database');

const database = new FoodDatabase([
  {
    id: 'white-rice',
    nameVi: 'Cơm trắng',
    aliases: ['cơm'],
    nutrientsPer100g: {
      calories: 130,
      proteinGrams: 2.7,
      carbsGrams: 28,
      fatGrams: 0.3,
    },
    householdPortions: {
      BOWL: {
        SMALL: { minGrams: 90, midGrams: 110, maxGrams: 130 },
        MEDIUM: { minGrams: 130, midGrams: 150, maxGrams: 170 },
        LARGE: { minGrams: 170, midGrams: 200, maxGrams: 230 },
      },
    },
  },
]);
const estimator = new NutritionEstimator({ database });
const curatedDatabase = new FoodDatabase(JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'data', 'vietnamese_foods.json'),
  'utf8',
)));
const curatedEstimator = new NutritionEstimator({ database: curatedDatabase });

test('calculates a per-100g label for consumed grams', () => {
  const result = estimator.estimateLabel({
    nameVi: 'Snack',
    basis: 'PER_100G',
    facts: { calories: 498, proteinGrams: 4.4, carbsGrams: 49.8, fatGrams: 31.1 },
    consumed: { kind: 'GRAMS', amount: 57 },
  });

  assert.deepEqual(result.estimate.calories, { min: 284, mid: 284, max: 284 });
  assert.deepEqual(result.estimate.proteinGrams, { min: 2.5, mid: 2.5, max: 2.5 });
  assert.deepEqual(result.estimate.carbsGrams, { min: 28.4, mid: 28.4, max: 28.4 });
  assert.deepEqual(result.estimate.fatGrams, { min: 17.7, mid: 17.7, max: 17.7 });
});

test('calculates a per-serving label for a fractional serving', () => {
  const result = estimator.estimateLabel({
    nameVi: 'Sữa chua',
    basis: 'PER_SERVING',
    facts: { calories: 120, proteinGrams: 5, carbsGrams: 18, fatGrams: 3 },
    servingSizeGrams: 100,
    consumed: { kind: 'SERVINGS', amount: 1.5 },
  });

  assert.equal(result.estimate.calories.mid, 180);
  assert.equal(result.estimate.proteinGrams.mid, 7.5);
});

test('uses household min/mid/max weights for a meal component', () => {
  const result = estimator.estimateMeal({
    nameVi: 'Cơm',
    components: [{
      observationId: 'component-1', foodId: 'white-rice', nameVi: 'Cơm trắng',
      portion: { kind: 'HOUSEHOLD', unit: 'BOWL', quantity: 1, size: 'MEDIUM' },
    }],
    uncertaintyReasons: [],
  });

  assert.deepEqual(result.estimate.calories, { min: 169, mid: 195, max: 221 });
  assert.equal(result.confidenceLevel, 'HIGH');
});

test('widens a meal range for hidden oil without changing the midpoint source', () => {
  const result = estimator.estimateMeal({
    nameVi: 'Cơm',
    components: [{
      observationId: 'component-1', foodId: 'white-rice', nameVi: 'Cơm trắng',
      portion: { kind: 'GRAMS', grams: 150 },
    }],
    uncertaintyReasons: ['HIDDEN_OIL'],
  });

  assert.ok(result.estimate.calories.min < result.estimate.calories.mid);
  assert.ok(result.estimate.calories.max > result.estimate.calories.mid);
  assert.equal(result.estimate.calories.mid, 195);
});

test('rejects unknown foods and implausible nutrition', () => {
  assert.throws(
    () => estimator.estimateMeal({
      nameVi: 'Không rõ',
      components: [{
        observationId: 'component-1', foodId: 'missing', nameVi: 'Không rõ',
        portion: { kind: 'GRAMS', grams: 100 },
      }],
      uncertaintyReasons: [],
    }),
    (error) => error.code === 'DATABASE_NO_MATCH',
  );

  assert.throws(
    () => estimator.estimateLabel({
      nameVi: 'Sai', basis: 'PER_100G',
      facts: { calories: 9000, proteinGrams: 0, carbsGrams: 0, fatGrams: 0 },
      consumed: { kind: 'GRAMS', amount: 100 },
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});

test('database no-match preserves the observation context for correction', () => {
  assert.throws(
    () => curatedEstimator.estimateMeal({
      nameVi: 'Bữa ăn',
      uncertaintyReasons: [],
      components: [{
        observationId: 'provider-component-7',
        nameVi: 'Món hoàn toàn không biết',
        portion: { kind: 'GRAMS', grams: 100 },
      }],
    }),
    (error) => error.code === 'DATABASE_NO_MATCH'
      && error.details.observationId === 'provider-component-7',
  );
});

test('uses serving count and net weight conversion for labels', () => {
  const result = estimator.estimateLabel({
    nameVi: 'Bánh', basis: 'PER_SERVING',
    facts: { calories: 101, proteinGrams: 1.25, carbsGrams: 20.25, fatGrams: 1.55 },
    servingSizeGrams: 40,
    consumed: { kind: 'GRAMS', amount: 60 },
  });

  assert.equal(result.consumedGrams, 60);
  assert.equal(result.estimate.calories.mid, 152);
  assert.equal(result.estimate.proteinGrams.mid, 1.9);
});

test('rejects invalid, empty, and ambiguous confirmations', () => {
  assert.throws(
    () => estimator.estimateMeal({ nameVi: 'Trống', components: [], uncertaintyReasons: [] }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
  assert.throws(
    () => estimator.estimateMeal({
      nameVi: 'Quá nhiều',
      components: [{ observationId: 'x', foodId: 'white-rice', nameVi: 'Cơm', portion: { kind: 'HOUSEHOLD', unit: 'BOWL', quantity: 21, size: 'SMALL' } }],
      uncertaintyReasons: [],
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
  assert.throws(
    () => estimator.estimateLabel({
      nameVi: 'Không rõ', basis: 'UNKNOWN', facts: { calories: 1, proteinGrams: 0, carbsGrams: 0, fatGrams: 0 },
      consumed: { kind: 'GRAMS', amount: 1 },
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
  assert.throws(
    () => estimator.estimateLabel({
      nameVi: 'Sai', basis: 'PER_100G', facts: { calories: -1, proteinGrams: 0, carbsGrams: 0, fatGrams: 0 },
      consumed: { kind: 'GRAMS', amount: NaN },
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});

test('rejects labels whose calories disagree with macros', () => {
  assert.throws(
    () => estimator.estimateLabel({
      nameVi: 'Sai', basis: 'PER_100G',
      facts: { calories: 100, proteinGrams: 40, carbsGrams: 40, fatGrams: 20 },
      consumed: { kind: 'GRAMS', amount: 100 },
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});

test('accepts meal totals at the product safety envelope and rejects totals above it', () => {
  assert.deepEqual(TOTAL_NUTRIENT_MAXIMA, {
    calories: 5000,
    proteinGrams: 500,
    carbsGrams: 500,
    fatGrams: 500,
  });
  const boundaryEstimator = new NutritionEstimator({
    database: new FoodDatabase([{
      id: 'boundary-food',
      nameVi: 'Mon kiem tra bien',
      aliases: [],
      nutrientsPer100g: {
        calories: 1000,
        proteinGrams: 100,
        carbsGrams: 100,
        fatGrams: 100,
      },
      householdPortions: {},
    }]),
  });
  const confirmation = (grams) => ({
    nameVi: 'Bua an kiem tra bien',
    components: [{
      observationId: 'boundary-component',
      foodId: 'boundary-food',
      nameVi: 'Mon kiem tra bien',
      portion: { kind: 'GRAMS', grams },
    }],
    uncertaintyReasons: [],
  });

  const exact = boundaryEstimator.estimateMeal(confirmation(500));
  for (const nutrient of Object.keys(TOTAL_NUTRIENT_MAXIMA)) {
    assert.deepEqual(exact.estimate[nutrient], {
      min: TOTAL_NUTRIENT_MAXIMA[nutrient],
      mid: TOTAL_NUTRIENT_MAXIMA[nutrient],
      max: TOTAL_NUTRIENT_MAXIMA[nutrient],
    });
  }
  assert.throws(
    () => boundaryEstimator.estimateMeal(confirmation(500.0001)),
    (error) => error.code === 'INVALID_CONFIRMATION'
      && error.details.field === 'estimate.calories.max',
  );
});

test('accepts label totals at the product safety envelope and rejects totals above it', () => {
  const caloriesProteinCarbs = (amount) => estimator.estimateLabel({
    nameVi: 'Nhan kiem tra bien',
    basis: 'PER_100G',
    facts: {
      calories: 1000,
      proteinGrams: 100,
      carbsGrams: 100,
      fatGrams: 22.2222222222,
    },
    consumed: { kind: 'GRAMS', amount },
  });
  const fat = (amount) => estimator.estimateLabel({
    nameVi: 'Nhan chat beo kiem tra bien',
    basis: 'PER_100G',
    facts: {
      calories: 900,
      proteinGrams: 0,
      carbsGrams: 0,
      fatGrams: 100,
    },
    consumed: { kind: 'GRAMS', amount },
  });

  const exact = caloriesProteinCarbs(500);
  assert.equal(exact.estimate.calories.max, TOTAL_NUTRIENT_MAXIMA.calories);
  assert.equal(exact.estimate.proteinGrams.max, TOTAL_NUTRIENT_MAXIMA.proteinGrams);
  assert.equal(exact.estimate.carbsGrams.max, TOTAL_NUTRIENT_MAXIMA.carbsGrams);
  assert.equal(fat(500).estimate.fatGrams.max, TOTAL_NUTRIENT_MAXIMA.fatGrams);

  assert.throws(
    () => caloriesProteinCarbs(500.0001),
    (error) => error.code === 'INVALID_CONFIRMATION'
      && error.details.field === 'estimate.calories.max',
  );
  assert.throws(
    () => fat(500.0001),
    (error) => error.code === 'INVALID_CONFIRMATION'
      && error.details.field === 'estimate.fatGrams.max',
  );
});

test('does not fuzzy-match generic meat, fish, or egg names', () => {
  const genericDatabase = new FoodDatabase([
    {
      id: 'boiled-egg', nameVi: 'Trứng gà luộc', aliases: ['trứng gà'],
      nutrientsPer100g: { calories: 155, proteinGrams: 13, carbsGrams: 1.1, fatGrams: 11 },
      householdPortions: {},
    },
  ]);

  assert.equal(genericDatabase.match('trứng'), null);
  assert.equal(genericDatabase.match('thịt'), null);
  assert.equal(genericDatabase.match('cá'), null);
});

test('estimates shipped per-piece and per-serving legacy records exactly', () => {
  const eggs = curatedEstimator.estimateMeal({
    nameVi: 'Trứng',
    components: [{
      observationId: 'egg-1', foodId: 'boiled-egg', nameVi: 'Trứng luộc',
      portion: { kind: 'HOUSEHOLD', unit: 'PIECE', quantity: 2, size: 'MEDIUM' },
    }],
    uncertaintyReasons: [],
  });
  const pho = curatedEstimator.estimateMeal({
    nameVi: 'Phở',
    components: [{
      observationId: 'pho-1', foodId: 'beef-pho', nameVi: 'Phở bò',
      portion: { kind: 'HOUSEHOLD', unit: 'SERVING', quantity: 1, size: 'MEDIUM' },
    }],
    uncertaintyReasons: [],
  });

  assert.deepEqual(eggs.estimate.calories, { min: 156, mid: 156, max: 156 });
  assert.deepEqual(pho.estimate.calories, { min: 350, mid: 350, max: 350 });
});

test('uses the shipped gram and bowl paths and rejects unsupported curated combinations', () => {
  const riceByGrams = curatedEstimator.estimateMeal({
    nameVi: 'Cơm',
    components: [{
      observationId: 'rice-grams', foodId: 'white-rice', nameVi: 'Cơm trắng',
      portion: { kind: 'GRAMS', grams: 100 },
    }],
    uncertaintyReasons: [],
  });
  const riceByBowl = curatedEstimator.estimateMeal({
    nameVi: 'Cơm',
    components: [{
      observationId: 'rice-bowl', foodId: 'white-rice', nameVi: 'Cơm trắng',
      portion: { kind: 'HOUSEHOLD', unit: 'BOWL', quantity: 1, size: 'MEDIUM' },
    }],
    uncertaintyReasons: [],
  });

  assert.equal(riceByGrams.estimate.calories.mid, 130);
  assert.equal(riceByBowl.estimate.calories.mid, 195);
  assert.throws(
    () => curatedEstimator.estimateMeal({
      nameVi: 'Trứng',
      components: [{
        observationId: 'egg-bowl', foodId: 'boiled-egg', nameVi: 'Trứng luộc',
        portion: { kind: 'HOUSEHOLD', unit: 'BOWL', quantity: 1, size: 'MEDIUM' },
      }],
      uncertaintyReasons: [],
    }),
    (error) => error.code === 'UNSUPPORTED_PORTION',
  );
  assert.throws(
    () => curatedEstimator.estimateMeal({
      nameVi: 'Cơm',
      components: [{
        observationId: 'rice-piece', foodId: 'white-rice', nameVi: 'Cơm trắng',
        portion: { kind: 'HOUSEHOLD', unit: 'PIECE', quantity: 1, size: 'MEDIUM' },
      }],
      uncertaintyReasons: [],
    }),
    (error) => error.code === 'UNSUPPORTED_PORTION',
  );
});

test('summarizes only confirmed grams and household portions', () => {
  const result = curatedEstimator.estimateMeal({
    nameVi: 'Bữa ăn',
    components: [
      {
        observationId: 'rice-grams', foodId: 'white-rice', nameVi: 'Cơm trắng',
        portion: { kind: 'GRAMS', grams: 150 },
      },
      {
        observationId: 'egg-piece', foodId: 'boiled-egg', nameVi: 'Trứng luộc',
        portion: { kind: 'HOUSEHOLD', unit: 'PIECE', quantity: 1, size: 'MEDIUM' },
      },
    ],
    uncertaintyReasons: [],
  });

  assert.equal(result.calculationSummaryVi, 'Ước tính từ Cơm trắng: 150 g; Trứng luộc: 1 cái vừa.');
});
