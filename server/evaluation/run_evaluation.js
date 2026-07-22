'use strict';

const fs = require('node:fs');
const path = require('node:path');

const { AnalysisSessionStore } = require('../src/food-analysis/analysis_session_store');
const {
  FoodAnalysisError,
  labelConfirmationSchema,
  mealConfirmationSchema,
} = require('../src/food-analysis/contracts');
const { FoodAnalysisService } = require('../src/food-analysis/food_analysis_service');
const { FoodDatabase } = require('../src/food-analysis/food_database');
const { GeminiFoodObserver } = require('../src/food-analysis/gemini_food_observer');
const { NutritionEstimator } = require('../src/food-analysis/nutrition_estimator');
const { detectImageType } = require('../src/http/image_signature');

const MAX_MANIFEST_BYTES = 1024 * 1024;
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const MAX_CASES = 500;
const MIN_MEAL_CASES = 30;
const MIN_LABEL_CASES = 20;
const REQUIRED_PROVENANCE_FIELDS = [
  'source',
  'license',
  'licenseReference',
  'collectedAt',
];
const NUTRIENTS = ['calories', 'proteinGrams', 'carbsGrams', 'fatGrams'];
const RELEASE_TARGETS = Object.freeze({
  majorComponentIdentificationRatePercent: 90,
  medianAbsoluteCalorieErrorPercent: 20,
  within35PercentCalorieErrorPercent: 90,
  clearLabelRequiredFieldCompletenessPercent: 95,
});

class EvaluationInputError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'EvaluationInputError';
    this.code = code;
  }
}

function inputError(message) {
  return new EvaluationInputError('INVALID_EVALUATION_INPUT', message);
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function requirePlainObject(value, field) {
  if (!isPlainObject(value)) throw inputError(`${field} must be an object`);
  return value;
}

function requireString(value, field, maxLength = 300) {
  if (typeof value !== 'string' || !value.trim() || value.length > maxLength) {
    throw inputError(`${field} must be a non-empty string`);
  }
  return value.trim();
}

function requireRelativeFilePath(value, field) {
  const candidate = requireString(value, field, 240);
  if (candidate.includes('\0')
    || path.isAbsolute(candidate)
    || candidate.split(/[\\/]+/).some((segment) => segment === '..')) {
    throw inputError(`${field} must be a safe relative path without traversal`);
  }
  return candidate;
}

function requireFiniteNumber(value, field, { positive = false, max = 10_000 } = {}) {
  if (!Number.isFinite(value)
    || (positive ? value <= 0 : value < 0)
    || value > max) {
    throw inputError(`${field} must be a finite ${positive ? 'positive' : 'non-negative'} number`);
  }
  return value;
}

function validateNutrition(value, field) {
  const nutrition = requirePlainObject(value, field);
  for (const nutrient of NUTRIENTS) {
    requireFiniteNumber(
      nutrition[nutrient],
      `${field}.${nutrient}`,
      { positive: nutrient === 'calories', max: nutrient === 'calories' ? 10_000 : 2_000 },
    );
  }
}

function validateProvenance(value, field) {
  const provenance = requirePlainObject(value, field);
  for (const key of REQUIRED_PROVENANCE_FIELDS) {
    const entry = requireString(provenance[key], `${field}.${key}`, 500);
    if (/(?:REPLACE_|PLACEHOLDER|\bTBD\b|\bTODO\b|\bUNKNOWN\b|\bUNVERIFIED\b)/i.test(entry)) {
      throw inputError(`${field}.${key} must contain verified provenance, not a placeholder`);
    }
  }
}

function validateConfirmation(value, imageType, field) {
  const confirmation = requirePlainObject(value, field);
  if (confirmation.kind !== imageType) {
    throw inputError(`${field}.kind must match imageType`);
  }
  const { kind, ...payload } = confirmation;
  const schema = imageType === 'MEAL' ? mealConfirmationSchema : labelConfirmationSchema;
  const parsed = schema.safeParse(payload);
  if (!parsed.success) {
    const issuePath = parsed.error.issues[0]?.path.join('.') || 'confirmation';
    throw inputError(`${field}.${issuePath} is invalid`);
  }
}

function validateCase(item, index, seenIds) {
  const field = `cases.${index}`;
  const value = requirePlainObject(item, field);
  const caseId = requireString(value.caseId, `${field}.caseId`, 100);
  if (seenIds.has(caseId)) throw inputError(`${field}.caseId must be unique`);
  seenIds.add(caseId);
  if (!['MEAL', 'NUTRITION_LABEL'].includes(value.imageType)) {
    throw inputError(`${field}.imageType must be MEAL or NUTRITION_LABEL`);
  }
  requireRelativeFilePath(value.primaryImage, `${field}.primaryImage`);
  if (value.secondaryImage !== undefined && value.secondaryImage !== null) {
    const secondary = requirePlainObject(value.secondaryImage, `${field}.secondaryImage`);
    requireRelativeFilePath(secondary.path, `${field}.secondaryImage.path`);
    requireString(secondary.captureReason, `${field}.secondaryImage.captureReason`, 100);
  }
  validateProvenance(value.provenance, `${field}.provenance`);
  const groundTruth = requirePlainObject(value.groundTruth, `${field}.groundTruth`);
  validateConfirmation(groundTruth.confirmation, value.imageType, `${field}.groundTruth.confirmation`);
  validateNutrition(groundTruth.weighedNutrition, `${field}.groundTruth.weighedNutrition`);
  if (value.imageType === 'MEAL') {
    if (!Array.isArray(groundTruth.majorComponentFoodIds)
      || groundTruth.majorComponentFoodIds.length === 0
      || groundTruth.majorComponentFoodIds.length > 20) {
      throw inputError(`${field}.groundTruth.majorComponentFoodIds must contain 1 to 20 items`);
    }
    const uniqueFoodIds = new Set();
    for (let i = 0; i < groundTruth.majorComponentFoodIds.length; i += 1) {
      uniqueFoodIds.add(requireString(
        groundTruth.majorComponentFoodIds[i],
        `${field}.groundTruth.majorComponentFoodIds.${i}`,
        100,
      ));
    }
    if (uniqueFoodIds.size !== groundTruth.majorComponentFoodIds.length) {
      throw inputError(`${field}.groundTruth.majorComponentFoodIds must be unique`);
    }
    const confirmationFoodIds = new Set(groundTruth.confirmation.components
      .map((component) => component.foodId)
      .filter(Boolean));
    for (const foodId of uniqueFoodIds) {
      if (!confirmationFoodIds.has(foodId)) {
        throw inputError(`${field}.groundTruth.majorComponentFoodIds must exist in confirmation components`);
      }
    }
  } else if (typeof groundTruth.clearLabel !== 'boolean') {
    throw inputError(`${field}.groundTruth.clearLabel must be a boolean`);
  }
}

function validateManifest(manifest) {
  const value = requirePlainObject(manifest, 'manifest');
  if (value.schemaVersion !== 1) throw inputError('schemaVersion must be 1');
  if (!Array.isArray(value.cases) || value.cases.length === 0 || value.cases.length > MAX_CASES) {
    throw inputError(`cases must contain 1 to ${MAX_CASES} items`);
  }
  const seenIds = new Set();
  value.cases.forEach((item, index) => validateCase(item, index, seenIds));
  return value;
}

function isInside(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative !== '' && !relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative);
}

function resolvePrivateFile(evalRoot, relativePath, maxBytes) {
  const requested = path.resolve(evalRoot, relativePath);
  if (!isInside(evalRoot, requested)) throw inputError('image path escapes FOOD_EVAL_DIR');

  let realPath;
  try {
    realPath = fs.realpathSync(requested);
  } catch {
    throw inputError('evaluation image is missing or unreadable');
  }
  if (!isInside(evalRoot, realPath)) throw inputError('evaluation image symlink escapes FOOD_EVAL_DIR');
  const stat = fs.statSync(realPath);
  if (!stat.isFile() || stat.size <= 0 || stat.size > maxBytes) {
    throw inputError('evaluation image has an invalid size');
  }
  return realPath;
}

function readImage(evalRoot, relativePath) {
  const filePath = resolvePrivateFile(evalRoot, relativePath, MAX_IMAGE_BYTES);
  const bytes = fs.readFileSync(filePath);
  const detected = detectImageType(bytes);
  if (!detected) throw inputError('evaluation image must be JPEG, PNG, or WEBP');
  return { bytes, mimeType: detected.mimeType };
}

function loadPrivateManifest(evalDir) {
  let evalRoot;
  try {
    evalRoot = fs.realpathSync(evalDir);
  } catch {
    throw inputError('FOOD_EVAL_DIR is missing or unreadable');
  }
  if (!fs.statSync(evalRoot).isDirectory()) throw inputError('FOOD_EVAL_DIR must be a directory');
  const manifestPath = resolvePrivateFile(evalRoot, 'manifest.json', MAX_MANIFEST_BYTES);
  let decoded;
  try {
    decoded = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  } catch {
    throw inputError('manifest.json is not valid JSON');
  }
  return { evalRoot, manifest: validateManifest(decoded) };
}

function createService(observer) {
  const records = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'data', 'vietnamese_foods.json'), 'utf8'));
  const database = new FoodDatabase(records);
  return new FoodAnalysisService({
    observer,
    estimator: new NutritionEstimator({ database }),
    sessionStore: new AnalysisSessionStore(),
  });
}

function roundPercent(value) {
  return Math.round(value * 100) / 100;
}

function percentage(numerator, denominator) {
  return denominator === 0 ? null : roundPercent((numerator / denominator) * 100);
}

function percentile(values, fraction) {
  if (values.length === 0) return null;
  const ordered = [...values].sort((left, right) => left - right);
  return ordered[Math.max(0, Math.ceil(ordered.length * fraction) - 1)];
}

function median(values) {
  if (values.length === 0) return null;
  const ordered = [...values].sort((left, right) => left - right);
  const middle = Math.floor(ordered.length / 2);
  const value = ordered.length % 2 === 0
    ? (ordered[middle - 1] + ordered[middle]) / 2
    : ordered[middle];
  return roundPercent(value);
}

function labelCompleteness(labelFacts, confirmation) {
  const checks = [
    labelFacts?.basis !== null && labelFacts?.basis !== 'UNKNOWN',
    ...NUTRIENTS.map((nutrient) => labelFacts?.facts?.[nutrient] !== null
      && Number.isFinite(labelFacts?.facts?.[nutrient])),
    labelFacts?.netWeightGrams !== null && Number.isFinite(labelFacts?.netWeightGrams),
  ];
  if (confirmation.basis === 'PER_SERVING') {
    checks.push(labelFacts?.servingSizeGrams !== null
      && Number.isFinite(labelFacts?.servingSizeGrams));
  }
  return {
    complete: checks.filter(Boolean).length,
    required: checks.length,
  };
}

function requiredLabelFieldCount(confirmation) {
  return confirmation.basis === 'PER_SERVING' ? 7 : 6;
}

function normalizedErrorCode(error) {
  const raw = typeof error?.code === 'string' ? error.code : 'INTERNAL_ERROR';
  return /^[A-Z][A-Z0-9_]{0,63}$/.test(raw) ? raw : 'INTERNAL_ERROR';
}

function assessReleaseGate({ caseCounts, metrics }, { enforceMinimums = true } = {}) {
  const checks = {
    minimumMealCases: {
      target: MIN_MEAL_CASES,
      actual: caseCounts.meal,
      passed: !enforceMinimums || caseCounts.meal >= MIN_MEAL_CASES,
    },
    minimumLabelCases: {
      target: MIN_LABEL_CASES,
      actual: caseCounts.label,
      passed: !enforceMinimums || caseCounts.label >= MIN_LABEL_CASES,
    },
    majorComponentIdentification: {
      operator: '>=',
      targetPercent: RELEASE_TARGETS.majorComponentIdentificationRatePercent,
      actualPercent: metrics.majorComponentIdentificationRatePercent,
      passed: metrics.majorComponentIdentificationRatePercent !== null
        && metrics.majorComponentIdentificationRatePercent
          >= RELEASE_TARGETS.majorComponentIdentificationRatePercent,
    },
    medianAbsoluteCalorieError: {
      operator: '<=',
      targetPercent: RELEASE_TARGETS.medianAbsoluteCalorieErrorPercent,
      actualPercent: metrics.medianAbsoluteCalorieErrorPercent,
      passed: metrics.medianAbsoluteCalorieErrorPercent !== null
        && metrics.medianAbsoluteCalorieErrorPercent
          <= RELEASE_TARGETS.medianAbsoluteCalorieErrorPercent,
    },
    within35PercentCalorieError: {
      operator: '>=',
      targetPercent: RELEASE_TARGETS.within35PercentCalorieErrorPercent,
      actualPercent: metrics.within35PercentCalorieErrorPercent,
      passed: metrics.within35PercentCalorieErrorPercent !== null
        && metrics.within35PercentCalorieErrorPercent
          >= RELEASE_TARGETS.within35PercentCalorieErrorPercent,
    },
    clearLabelRequiredFieldCompleteness: {
      operator: '>=',
      targetPercent: RELEASE_TARGETS.clearLabelRequiredFieldCompletenessPercent,
      actualPercent: metrics.clearLabelRequiredFieldCompletenessPercent,
      passed: metrics.clearLabelRequiredFieldCompletenessPercent !== null
        && metrics.clearLabelRequiredFieldCompletenessPercent
          >= RELEASE_TARGETS.clearLabelRequiredFieldCompletenessPercent,
    },
  };
  return {
    passed: Object.values(checks).every((check) => check.passed),
    checks,
    externalChecks: {
      automaticSaves: {
        target: 0,
        status: 'ENFORCED_BY_FLUTTER_TEST_GATE',
      },
    },
  };
}

async function evaluateManifest({
  evalDir,
  manifest,
  observer,
  nowMs = () => Date.now(),
  enforceMinimums = true,
  generatedAt = new Date().toISOString(),
}) {
  validateManifest(manifest);
  const manifestMealCases = manifest.cases
    .filter((item) => item.imageType === 'MEAL').length;
  const manifestLabelCases = manifest.cases
    .filter((item) => item.imageType === 'NUTRITION_LABEL').length;
  if (enforceMinimums
    && (manifestMealCases < MIN_MEAL_CASES || manifestLabelCases < MIN_LABEL_CASES)) {
    throw new EvaluationInputError(
      'INSUFFICIENT_EVALUATION_DATA',
      `Evaluation requires at least ${MIN_MEAL_CASES} meal and ${MIN_LABEL_CASES} label cases`,
    );
  }
  let evalRoot;
  try {
    evalRoot = fs.realpathSync(evalDir);
  } catch {
    throw inputError('FOOD_EVAL_DIR is missing or unreadable');
  }
  if (!fs.statSync(evalRoot).isDirectory()) throw inputError('FOOD_EVAL_DIR must be a directory');
  const sortedCases = [...manifest.cases].sort((left, right) => left.caseId.localeCompare(right.caseId));
  const totals = {
    majorExpected: 0,
    majorIdentified: 0,
    clearLabelFieldsRequired: 0,
    clearLabelFieldsComplete: 0,
    usedSecondImage: 0,
    completed: 0,
    failed: 0,
  };
  const calorieErrors = [];
  const latencies = [];
  const errorCodeCounts = new Map();

  for (const item of sortedCases) {
    if (item.imageType === 'MEAL') {
      totals.majorExpected += item.groundTruth.majorComponentFoodIds.length;
    } else if (item.groundTruth.clearLabel) {
      totals.clearLabelFieldsRequired += requiredLabelFieldCount(
        item.groundTruth.confirmation,
      );
    }
    const startedAt = nowMs();
    try {
      const service = createService(observer);
      let review = await service.start(readImage(evalRoot, item.primaryImage));
      if (review.status === 'NEEDS_SECOND_IMAGE') {
        if (!item.secondaryImage) {
          throw new FoodAnalysisError(
            'SECONDARY_IMAGE_REQUIRED',
            'A secondary evaluation image is required.',
            422,
          );
        }
        review = await service.addSecondaryImage(
          review.analysisId,
          readImage(evalRoot, item.secondaryImage.path),
        );
        totals.usedSecondImage += 1;
      }
      if (review.imageType !== item.imageType) {
        throw new FoodAnalysisError('IMAGE_TYPE_MISMATCH', 'Image type mismatch.', 422);
      }
      if (review.status !== 'NEEDS_CONFIRMATION') {
        throw new FoodAnalysisError(review.status, 'Evaluation did not reach confirmation.', 422);
      }

      if (item.imageType === 'MEAL') {
        const observedMajorIds = new Set((review.components || [])
          .filter((component) => component.isMajor && component.matchedFoodId)
          .map((component) => component.matchedFoodId));
        totals.majorIdentified += item.groundTruth.majorComponentFoodIds
          .filter((foodId) => observedMajorIds.has(foodId)).length;
      } else if (item.groundTruth.clearLabel) {
        const completeness = labelCompleteness(
          review.labelFacts,
          item.groundTruth.confirmation,
        );
        totals.clearLabelFieldsComplete += completeness.complete;
      }

      const result = await service.confirm(
        review.analysisId,
        item.groundTruth.confirmation,
      );
      const expectedCalories = item.groundTruth.weighedNutrition.calories;
      const calorieError = Math.abs(result.estimate.calories.mid - expectedCalories)
        / expectedCalories * 100;
      calorieErrors.push(calorieError);
      totals.completed += 1;
    } catch (error) {
      const code = normalizedErrorCode(error);
      errorCodeCounts.set(code, (errorCodeCounts.get(code) || 0) + 1);
      totals.failed += 1;
    } finally {
      const duration = nowMs() - startedAt;
      latencies.push(Math.max(0, Math.round(Number.isFinite(duration) ? duration : 0)));
    }
  }

  const caseCounts = {
    total: sortedCases.length,
    meal: manifestMealCases,
    label: manifestLabelCases,
    completed: totals.completed,
    failed: totals.failed,
  };
  const metrics = {
    majorComponentIdentificationRatePercent: percentage(
      totals.majorIdentified,
      totals.majorExpected,
    ),
    medianAbsoluteCalorieErrorPercent: median(calorieErrors),
    within35PercentCalorieErrorPercent: percentage(
      calorieErrors.filter((value) => value <= 35).length,
      sortedCases.length,
    ),
    clearLabelRequiredFieldCompletenessPercent: percentage(
      totals.clearLabelFieldsComplete,
      totals.clearLabelFieldsRequired,
    ),
    secondImageRatePercent: percentage(totals.usedSecondImage, sortedCases.length),
    errorCodeCounts: Object.fromEntries([...errorCodeCounts.entries()]
      .sort(([left], [right]) => left.localeCompare(right))),
    latencyMs: {
      p50: percentile(latencies, 0.5),
      p95: percentile(latencies, 0.95),
    },
  };
  const report = {
    schemaVersion: 1,
    generatedAt,
    caseCounts,
    metrics,
  };
  report.releaseGate = assessReleaseGate(report, { enforceMinimums });
  return report;
}

function aggregateReport(report) {
  return {
    schemaVersion: report.schemaVersion,
    generatedAt: report.generatedAt,
    caseCounts: report.caseCounts,
    metrics: report.metrics,
    releaseGate: report.releaseGate,
  };
}

function writeAggregateReport(report, outputDir) {
  fs.mkdirSync(outputDir, { recursive: true });
  const stamp = requireString(report.generatedAt, 'generatedAt', 40).replace(/[^0-9TZ]/g, '');
  const outputPath = path.join(outputDir, `food-photo-evaluation-${stamp}.json`);
  fs.writeFileSync(outputPath, `${JSON.stringify(aggregateReport(report), null, 2)}\n`, {
    encoding: 'utf8',
    flag: 'wx',
  });
  return outputPath;
}

async function runCli() {
  require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
  const requestedDir = process.env.FOOD_EVAL_DIR;
  if (!requestedDir) throw inputError('FOOD_EVAL_DIR is required');
  const { evalRoot, manifest } = loadPrivateManifest(requestedDir);
  const observer = new GeminiFoodObserver({
    apiKey: process.env.GEMINI_API_KEY,
    model: process.env.GEMINI_MODEL || 'gemini-2.5-pro',
  });
  const report = await evaluateManifest({ evalDir: evalRoot, manifest, observer });
  writeAggregateReport(report, path.join(__dirname, 'results'));
  process.stdout.write(`${JSON.stringify(aggregateReport(report), null, 2)}\n`);
  return report.releaseGate.passed ? 0 : 1;
}

if (require.main === module) {
  runCli()
    .then((exitCode) => {
      process.exitCode = exitCode;
    })
    .catch((error) => {
      const code = error instanceof EvaluationInputError
        ? error.code
        : normalizedErrorCode(error);
      process.stderr.write(`Food evaluation failed: ${code}\n`);
      process.exitCode = 1;
    });
}

module.exports = {
  EvaluationInputError,
  RELEASE_TARGETS,
  assessReleaseGate,
  evaluateManifest,
  loadPrivateManifest,
  validateManifest,
  writeAggregateReport,
};
