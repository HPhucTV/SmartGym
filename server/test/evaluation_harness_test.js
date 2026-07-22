const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const {
  assessReleaseGate,
  evaluateManifest,
  validateManifest,
  writeAggregateReport,
} = require('../evaluation/run_evaluation');
const { FoodAnalysisError } = require('../src/food-analysis/contracts');

const jpeg = (marker) => Buffer.from([0xff, 0xd8, 0xff, marker]);

function provenance() {
  return {
    source: 'Synthetic test fixture',
    license: 'Project test fixture',
    licenseReference: 'test://evaluation-fixture-license',
    collectedAt: '2026-07-22',
  };
}

function nutrition(calories) {
  return {
    calories,
    proteinGrams: 10,
    carbsGrams: 20,
    fatGrams: 8,
  };
}

function mealCase(overrides = {}) {
  return {
    caseId: 'meal-1',
    imageType: 'MEAL',
    primaryImage: 'images/meal.jpg',
    secondaryImage: {
      path: 'images/meal-side.jpg',
      captureReason: 'SIDE_ANGLE',
    },
    provenance: provenance(),
    groundTruth: {
      majorComponentFoodIds: ['white-rice'],
      confirmation: {
        kind: 'MEAL',
        nameVi: 'Bua an thu nghiem',
        components: [{
          observationId: 'rice',
          foodId: 'white-rice',
          nameVi: 'Com trang',
          portion: { kind: 'GRAMS', grams: 150 },
        }],
      },
      weighedNutrition: nutrition(200),
    },
    ...overrides,
  };
}

function labelCase(overrides = {}) {
  return {
    caseId: 'label-1',
    imageType: 'NUTRITION_LABEL',
    primaryImage: 'images/label.jpg',
    provenance: provenance(),
    groundTruth: {
      clearLabel: true,
      confirmation: {
        kind: 'NUTRITION_LABEL',
        nameVi: 'Nhan thu nghiem',
        basis: 'PER_100G',
        facts: nutrition(200),
        consumed: { kind: 'GRAMS', amount: 100 },
      },
      weighedNutrition: nutrition(250),
    },
    ...overrides,
  };
}

function unknownCase() {
  return mealCase({
    caseId: 'meal-error',
    primaryImage: 'images/error.jpg',
    secondaryImage: undefined,
  });
}

function createFixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'food-eval-'));
  const images = path.join(root, 'images');
  fs.mkdirSync(images);
  fs.writeFileSync(path.join(images, 'meal.jpg'), jpeg(1));
  fs.writeFileSync(path.join(images, 'meal-side.jpg'), jpeg(2));
  fs.writeFileSync(path.join(images, 'label.jpg'), jpeg(3));
  fs.writeFileSync(path.join(images, 'error.jpg'), jpeg(4));
  return root;
}

function observer() {
  return {
    async observePrimary({ bytes }) {
      if (bytes[3] === 1) {
        return {
          imageType: 'MEAL',
          confidence: 0.5,
          uncertaintyReasons: [],
          components: [{
            id: 'rice',
            nameVi: 'Com trang',
            confidence: 0.5,
            isMajor: true,
            suggestedPortion: null,
          }],
          labelFacts: null,
        };
      }
      if (bytes[3] === 3) {
        return {
          imageType: 'NUTRITION_LABEL',
          confidence: 0.98,
          uncertaintyReasons: [],
          components: null,
          labelFacts: {
            nameVi: 'Nhan thu nghiem',
            basis: 'PER_100G',
            facts: nutrition(200),
            servingSizeGrams: null,
            servingsPerContainer: null,
            netWeightGrams: 100,
            confidence: 0.98,
            missingFields: [],
          },
        };
      }
      throw new FoodAnalysisError('ANALYSIS_UNAVAILABLE', 'synthetic failure', 503);
    },
    async observeSecondary() {
      return {
        imageType: 'MEAL',
        confidence: 0.9,
        uncertaintyReasons: [],
        components: [{
          id: 'rice',
          nameVi: 'Com trang',
          confidence: 0.9,
          isMajor: true,
          suggestedPortion: { kind: 'GRAMS', grams: 150 },
        }],
        labelFacts: null,
      };
    },
  };
}

test('evaluates synthetic cases through the real service and returns aggregate-only metrics', async (t) => {
  const evalDir = createFixture();
  t.after(() => fs.rmSync(evalDir, { recursive: true, force: true }));
  const times = [0, 100, 100, 400, 400, 900];

  const report = await evaluateManifest({
    evalDir,
    manifest: { schemaVersion: 1, cases: [mealCase(), labelCase(), unknownCase()] },
    observer: observer(),
    nowMs: () => times.shift(),
    enforceMinimums: false,
    generatedAt: '2026-07-22T00:00:00.000Z',
  });

  assert.deepEqual(report.caseCounts, {
    total: 3,
    meal: 2,
    label: 1,
    completed: 2,
    failed: 1,
  });
  // The unavailable meal counts as a missed identification, not as an excluded case.
  assert.equal(report.metrics.majorComponentIdentificationRatePercent, 50);
  assert.equal(report.metrics.medianAbsoluteCalorieErrorPercent, 11.25);
  assert.equal(report.metrics.within35PercentCalorieErrorPercent, 66.67);
  assert.equal(report.metrics.clearLabelRequiredFieldCompletenessPercent, 100);
  assert.equal(report.metrics.secondImageRatePercent, 33.33);
  assert.deepEqual(report.metrics.errorCodeCounts, { ANALYSIS_UNAVAILABLE: 1 });
  assert.deepEqual(report.metrics.latencyMs, { p50: 300, p95: 500 });

  const serialized = JSON.stringify(report);
  for (const forbidden of ['Com trang', 'Nhan thu nghiem', 'meal.jpg', 'observations']) {
    assert.equal(serialized.includes(forbidden), false);
  }
});

test('release gate enforces dataset minimums and all accuracy targets', () => {
  const passingMetrics = {
    majorComponentIdentificationRatePercent: 90,
    medianAbsoluteCalorieErrorPercent: 20,
    within35PercentCalorieErrorPercent: 90,
    clearLabelRequiredFieldCompletenessPercent: 95,
  };
  const passing = assessReleaseGate({
    caseCounts: { meal: 30, label: 20 },
    metrics: passingMetrics,
  });
  assert.equal(passing.passed, true);

  const tooSmall = assessReleaseGate({
    caseCounts: { meal: 29, label: 19 },
    metrics: passingMetrics,
  });
  assert.equal(tooSmall.passed, false);
  assert.equal(tooSmall.checks.minimumMealCases.passed, false);
  assert.equal(tooSmall.checks.minimumLabelCases.passed, false);

  const inaccurate = assessReleaseGate({
    caseCounts: { meal: 30, label: 20 },
    metrics: {
      majorComponentIdentificationRatePercent: 89.99,
      medianAbsoluteCalorieErrorPercent: 20.01,
      within35PercentCalorieErrorPercent: 89.99,
      clearLabelRequiredFieldCompletenessPercent: 94.99,
    },
  });
  assert.equal(inaccurate.passed, false);
});

test('production evaluation fails minimum counts before invoking the provider', async (t) => {
  const evalDir = createFixture();
  t.after(() => fs.rmSync(evalDir, { recursive: true, force: true }));
  let providerCalls = 0;

  await assert.rejects(
    evaluateManifest({
      evalDir,
      manifest: { schemaVersion: 1, cases: [mealCase(), labelCase()] },
      observer: {
        async observePrimary() {
          providerCalls += 1;
          throw new Error('must not run');
        },
      },
    }),
    (error) => error.code === 'INSUFFICIENT_EVALUATION_DATA',
  );
  assert.equal(providerCalls, 0);
});

test('failed clear-label cases remain in completeness and within-error denominators', async (t) => {
  const evalDir = createFixture();
  t.after(() => fs.rmSync(evalDir, { recursive: true, force: true }));
  const failedLabel = labelCase({
    caseId: 'label-error',
    primaryImage: 'images/error.jpg',
  });

  const report = await evaluateManifest({
    evalDir,
    manifest: { schemaVersion: 1, cases: [labelCase(), failedLabel] },
    observer: observer(),
    nowMs: (() => {
      const times = [0, 10, 10, 20];
      return () => times.shift();
    })(),
    enforceMinimums: false,
    generatedAt: '2026-07-22T00:00:00.000Z',
  });

  assert.equal(report.metrics.clearLabelRequiredFieldCompletenessPercent, 50);
  assert.equal(report.metrics.within35PercentCalorieErrorPercent, 50);
});

test('manifest validation rejects missing license metadata and unsafe image paths', () => {
  const missingLicense = mealCase();
  delete missingLicense.provenance.license;
  assert.throws(
    () => validateManifest({ schemaVersion: 1, cases: [missingLicense] }),
    /license/,
  );

  const unsafe = mealCase({ primaryImage: '../private-photo.jpg' });
  assert.throws(
    () => validateManifest({ schemaVersion: 1, cases: [unsafe] }),
    /relative path|traversal/i,
  );

  const placeholder = mealCase();
  placeholder.provenance.licenseReference = 'REPLACE_WITH_RELEASE';
  assert.throws(
    () => validateManifest({ schemaVersion: 1, cases: [placeholder] }),
    /placeholder/i,
  );
});

test('aggregate report writer never serializes per-case data', (t) => {
  const outputDir = fs.mkdtempSync(path.join(os.tmpdir(), 'food-eval-report-'));
  t.after(() => fs.rmSync(outputDir, { recursive: true, force: true }));
  const report = {
    schemaVersion: 1,
    generatedAt: '2026-07-22T00:00:00.000Z',
    caseCounts: { total: 0, meal: 0, label: 0, completed: 0, failed: 0 },
    metrics: {
      majorComponentIdentificationRatePercent: null,
      medianAbsoluteCalorieErrorPercent: null,
      within35PercentCalorieErrorPercent: null,
      clearLabelRequiredFieldCompletenessPercent: null,
      secondImageRatePercent: 0,
      errorCodeCounts: {},
      latencyMs: { p50: null, p95: null },
    },
    releaseGate: { passed: false, checks: {} },
    privateCase: { imagePath: 'must-not-leak.jpg' },
  };

  const output = writeAggregateReport(report, outputDir);
  const written = fs.readFileSync(output, 'utf8');
  assert.equal(written.includes('privateCase'), false);
  assert.equal(written.includes('must-not-leak'), false);
});
