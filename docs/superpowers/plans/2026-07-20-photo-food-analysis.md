# Photo Food Analysis Implementation Plan

> **Historical plan — contract superseded 2026-08-04.** Keep this file as implementation history. The legacy barcode and AI Coach routes described below are no longer runtime contracts; use [`../../online-integrations-and-release-hardening.md`](../../online-integrations-and-release-hardening.md) for the current surface.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace barcode scanning as the primary nutrition action with a consent-gated photo workflow that recognizes meals or nutrition labels, asks for a second photo only when needed, lets the user correct familiar portions, calculates deterministic nutrition ranges, and saves only a confirmed midpoint.

**Architecture:** Add three new Express endpoints beside the legacy endpoints. Gemini/OCR produces validated observations only; a pure deterministic estimator owns all nutrition arithmetic. An in-memory 15-minute session store retains structured observations but never image bytes. The Flutter client adds typed photo-analysis contracts, a Riverpod notifier dedicated to this workflow, camera/image preprocessing behind testable interfaces, and a Drift v3 migration that preserves existing history while attaching estimate metadata to camera-derived logs.

**Tech Stack:** Flutter/Dart, Riverpod 3, Dio, official `camera` plugin, Dart `image`, Drift/SQLite, Node.js CommonJS, Express 4, Multer memory storage, Zod, Node test runner, Supertest, Gemini REST API.

## Global Constraints

- Work in the current repository and preserve unrelated user changes. Before every commit, inspect `git status --short` and stage only the files named by that task.
- Follow red-green-refactor: add a focused failing test, run it and confirm the expected failure, implement the smallest production change, then rerun the focused test.
- Keep `/api/analyze-food`, `/api/scan-barcode`, and `/api/register-barcode` working. This release removes barcode only from the primary Flutter UI.
- Never persist or log uploaded bytes, base64, EXIF, provider prompts/responses, food names, free-form corrections, or nutrition history.
- Initial image analysis may return only `NEEDS_SECOND_IMAGE`, `NEEDS_CONFIRMATION`, or `UNRECOGNIZED`. Only confirmation may return `READY`.
- The provider may identify image type, components, label text, and confidence. It must not supply the final calories or macros used by the app.
- Use these thresholds exactly: first-image major-component confidence below `0.60` requests a second photo; after a second photo, confidence below `0.55` requires manual completion before estimation.
- Accept only JPEG, PNG, or WebP; verify magic bytes; reject files over 5 MB; keep Multer in memory.
- A successful upload must release image bytes after the request. The session store may retain only validated structured observations and bounded metadata for 15 minutes.
- The Flutter app re-encodes captures before upload to normalize format and remove EXIF. Pending bytes live only in the notifier while retry is possible and are cleared after success, cancel, or dispose.
- Existing midpoint columns continue driving daily totals. New min/max/confidence/source/image-type/summary fields are nullable or defaulted so migration preserves all rows.
- Generated Drift or Freezed files must be produced by `dart run build_runner build --delete-conflicting-outputs`; never edit generated files by hand.
- Real camera behavior requires a physical Android device. Unit/widget/build verification must not be described as physical-camera verification.

## Canonical Contract

Use these values consistently in JavaScript JSON, Dart parsing, Drift strings, tests, and UI:

```text
imageType: MEAL | NUTRITION_LABEL | UNKNOWN
status: NEEDS_SECOND_IMAGE | NEEDS_CONFIRMATION | READY | UNRECOGNIZED
confidenceLevel: HIGH | MEDIUM | LOW
portion.kind: HOUSEHOLD | GRAMS
portion.unit: BOWL | PIECE | SPOON | SERVING
portion.size: SMALL | MEDIUM | LARGE
labelBasis: PER_100G | PER_SERVING | UNKNOWN
labelConsumed.kind: GRAMS | SERVINGS
source: MANUAL | CAMERA_ANALYSIS
```

All failures use:

```json
{
  "error": {
    "code": "INVALID_IMAGE",
    "message": "Ảnh không hợp lệ.",
    "details": {}
  }
}
```

The initial and secondary-image response is:

```json
{
  "analysisId": "uuid",
  "imageType": "MEAL",
  "status": "NEEDS_CONFIRMATION",
  "components": [
    {
      "id": "component-1",
      "nameVi": "Cơm trắng",
      "matchedFoodId": "white-rice",
      "confidence": 0.91,
      "isMajor": true,
      "requiresManualPortion": false,
      "suggestedPortion": {
        "kind": "HOUSEHOLD",
        "unit": "BOWL",
        "quantity": 1,
        "size": "MEDIUM"
      }
    }
  ],
  "labelFacts": null,
  "confidence": 0.82,
  "uncertaintyReasons": ["Có thể có dầu hoặc nước sốt bị che khuất."],
  "expiresAt": "2026-07-20T10:15:00.000Z"
}
```

For `NUTRITION_LABEL`, `components` is null and `labelFacts` has this exact shape:

```json
{
  "nameVi": "Tên sản phẩm",
  "basis": "PER_100G",
  "facts": {
    "calories": 498,
    "proteinGrams": 4.4,
    "carbsGrams": 49.8,
    "fatGrams": 31.1
  },
  "servingSizeGrams": null,
  "servingsPerContainer": null,
  "netWeightGrams": 57,
  "confidence": 0.94,
  "missingFields": []
}
```

Any fact that OCR cannot establish is null and named in bounded `missingFields`. For `MEAL`, `labelFacts` is null. The provider returns a component name; `FoodAnalysisService` adds nullable `matchedFoodId` by querying `FoodDatabase`, so the provider never invents internal food IDs.

The confirmation response is:

```json
{
  "analysisId": "uuid",
  "imageType": "MEAL",
  "status": "READY",
  "nameVi": "Cơm với ức gà",
  "estimate": {
    "calories": {"min": 430, "mid": 505, "max": 580},
    "proteinGrams": {"min": 34, "mid": 39, "max": 44},
    "carbsGrams": {"min": 48, "mid": 55, "max": 62},
    "fatGrams": {"min": 8, "mid": 12, "max": 16}
  },
  "confidenceLevel": "MEDIUM",
  "uncertaintyReasons": ["Lượng dầu không nhìn thấy rõ."],
  "calculationSummary": "1 bát cơm vừa + 1 phần ức gà vừa; khoảng được nới rộng do dầu."
}
```

The meal confirmation body is:

```json
{
  "kind": "MEAL",
  "nameVi": "Cơm với ức gà",
  "components": [
    {
      "observationId": "component-1",
      "foodId": "white-rice",
      "nameVi": "Cơm trắng",
      "portion": {
        "kind": "HOUSEHOLD",
        "unit": "BOWL",
        "quantity": 1,
        "size": "MEDIUM"
      }
    }
  ]
}
```

The label confirmation body is:

```json
{
  "kind": "NUTRITION_LABEL",
  "nameVi": "Tên sản phẩm",
  "basis": "PER_100G",
  "facts": {
    "calories": 498,
    "proteinGrams": 4.4,
    "carbsGrams": 49.8,
    "fatGrams": 31.1
  },
  "consumed": {"kind": "GRAMS", "amount": 57}
}
```

---

### Task 1: Build the deterministic nutrition core

**Files:**

- Modify: `server/package.json`
- Modify: `server/package-lock.json`
- Create: `server/data/vietnamese_foods.json`
- Create: `server/data/README.md`
- Create: `server/src/food-analysis/contracts.js`
- Create: `server/src/food-analysis/food_database.js`
- Create: `server/src/food-analysis/nutrition_estimator.js`
- Create: `server/test/nutrition_estimator_test.js`

- [ ] **Step 1: Add backend test and validation dependencies**

From `server/`, run:

```powershell
npm install zod
npm install --save-dev supertest
npm pkg set scripts.test="node --test"
```

Expected: `package.json` contains `zod`, `supertest`, and a `test` script; the lockfile changes only because of these packages.

- [ ] **Step 2: Write failing estimator tests**

Cover all arithmetic branches in `server/test/nutrition_estimator_test.js`:

```js
const test = require('node:test');
const assert = require('node:assert/strict');
const { NutritionEstimator } = require('../src/food-analysis/nutrition_estimator');
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

test('calculates a per-100g label for consumed grams', () => {
  const result = estimator.estimateLabel({
    nameVi: 'Snack',
    basis: 'PER_100G',
    facts: {
      calories: 498,
      proteinGrams: 4.4,
      carbsGrams: 49.8,
      fatGrams: 31.1,
    },
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
    facts: {
      calories: 120,
      proteinGrams: 5,
      carbsGrams: 18,
      fatGrams: 3,
    },
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
      observationId: 'component-1',
      foodId: 'white-rice',
      nameVi: 'Cơm trắng',
      portion: {
        kind: 'HOUSEHOLD',
        unit: 'BOWL',
        quantity: 1,
        size: 'MEDIUM',
      },
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
      observationId: 'component-1',
      foodId: 'white-rice',
      nameVi: 'Cơm trắng',
      portion: { kind: 'GRAMS', grams: 150 },
    }],
    uncertaintyReasons: ['HIDDEN_OIL'],
  });

  assert.ok(result.estimate.calories.min < result.estimate.calories.mid);
  assert.ok(result.estimate.calories.max > result.estimate.calories.mid);
});

test('rejects unknown foods and implausible nutrition', () => {
  assert.throws(
    () => estimator.estimateMeal({
      nameVi: 'Không rõ',
      components: [{
        observationId: 'component-1',
        foodId: 'missing',
        nameVi: 'Không rõ',
        portion: { kind: 'GRAMS', grams: 100 },
      }],
      uncertaintyReasons: [],
    }),
    (error) => error.code === 'DATABASE_NO_MATCH',
  );

  assert.throws(
    () => estimator.estimateLabel({
      nameVi: 'Sai',
      basis: 'PER_100G',
      facts: {
        calories: 9000,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
      },
      consumed: { kind: 'GRAMS', amount: 100 },
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});
```

Also add tests for serving count, net-weight conversion, negative/NaN values, empty components, quantity bounds, ambiguous label basis, macro-derived calorie plausibility, and rounding to one decimal for macros/integer calories.

- [ ] **Step 3: Run the focused test and confirm red**

```powershell
node --test test/nutrition_estimator_test.js
```

Expected: FAIL with `MODULE_NOT_FOUND` for `nutrition_estimator`.

- [ ] **Step 4: Create strict boundary schemas and errors**

In `contracts.js`, export Zod schemas for provider observations, meal confirmation, label confirmation, analysis statuses, and estimates. Apply bounded values:

```js
const { z } = require('zod');

const finiteNonNegative = z.number().finite().min(0);
const portionSchema = z.discriminatedUnion('kind', [
  z.object({
    kind: z.literal('HOUSEHOLD'),
    unit: z.enum(['BOWL', 'PIECE', 'SPOON', 'SERVING']),
    quantity: z.number().finite().positive().max(20),
    size: z.enum(['SMALL', 'MEDIUM', 'LARGE']),
  }).strict(),
  z.object({
    kind: z.literal('GRAMS'),
    grams: z.number().finite().positive().max(5000),
  }).strict(),
]);

const nutrientFactsSchema = z.object({
  calories: finiteNonNegative.max(1000),
  proteinGrams: finiteNonNegative.max(100),
  carbsGrams: finiteNonNegative.max(100),
  fatGrams: finiteNonNegative.max(100),
}).strict();

module.exports = {
  portionSchema,
  nutrientFactsSchema,
  mealConfirmationSchema,
  labelConfirmationSchema,
  providerObservationSchema,
};
```

Define one `FoodAnalysisError` class in this file with `code`, Vietnamese `message`, `httpStatus`, and bounded `details`. Never put raw Zod/provider payloads into `details`.

- [ ] **Step 5: Extract curated records and implement pure estimation**

Copy the existing values from `server/server.js` to `server/data/vietnamese_foods.json` without silently changing their nutrient values. Keep the legacy constant untouched in this release so the old endpoint remains stable. Give each new record:

```json
{
  "id": "white-rice",
  "nameVi": "Cơm trắng",
  "aliases": ["cơm", "cơm trắng"],
  "nutrientsPer100g": {
    "calories": 130,
    "proteinGrams": 2.7,
    "carbsGrams": 28,
    "fatGrams": 0.3
  },
  "householdPortions": {
    "BOWL": {
      "SMALL": {"minGrams": 90, "midGrams": 110, "maxGrams": 130},
      "MEDIUM": {"minGrams": 130, "midGrams": 150, "maxGrams": 170},
      "LARGE": {"minGrams": 170, "midGrams": 200, "maxGrams": 230}
    }
  }
}
```

`FoodDatabase.match(name)` must normalize Vietnamese tones but must not fuzzy-match generic `thịt`, `cá`, or `trứng` to a specific food. `NutritionEstimator` must:

1. validate confirmation;
2. map household portions to min/mid/max grams;
3. sum nutrients using curated data;
4. widen meal ranges for bounded codes such as `HIDDEN_OIL`, `SAUCE`, `OVERLAP`, or `WEAK_DATABASE_MATCH`;
5. compute label arithmetic without range widening when all printed facts are explicit;
6. reject implausible values and calorie/macro disagreement outside a documented tolerance;
7. return range objects with `min <= mid <= max`;
8. generate a concise Vietnamese calculation summary from confirmed quantities only.

`server/data/README.md` must record that the initial records were migrated from the existing in-repo lookup table, identify the source/verification status of every later record, and prohibit adding unreferenced nutritional values.

- [ ] **Step 6: Run tests and commit**

```powershell
npm test
git status --short
git add package.json package-lock.json data/vietnamese_foods.json data/README.md src/food-analysis/contracts.js src/food-analysis/food_database.js src/food-analysis/nutrition_estimator.js test/nutrition_estimator_test.js
git commit -m "feat(server): add deterministic food estimator"
```

Expected: all Node tests pass; the commit contains only Task 1 files.

---

### Task 2: Add validated observation, session, and confidence workflow

**Files:**

- Create: `server/src/food-analysis/analysis_session_store.js`
- Create: `server/src/food-analysis/gemini_food_observer.js`
- Create: `server/src/food-analysis/food_analysis_service.js`
- Create: `server/test/analysis_session_store_test.js`
- Create: `server/test/food_analysis_service_test.js`
- Create: `server/test/gemini_food_observer_test.js`

- [ ] **Step 1: Write failing session and service tests**

Use injected clock, UUID generator, observer, and estimator. The fake observer returns validated structures, never totals.

```js
test('first image below 0.60 requests a second image', async () => {
  const observer = new FakeObserver({
    imageType: 'MEAL',
    confidence: 0.58,
    uncertaintyReasons: ['OVERLAP'],
    components: [{
      id: 'c1',
      nameVi: 'Cơm trắng',
      confidence: 0.58,
      isMajor: true,
      suggestedPortion: {
        kind: 'HOUSEHOLD',
        unit: 'BOWL',
        quantity: 1,
        size: 'MEDIUM',
      },
    }],
    labelFacts: null,
  });
  const service = makeService({ observer });

  const response = await service.start({
    bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
    mimeType: 'image/jpeg',
  });

  assert.equal(response.status, 'NEEDS_SECOND_IMAGE');
  assert.equal(response.analysisId, 'analysis-1');
  assert.equal(service.sessionStore.peek('analysis-1').imageBytes, undefined);
});

test('first image at 0.60 goes directly to confirmation', async () => {
  const service = makeService({ observer: mealObserverAt(0.60) });
  const response = await service.start(validJpeg());
  assert.equal(response.status, 'NEEDS_CONFIRMATION');
});

test('second image below 0.55 marks low-confidence components manual', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.40), mealObservation(0.54)]),
  });
  const started = await service.start(validJpeg());
  const response = await service.addSecondaryImage(started.analysisId, validJpeg());
  assert.equal(response.status, 'NEEDS_CONFIRMATION');
  assert.equal(response.components[0].requiresManualPortion, true);
});

test('confirmation is rejected until manual low-confidence fields are complete', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.40), mealObservation(0.54)]),
  });
  const started = await service.start(validJpeg());
  await service.addSecondaryImage(started.analysisId, validJpeg());
  await assert.rejects(
    service.confirm(started.analysisId, incompleteMealConfirmation()),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});
```

Add tests for:

- clear label -> `NEEDS_CONFIRMATION`;
- ambiguous basis -> `NEEDS_SECOND_IMAGE`;
- unknown image -> `UNRECOGNIZED`;
- image can be added only once and only in `NEEDS_SECOND_IMAGE`;
- confirmation only in `NEEDS_CONFIRMATION`;
- expired and unguessable IDs -> `ANALYSIS_EXPIRED`/`ANALYSIS_UNAVAILABLE`;
- confirmation returns `READY` from the estimator;
- session is deleted after successful confirmation;
- session remains usable after a correctable confirmation error;
- no `Buffer`, base64, prompt, or raw provider response is present in the store.

- [ ] **Step 2: Run focused tests and confirm red**

```powershell
node --test test/analysis_session_store_test.js test/food_analysis_service_test.js
```

Expected: FAIL because the new modules do not exist.

- [ ] **Step 3: Implement the 15-minute structured session store**

The store contract is:

```js
class AnalysisSessionStore {
  constructor({
    now = () => Date.now(),
    ttlMs = 15 * 60 * 1000,
    idFactory = () => require('node:crypto').randomUUID(),
  } = {}) {}

  create({ imageType, status, observation, usedSecondImage }) {}
  get(id) {}
  update(id, next) {}
  delete(id) {}
  sweepExpired() {}
}
```

`create` copies only validated JSON-safe fields and returns an ISO `expiresAt`. `get` distinguishes malformed/missing IDs from expired known IDs without revealing internal data. Bound the map to a configured maximum; sweep expired sessions before rejecting with `ANALYSIS_UNAVAILABLE`.

- [ ] **Step 4: Implement a provider adapter with strict output validation**

`GeminiFoodObserver` exposes:

```js
class GeminiFoodObserver {
  constructor({ apiKey, model, fetchImpl = fetch, timeoutMs = 30_000 }) {}

  async observePrimary({ bytes, mimeType }) {}

  async observeSecondary({ bytes, mimeType, previousObservation }) {}
}
```

The prompt requests only `imageType`, observations, confidence, and uncertainty codes. It explicitly forbids final calories/macros. Parse fenced or plain JSON, then call `providerObservationSchema.safeParse`. Convert timeout/unavailable/malformed output to stable `ANALYSIS_UNAVAILABLE` or `INVALID_PROVIDER_RESPONSE` errors. Do not return prompt text or raw output to the caller and do not log either.

- [ ] **Step 5: Implement orchestration and thresholds**

`FoodAnalysisService`:

```js
class FoodAnalysisService {
  constructor({ observer, estimator, sessionStore, logger }) {}

  async start({ bytes, mimeType, requestId }) {}
  async addSecondaryImage(analysisId, { bytes, mimeType, requestId }) {}
  async confirm(analysisId, confirmation, { requestId } = {}) {}
}
```

Keep the byte buffer in a local variable only for the awaited provider call. Store the validated observation after the call returns. Compare only major components for the `0.60`/`0.55` meal thresholds. For labels, require basis plus all four nutrient fields and a consumed amount; request a second image when OCR has not established those fields. After the second image, expose missing fields for manual correction rather than looping.

- [ ] **Step 6: Verify malformed provider responses**

```powershell
node --test test/gemini_food_observer_test.js
node --test test/analysis_session_store_test.js test/food_analysis_service_test.js
```

Expected: PASS, including timeout and malformed JSON tests using fake `fetchImpl`.

- [ ] **Step 7: Commit**

```powershell
git add src/food-analysis/analysis_session_store.js src/food-analysis/gemini_food_observer.js src/food-analysis/food_analysis_service.js test/analysis_session_store_test.js test/food_analysis_service_test.js test/gemini_food_observer_test.js
git commit -m "feat(server): orchestrate photo food analysis"
```

---

### Task 3: Expose secure photo-analysis HTTP endpoints and bounded telemetry

**Files:**

- Create: `server/src/http/api_error.js`
- Create: `server/src/http/image_signature.js`
- Create: `server/src/http/analysis_logger.js`
- Create: `server/src/food-analysis/router.js`
- Modify: `server/server.js`
- Create: `server/test/food_analysis_routes_test.js`
- Create: `server/test/analysis_logger_test.js`

- [ ] **Step 1: Write failing Supertest contract tests**

Build a minimal Express app around `createFoodAnalysisRouter` with a fake service:

```js
const request = require('supertest');
const express = require('express');
const { createFoodAnalysisRouter } = require('../src/food-analysis/router');

function testApp(service) {
  const app = express();
  app.use(express.json({ limit: '32kb' }));
  app.use('/api/food-analyses', createFoodAnalysisRouter({
    service,
    logger: { event() {} },
    rateLimitOptions: { windowMs: 60_000, limit: 1000 },
  }));
  return app;
}

test('starts an analysis with the primaryImage field', async () => {
  const response = await request(testApp(fakeService()))
    .post('/api/food-analyses')
    .attach('primaryImage', Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {
      filename: 'meal.jpg',
      contentType: 'image/jpeg',
    });

  assert.equal(response.status, 201);
  assert.equal(response.body.status, 'NEEDS_CONFIRMATION');
});

test('rejects a spoofed mime type using magic bytes', async () => {
  const response = await request(testApp(fakeService()))
    .post('/api/food-analyses')
    .attach('primaryImage', Buffer.from('not-an-image'), {
      filename: 'meal.jpg',
      contentType: 'image/jpeg',
    });

  assert.equal(response.status, 400);
  assert.deepEqual(response.body, {
    error: {
      code: 'INVALID_IMAGE',
      message: 'Ảnh không hợp lệ.',
      details: {},
    },
  });
});
```

Add tests for PNG/WebP signatures, unsupported GIF/HEIC, wrong multipart field, missing file, over-5-MB upload, invalid JSON confirmation, expired analysis, second-image wrong state, provider timeout, rate-limit error shape, and `NEEDS_SECOND_IMAGE` as a successful 201/200 response rather than an error.

- [ ] **Step 2: Confirm tests fail**

```powershell
node --test test/food_analysis_routes_test.js
```

Expected: FAIL because `router.js` does not exist.

- [ ] **Step 3: Implement signature checking and one error mapper**

`detectImageType(buffer)` must recognize:

```text
JPEG: FF D8 FF
PNG:  89 50 4E 47 0D 0A 1A 0A
WebP: "RIFF" at 0 and "WEBP" at 8
```

Use `multer.memoryStorage()` with `limits.fileSize = 5 * 1024 * 1024` and a one-file limit. Normalize all Multer, Zod, service, and rate-limit errors through `sendApiError(res, error)`. Do not echo filenames, MIME headers, validation input, stack traces, or provider responses.

- [ ] **Step 4: Implement the router**

Export:

```js
function createFoodAnalysisRouter({
  service,
  logger,
  rateLimitOptions = { windowMs: 10 * 60 * 1000, limit: 10 },
}) {}
```

Routes:

```text
POST /                       multipart primaryImage   -> 201
POST /:analysisId/images     multipart secondaryImage -> 200
POST /:analysisId/confirmations JSON                  -> 200
```

Create a correlation ID with `crypto.randomUUID()` per request. Clear `req.file.buffer` in a `finally` block after awaiting the service:

```js
finally {
  if (req.file?.buffer) {
    req.file.buffer.fill(0);
    req.file.buffer = null;
  }
}
```

Do not write uploads to disk or call `fs` from any new photo-analysis module.

- [ ] **Step 5: Add privacy-safe structured events**

`AnalysisLogger.event(name, fields)` writes one JSON line with allowlisted fields only:

```text
requestId, event, imageType, status, confidenceBucket,
errorCode, usedSecondImage, componentCorrectionBucket,
portionCorrectionBucket, rangeWidthBucket, durationBucket
```

Buckets are bounded enums, never raw values or labels. The service emits:

- `food_analysis_completed`;
- `food_analysis_failed`;
- `food_analysis_confirmation_completed`.

Test that attempted `nameVi`, `image`, `prompt`, `history`, and arbitrary fields are discarded. Compare confirmations to observations only to emit `NONE`, `ONE`, or `MULTIPLE` correction buckets.

- [ ] **Step 6: Mount the router without changing legacy contracts**

In `server/server.js`:

1. import the new components;
2. create the database, estimator, observer, store, service, and logger once;
3. mount `app.use('/api/food-analyses', router)` before the final error handling/listen;
4. keep existing endpoints intact;
5. wrap startup so tests can import the app:

```js
if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server Gym App Backend đang chạy tại http://localhost:${port}`);
  });
}

module.exports = { app };
```

Do not log whether the Gemini key value itself exists. If it is absent, the new observer returns `ANALYSIS_UNAVAILABLE`.

- [ ] **Step 7: Verify HTTP and legacy startup**

```powershell
npm test
node -e "const { app } = require('./server'); if (!app) process.exit(1)"
```

Expected: all tests pass and importing `server.js` exits without opening a port.

- [ ] **Step 8: Commit**

```powershell
git add server.js src/http/api_error.js src/http/image_signature.js src/http/analysis_logger.js src/food-analysis/router.js test/food_analysis_routes_test.js test/analysis_logger_test.js
git commit -m "feat(server): expose secure food photo API"
```

---

### Task 4: Add typed Flutter photo-analysis contracts and Dio client calls

**Files:**

- Create: `flutter/lib/core/model/food_photo_analysis_models.dart`
- Modify: `flutter/lib/data/remote/food_analysis_client.dart`
- Modify: `flutter/lib/data/providers/remote_providers.dart`
- Create: `flutter/test/data/remote/food_analysis_client_test.dart`

- [ ] **Step 1: Write failing JSON and Dio tests**

Use a custom Dio `HttpClientAdapter` so no network is used. Assert:

- every canonical enum parses and unknown enum values throw `FoodAnalysisFormatException`;
- nullable `components`/`labelFacts` follow the discriminated `imageType`;
- range invariants reject `min > mid` or `mid > max`;
- `startPhotoAnalysis` sends `primaryImage`;
- `addSecondaryPhoto` sends `secondaryImage`;
- `confirmAnalysis` sends JSON to the correct analysis ID;
- the typed API error preserves bounded `code`, Vietnamese `message`, and `details`;
- timeout maps to `ANALYSIS_UNAVAILABLE`;
- `cancelPending()` cancels active photo calls;
- legacy `analyze`, `scanBarcode`, and `registerBarcode` remain callable.

The client interface must become:

```dart
abstract class FoodAnalysisClient {
  Future<FoodAnalysisReview> startPhotoAnalysis(PreparedUpload upload);
  Future<FoodAnalysisReview> addSecondaryPhoto(
    String analysisId,
    PreparedUpload upload,
  );
  Future<FoodAnalysisReady> confirmAnalysis(
    String analysisId,
    FoodAnalysisConfirmation confirmation,
  );
  void cancelPending();

  // Compatibility until the separate barcode cleanup.
  Future<ScanResult?> analyze(Uint8List imageBytes);
  Future<ScanResult?> scanBarcode(String barcode);
  Future<bool> registerBarcode(String barcode, ScanResult result);
}
```

- [ ] **Step 2: Confirm red**

```powershell
flutter test test/data/remote/food_analysis_client_test.dart
```

Expected: FAIL because the typed model file and methods do not exist.

- [ ] **Step 3: Implement immutable domain objects and strict parsing**

Use plain immutable Dart classes to avoid generated JSON accepting malformed values. Define:

```dart
enum FoodImageType { meal, nutritionLabel, unknown }
enum FoodAnalysisStatus {
  needsSecondImage,
  needsConfirmation,
  ready,
  unrecognized,
}
enum AnalysisConfidenceLevel { high, medium, low }

final class NutritionRange {
  final double min;
  final double mid;
  final double max;

  const NutritionRange({
    required this.min,
    required this.mid,
    required this.max,
  }) : assert(min <= mid && mid <= max);
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
```

Also define `ObservedFoodComponent`, `ObservedLabelFacts`, `FoodAnalysisReview`, `MealConfirmation`, `LabelConfirmation`, `HouseholdPortion`, `GramPortion`, `NutritionEstimate`, `FoodAnalysisReady`, `FoodAnalysisApiException`, and `FoodAnalysisFormatException`. Parsing must require ISO `expiresAt`, 0–1 confidence, non-empty IDs, finite non-negative nutrients, and the response shape appropriate to its discriminator.

- [ ] **Step 4: Implement Dio multipart and cancellation**

Change the new endpoint provider to return the backend base URL, not the old `/api/analyze-food` URL. Keep a private `Set<CancelToken>`; add/remove tokens in `try/finally`, and make `cancelPending()` cancel then clear the set. Parse the nested error shape:

```dart
final error = errorData['error'];
if (error is Map<String, dynamic>) {
  throw FoodAnalysisApiException(
    code: error['code'] as String? ?? 'ANALYSIS_UNAVAILABLE',
    message: error['message'] as String? ??
        'Không thể phân tích ảnh lúc này.',
    details: (error['details'] as Map?)?.cast<String, Object?>() ?? const {},
  );
}
```

The photo methods throw typed exceptions; they must not return `null`. The three legacy methods preserve their current behavior.

- [ ] **Step 5: Verify and commit**

```powershell
dart format lib/core/model/food_photo_analysis_models.dart lib/data/remote/food_analysis_client.dart lib/data/providers/remote_providers.dart test/data/remote/food_analysis_client_test.dart
flutter test test/data/remote/food_analysis_client_test.dart
git add lib/core/model/food_photo_analysis_models.dart lib/data/remote/food_analysis_client.dart lib/data/providers/remote_providers.dart test/data/remote/food_analysis_client_test.dart
git commit -m "feat(flutter): add food photo API client"
```

---

### Task 5: Persist confirmed ranges with a Drift v3 migration

**Files:**

- Modify: `flutter/lib/data/local/tables/logged_foods.dart`
- Modify: `flutter/lib/data/local/database.dart`
- Modify: `flutter/lib/data/local/database.g.dart` (generated)
- Modify: `flutter/lib/data/local/daos/logged_food_dao.g.dart` (generated only if changed)
- Modify: `flutter/lib/data/repositories/nutrition_repository.dart`
- Modify: `flutter/lib/data/repositories/drift_nutrition_repository.dart`
- Modify: `flutter/test/feature/home/home_view_model_test.dart`
- Modify: `flutter/test/feature/profile/profile_view_model_test.dart`
- Modify: `flutter/test/feature/today/today_view_model_test.dart`
- Create: `flutter/test/data/photo_nutrition_persistence_test.dart`
- Create: `flutter/test/data/database_migration_v3_test.dart`

- [ ] **Step 1: Write failing atomic persistence tests**

Add a `PhotoNutritionLog` input type in the repository file:

```dart
final class PhotoNutritionLog {
  final String name;
  final String mealTime;
  final FoodImageType imageType;
  final NutritionEstimate estimate;
  final AnalysisConfidenceLevel confidenceLevel;
  final String calculationSummary;

  const PhotoNutritionLog({
    required this.name,
    required this.mealTime,
    required this.imageType,
    required this.estimate,
    required this.confidenceLevel,
    required this.calculationSummary,
  });
}
```

Extend the interface without changing manual logging:

```dart
Future<void> logPhotoEstimate({
  required int epochDay,
  required PhotoNutritionLog log,
});
```

Test that:

1. no row exists before this method;
2. one call inserts exactly one `logged_foods` row;
3. existing columns receive rounded midpoint values;
4. min/max, confidence, image type, source, and summary match;
5. daily totals increase by midpoint only;
6. a forced DAO failure rolls back both row and totals;
7. delete subtracts midpoint and removes metadata with the row;
8. manual `logFood` still stores `MANUAL` and null analysis fields.

- [ ] **Step 2: Write a failing v2-to-v3 migration test**

Create a v2 SQLite fixture with one existing logged row, set `PRAGMA user_version = 2`, open it through `GymDatabase`, then assert:

```dart
expect(db.schemaVersion, 3);
final row = (await db.select(db.loggedFoods).get()).single;
expect(row.name, 'Bữa cũ');
expect(row.calories, 500);
expect(row.source, 'MANUAL');
expect(row.calorieMin, isNull);
expect(row.calculationSummary, isNull);
```

Use a temporary database file under the test temp directory and delete it in `tearDown`; do not use or modify the real app database.

- [ ] **Step 3: Confirm red**

```powershell
flutter test test/data/photo_nutrition_persistence_test.dart test/data/database_migration_v3_test.dart
```

Expected: compile failure because the new columns/method do not exist.

- [ ] **Step 4: Add nullable/defaulted columns**

Add:

```dart
TextColumn get source =>
    text().withDefault(const Constant('MANUAL'))();
IntColumn get calorieMin => integer().nullable()();
IntColumn get calorieMax => integer().nullable()();
RealColumn get proteinMinGrams => real().nullable()();
RealColumn get proteinMaxGrams => real().nullable()();
RealColumn get carbsMinGrams => real().nullable()();
RealColumn get carbsMaxGrams => real().nullable()();
RealColumn get fatMinGrams => real().nullable()();
RealColumn get fatMaxGrams => real().nullable()();
TextColumn get analysisConfidence => text().nullable()();
TextColumn get analysisImageType => text().nullable()();
TextColumn get calculationSummary => text().nullable()();
```

Increment `schemaVersion` to 3. In `onUpgrade`, keep the existing `from < 2` block, then for `from < 3` call `m.addColumn` once for each new column. Existing rows receive `MANUAL` from the default and null metadata.

- [ ] **Step 5: Implement atomic photo logging**

Within one `database.transaction`:

1. map `estimate.*.mid` to existing integer midpoint columns using one documented rounding helper;
2. insert the full range metadata and `source = CAMERA_ANALYSIS`;
3. update `daily_nutrition` by midpoint only;
4. set `lastEntrySource = CAMERA_ANALYSIS`.

Validate non-empty names/summaries, range ordering, finite values, and physiological bounds before opening the transaction. Do not persist `analysisId`, images, provider output, or corrections.

- [ ] **Step 6: Generate code and update fakes**

```powershell
dart run build_runner build --delete-conflicting-outputs
rg -l "implements NutritionRepository" test
```

Add a throwing or recorded `logPhotoEstimate` implementation to every listed fake. Do not alter unrelated fake behavior.

- [ ] **Step 7: Verify migration and repository**

```powershell
flutter test test/data/photo_nutrition_persistence_test.dart test/data/database_migration_v3_test.dart
flutter test test/data/database_test.dart
```

Expected: PASS, with the old row preserved and daily totals changed by midpoint only.

- [ ] **Step 8: Commit**

```powershell
git add lib/data/local/tables/logged_foods.dart lib/data/local/database.dart lib/data/local/database.g.dart lib/data/local/daos/logged_food_dao.g.dart lib/data/repositories/nutrition_repository.dart lib/data/repositories/drift_nutrition_repository.dart test/data/photo_nutrition_persistence_test.dart test/data/database_migration_v3_test.dart
git add test/feature/home/home_view_model_test.dart test/feature/profile/profile_view_model_test.dart test/feature/today/today_view_model_test.dart
git commit -m "feat(flutter): persist photo nutrition ranges"
```

Before committing, inspect `git diff --cached --name-only`; remove any unrelated generated files from the index.

---

### Task 6: Add metadata-free photo preprocessing and camera capture

**Files:**

- Modify: `flutter/pubspec.yaml`
- Modify: `flutter/pubspec.lock`
- Modify: `flutter/ios/Runner/Info.plist`
- Create: `flutter/lib/feature/nutrition/photo/food_photo_preprocessor.dart`
- Create: `flutter/lib/feature/nutrition/photo/food_camera_gateway.dart`
- Create: `flutter/lib/feature/nutrition/photo/food_capture_screen.dart`
- Create: `flutter/test/feature/nutrition/photo/food_photo_preprocessor_test.dart`
- Create: `flutter/test/feature/nutrition/photo/food_capture_screen_test.dart`

- [ ] **Step 1: Add compatible official packages**

```powershell
flutter pub add camera image
```

Expected: `pubspec.yaml` and `pubspec.lock` select versions compatible with the installed Flutter/Dart SDK. Do not manually force a newer SDK or raise min SDK.

- [ ] **Step 2: Write failing preprocessing tests**

Generate deterministic in-memory images with `package:image` and test:

- decoded width or height below 640 -> `IMAGE_TOO_SMALL`;
- mean luminance below the configured threshold -> `IMAGE_TOO_DARK`;
- Laplacian variance below the configured blur threshold -> `IMAGE_TOO_BLURRY`;
- a configured excessive contiguous clipped-light/clipped-dark region -> `MAJOR_OCCLUSION`;
- clear, lit image -> `PreparedUpload` under 5 MB;
- output is JPEG with the expected magic bytes;
- output dimensions are capped at 1600 px on the long edge;
- metadata fields from the input are absent after decode/orientation bake/new-image copy/re-encode;
- original bytes are not retained by the result object after replacement.

The API is:

```dart
enum PhotoQualityIssue {
  tooSmall,
  tooDark,
  tooBlurry,
  majorOcclusion,
}

final class PhotoPreparationResult {
  final PreparedUpload? upload;
  final Set<PhotoQualityIssue> issues;

  const PhotoPreparationResult({
    required this.upload,
    required this.issues,
  });

  bool get accepted => upload != null && issues.isEmpty;
}

abstract interface class FoodPhotoPreprocessor {
  Future<PhotoPreparationResult> prepare(Uint8List sourceBytes);
}
```

- [ ] **Step 3: Confirm red**

```powershell
flutter test test/feature/nutrition/photo/food_photo_preprocessor_test.dart
```

Expected: FAIL because the preprocessor does not exist.

- [ ] **Step 4: Implement deterministic preprocessing**

Run decoding and pixel analysis in `Isolate.run` so camera UI stays responsive. Apply EXIF orientation, create a fresh pixel image, resize if necessary, calculate mean luminance and Laplacian variance on a downscaled grayscale copy, and detect a major contiguous clipped-light/clipped-dark region before encoding JPEG at a fixed quality. The returned filename is `food-analysis.jpg`, MIME is `image/jpeg`, and bytes must remain under 5 MB.

Keep thresholds as named constants with test fixtures documenting why they pass/fail. The occlusion heuristic checks framing obstruction only; ambiguous or overlapping food content remains the provider's responsibility. A quality issue is local UI guidance, not an API error. Do not identify dishes or calculate nutrition here.

- [ ] **Step 5: Write the camera screen against a gateway**

The gateway keeps the plugin out of widget tests:

```dart
abstract interface class FoodCameraGateway {
  Future<void> initialize();
  Widget buildPreview();
  Future<Uint8List> takePicture();
  Future<void> dispose();
}
```

`CameraPluginFoodGateway` uses the rear camera, medium/high resolution appropriate for OCR, flash-off by default, and official camera lifecycle handling. `FoodCaptureScreen`:

- shows “Đặt toàn bộ đĩa hoặc nhãn trong khung”;
- accepts a `capturePurpose` of primary meal/label or requested side/close-up;
- disables double capture;
- displays local recapture messages;
- returns only `PreparedUpload` through `Navigator.pop`;
- disposes the gateway on exit.

Widget tests use a fake gateway and fake preprocessor to cover initialization failure/permission denial, valid capture, rejected blur, recapture, and close without capture.

- [ ] **Step 6: Update iOS permission copy**

Replace the barcode-only camera text with Vietnamese text that explicitly says the camera is used to photograph food or nutrition labels. Keep the existing Android `CAMERA` and `INTERNET` permissions; do not add storage or location permission.

- [ ] **Step 7: Verify and commit**

```powershell
dart format lib/feature/nutrition/photo test/feature/nutrition/photo
flutter test test/feature/nutrition/photo/food_photo_preprocessor_test.dart test/feature/nutrition/photo/food_capture_screen_test.dart
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist lib/feature/nutrition/photo/food_photo_preprocessor.dart lib/feature/nutrition/photo/food_camera_gateway.dart lib/feature/nutrition/photo/food_capture_screen.dart test/feature/nutrition/photo/food_photo_preprocessor_test.dart test/feature/nutrition/photo/food_capture_screen_test.dart
git commit -m "feat(flutter): capture private food photos"
```

---

### Task 7: Implement the Riverpod photo-analysis state machine

**Files:**

- Create: `flutter/lib/feature/nutrition/photo/food_photo_state.dart`
- Create: `flutter/lib/feature/nutrition/photo/food_photo_notifier.dart`
- Create: `flutter/test/feature/nutrition/photo/food_photo_notifier_test.dart`

- [ ] **Step 1: Write state-transition tests first**

Use hand-written fakes for `FoodAnalysisClient`, `NutritionRepository`, profile lookup, and clock. Cover:

```text
Idle -> Uploading -> NeedsSecondPhoto
Idle -> Uploading -> ReviewingMeal
Idle -> Uploading -> ReviewingLabel
NeedsSecondPhoto -> Uploading -> ReviewingMeal/Label
Reviewing* -> Confirming -> Ready
Ready -> Saving -> Saved
any active state -> Cancelled -> Idle/disposed
timeout -> Error(retryable, retains only latest prepared upload)
error -> manual fallback
```

Required tests:

- no consent means zero client calls and a consent-required state;
- first image returning `NEEDS_SECOND_IMAGE` clears primary bytes;
- retry after timeout reuses only the latest prepared upload;
- success clears pending bytes;
- component add/remove/rename and familiar portion update are immutable;
- label basis/facts/consumed corrections are immutable;
- manual-required components prevent confirmation until completed;
- confirm sends the edited payload, not original observations;
- save calls `logPhotoEstimate` exactly once even on double tap;
- midpoint/range is not written before `save`;
- cancel invokes `client.cancelPending()` and clears bytes;
- expired analysis returns to recapture, not stale confirmation.

- [ ] **Step 2: Run the notifier tests and confirm red**

```powershell
flutter test test/feature/nutrition/photo/food_photo_notifier_test.dart
```

Expected: FAIL because the state and notifier modules do not exist.

- [ ] **Step 3: Define exhaustive immutable states**

Use sealed classes, not flags mixed into `NutritionUiState`:

```dart
sealed class FoodPhotoState {
  const FoodPhotoState();
}

final class FoodPhotoIdle extends FoodPhotoState {
  const FoodPhotoIdle();
}

final class FoodPhotoCapturing extends FoodPhotoState {
  final bool isSecondary;
  const FoodPhotoCapturing({required this.isSecondary});
}

final class FoodPhotoUploading extends FoodPhotoState {
  final bool isSecondary;
  const FoodPhotoUploading({required this.isSecondary});
}

final class FoodPhotoNeedsSecondPhoto extends FoodPhotoState {
  final FoodAnalysisReview review;
  const FoodPhotoNeedsSecondPhoto(this.review);
}

final class FoodPhotoReviewingMeal extends FoodPhotoState {
  final FoodAnalysisReview review;
  final MealConfirmation draft;
  const FoodPhotoReviewingMeal(this.review, this.draft);
}

final class FoodPhotoReviewingLabel extends FoodPhotoState {
  final FoodAnalysisReview review;
  final LabelConfirmation draft;
  const FoodPhotoReviewingLabel(this.review, this.draft);
}

final class FoodPhotoConfirming extends FoodPhotoState {
  const FoodPhotoConfirming();
}

final class FoodPhotoReady extends FoodPhotoState {
  final FoodAnalysisReady result;
  const FoodPhotoReady(this.result);
}

final class FoodPhotoSaving extends FoodPhotoState {
  final FoodAnalysisReady result;
  const FoodPhotoSaving(this.result);
}

final class FoodPhotoSaved extends FoodPhotoState {
  const FoodPhotoSaved();
}

final class FoodPhotoError extends FoodPhotoState {
  final String code;
  final String message;
  final bool canRetry;
  final bool requiresRecapture;
  const FoodPhotoError({
    required this.code,
    required this.message,
    required this.canRetry,
    required this.requiresRecapture,
  });
}
```

Add a distinct consent-required state or stable error code. Do not store image bytes in public state.

- [ ] **Step 4: Implement a focused notifier**

```dart
final foodPhotoNotifierProvider =
    NotifierProvider.autoDispose<FoodPhotoNotifier, FoodPhotoState>(
  FoodPhotoNotifier.new,
);
```

The notifier owns one private `PreparedUpload? _pendingUpload`, cleared in `ref.onDispose`. Its dependencies come from providers, except clock/epoch-day providers that tests override. It must:

- check `PersonalizationDao.profileNow().cloudAiConsent` before upload;
- expose `beginPrimaryCapture` and `beginSecondaryCapture` so camera navigation has an explicit `Capturing` state;
- submit primary or secondary images;
- translate server status into exhaustive states;
- create editable meal/label drafts from observations;
- validate required manual corrections before confirming;
- expose `retry`, `cancel`, and `useManualEntry`;
- infer meal time from injected local clock;
- call `logPhotoEstimate` only from `save`;
- guard save with state plus a private completed analysis ID set.

Do not add these responsibilities to the already-large `NutritionNotifier`.

- [ ] **Step 5: Run notifier tests**

```powershell
dart format lib/feature/nutrition/photo/food_photo_state.dart lib/feature/nutrition/photo/food_photo_notifier.dart test/feature/nutrition/photo/food_photo_notifier_test.dart
flutter test test/feature/nutrition/photo/food_photo_notifier_test.dart
```

Expected: PASS with no camera, network, or real database.

- [ ] **Step 6: Commit**

```powershell
git add lib/feature/nutrition/photo/food_photo_state.dart lib/feature/nutrition/photo/food_photo_notifier.dart test/feature/nutrition/photo/food_photo_notifier_test.dart
git commit -m "feat(flutter): coordinate food photo workflow"
```

---

### Task 8: Build confirmation/result UI and replace the barcode entry

**Files:**

- Create: `flutter/lib/feature/nutrition/photo/food_photo_flow_screen.dart`
- Create: `flutter/lib/feature/nutrition/photo/meal_confirmation_view.dart`
- Create: `flutter/lib/feature/nutrition/photo/label_confirmation_view.dart`
- Create: `flutter/lib/feature/nutrition/photo/nutrition_estimate_view.dart`
- Modify: `flutter/lib/feature/nutrition/nutrition_screen.dart`
- Create: `flutter/test/feature/nutrition/photo/meal_confirmation_view_test.dart`
- Create: `flutter/test/feature/nutrition/photo/label_confirmation_view_test.dart`
- Create: `flutter/test/feature/nutrition/photo/nutrition_estimate_view_test.dart`
- Create: `flutter/test/feature/nutrition/nutrition_screen_test.dart`
- Create: `flutter/test/integration/food_photo_flow_test.dart`

- [ ] **Step 1: Write failing widget tests for familiar portions**

Meal review must let the user:

- rename, add, and remove a component;
- choose half/one/one-and-a-half bowls for rice;
- choose piece count plus small/medium/large for meat/fish;
- choose little/medium/much for vegetables, soup, and sauce;
- switch to optional grams;
- see which low-confidence component is mandatory.

Label review must let the user:

- correct calories/protein/carbs/fat;
- select per 100 g or per serving;
- enter serving size/count or net weight when required;
- enter the consumed grams or servings;
- keep confirm disabled while the basis or consumed amount is ambiguous.

Use stable widget keys such as:

```dart
const Key('food-photo-primary-action');
Key('meal-component-$componentId');
Key('portion-household-$componentId');
Key('portion-grams-$componentId');
const Key('label-basis-per-100g');
const Key('food-analysis-confirm');
const Key('food-analysis-save');
```

- [ ] **Step 2: Write failing result-card tests**

`NutritionEstimateView` must render:

- calorie min–mid–max;
- protein/carbohydrate/fat ranges;
- high/medium/low confidence in Vietnamese;
- every bounded uncertainty reason in friendly text;
- calculation summary;
- “Ước tính, không phải phép đo y khoa”;
- Save and Edit actions;
- an experimental badge while `foodPhotoAnalysisStable == false`.

- [ ] **Step 3: Run the widget tests and confirm red**

```powershell
flutter test test/feature/nutrition/photo/meal_confirmation_view_test.dart test/feature/nutrition/photo/label_confirmation_view_test.dart test/feature/nutrition/photo/nutrition_estimate_view_test.dart
```

Expected: FAIL because the three view modules do not exist.

- [ ] **Step 4: Implement the flow screen**

`FoodPhotoFlowScreen` watches only `foodPhotoNotifierProvider` and renders one state at a time. It opens `FoodCaptureScreen` for primary or requested secondary capture. Secondary guidance is:

- meal: side angle showing height/separation;
- label: close, straight, well-lit relevant text.

Map errors as follows:

```text
IMAGE_TOO_BLURRY / local quality -> recapture
IMAGE_TOO_LARGE / UNSUPPORTED_IMAGE_TYPE -> recapture
ANALYSIS_EXPIRED -> start again
ANALYSIS_UNAVAILABLE -> retry + manual entry
INVALID_PROVIDER_RESPONSE -> retry + manual entry
DATABASE_NO_MATCH -> choose known food or manual entry
INVALID_CONFIRMATION -> stay on review with field errors
```

Manual fallback pops a typed result to `NutritionScreen`; the parent then calls its existing `startManualEntry`. Saved/cancelled flows return without writing again.

- [ ] **Step 5: Replace the nutrition entry row**

In `nutrition_screen.dart`:

- remove the `barcode_scanner_view.dart` import;
- replace `_showBarcodeScanner` with navigation to `FoodPhotoFlowScreen`;
- rename `onScanBarcode` to `onCaptureFood`;
- label the orange action `Chụp món ăn`;
- keep `Nhập tay` visible and equally easy to reach while the feature is experimental;
- remove the `BarcodeScannerView` overlay;
- do not delete `barcode_scanner_view.dart` or old notifier/client methods yet.

If cloud AI consent is off, the photo flow shows a concise explanation and a route/instruction to enable consent in Profile; manual entry remains active.

- [ ] **Step 6: Add fake end-to-end Flutter integration**

`food_photo_flow_test.dart` uses provider overrides and no real camera/network. Cover:

1. clear meal -> confirmation -> result -> save -> one repository call;
2. ambiguous meal -> second-photo request -> correction -> save;
3. clear label -> correct consumed amount -> deterministic result -> save;
4. ambiguous label basis -> cannot confirm until corrected;
5. timeout -> retry;
6. no consent/offline -> manual fallback;
7. cancellation -> zero repository writes.

- [ ] **Step 7: Run focused UI tests**

```powershell
dart format lib/feature/nutrition/photo lib/feature/nutrition/nutrition_screen.dart test/feature/nutrition/photo test/feature/nutrition/nutrition_screen_test.dart test/integration/food_photo_flow_test.dart
flutter test test/feature/nutrition/photo
flutter test test/feature/nutrition/nutrition_screen_test.dart
flutter test test/integration/food_photo_flow_test.dart
```

Expected: PASS; `rg -n "Quét mã vạch|BarcodeScannerView" lib/feature/nutrition/nutrition_screen.dart` returns no matches.

- [ ] **Step 8: Commit**

```powershell
git add lib/feature/nutrition/photo/food_photo_flow_screen.dart lib/feature/nutrition/photo/meal_confirmation_view.dart lib/feature/nutrition/photo/label_confirmation_view.dart lib/feature/nutrition/photo/nutrition_estimate_view.dart lib/feature/nutrition/nutrition_screen.dart test/feature/nutrition/photo/meal_confirmation_view_test.dart test/feature/nutrition/photo/label_confirmation_view_test.dart test/feature/nutrition/photo/nutrition_estimate_view_test.dart test/feature/nutrition/nutrition_screen_test.dart test/integration/food_photo_flow_test.dart
git commit -m "feat(flutter): replace barcode entry with food photos"
```

---

### Task 9: Add the private accuracy gate, documentation, and full verification

**Files:**

- Modify: `.gitignore`
- Create: `server/evaluation/manifest.example.json`
- Create: `server/evaluation/run_evaluation.js`
- Create: `server/evaluation/README.md`
- Create: `server/test/evaluation_harness_test.js`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-07-20-photo-food-analysis-design.md` only if implementation discovers an approved contract correction

- [ ] **Step 1: Write a failing evaluation-harness test**

The harness accepts a private directory path through `FOOD_EVAL_DIR`. Each private manifest item includes licensed/provenance metadata, ground-truth major components or label fields, weighed nutrition, and optional secondary-image metadata. It constructs the real observer/service with the private images, supplies ground-truth confirmations through the normal confirmation endpoint contract, and reports aggregate metrics only.

Test with tiny synthetic fixtures that it calculates:

```text
major component identification rate
median absolute calorie percentage error after confirmation
percentage within 35% calorie error
clear-label required-field completeness
second-image rate
error-code counts
p50 and p95 latency
```

It must fail the release gate when there are fewer than 30 meal cases or 20 label cases or provenance/license fields are missing. Zero automatic saves is enforced separately by the Flutter notifier and integration tests because the Node analysis service has no persistence dependency.

- [ ] **Step 2: Run the evaluation-harness test and confirm red**

```powershell
cd server
node --test test/evaluation_harness_test.js
cd ..
```

Expected: FAIL because the evaluation harness does not exist.

- [ ] **Step 3: Add ignored private-data layout**

Append:

```gitignore
server/evaluation/private/
server/evaluation/results/
```

Commit only `manifest.example.json`, the harness, and documentation. Never commit evaluation photographs or a real manifest containing private local paths.

- [ ] **Step 4: Implement and document the gate**

Release targets:

```text
major component identification >= 90%
median absolute calorie error <= 20%
confirmed estimates within 35% error >= 90%
clear-label required-field completeness >= 95%
automatic saves = 0
```

The harness exits nonzero when any accuracy target fails and writes an aggregate JSON report without food names, image paths, or raw observations. The Flutter test suite remains the release gate for `automatic saves = 0`. `README.md` must document:

- backend environment setup and new endpoints;
- consent and provider-retention disclosure requirement;
- manual fallback;
- why displayed values are ranges;
- how to run the private evaluation;
- the feature remains “Thử nghiệm” until a dated report passes all gates;
- legacy barcode endpoints remain temporary compatibility code.

- [ ] **Step 5: Run backend verification**

```powershell
cd server
npm test
node -e "const { app } = require('./server'); if (!app) process.exit(1)"
cd ..
```

Expected: all Node tests pass and importing the server does not bind a port.

- [ ] **Step 6: Run Flutter generation, analysis, tests, and build**

```powershell
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
cd ..
```

Expected: formatting is clean, analyzer has no errors, all Flutter tests pass, and the debug APK builds.

- [ ] **Step 7: Run privacy/static checks**

```powershell
rg -n "writeFile|writeFileSync|createWriteStream|diskStorage|base64|inlineData" server/src/food-analysis server/src/http
rg -n "Quét mã vạch|BarcodeScannerView" flutter/lib/feature/nutrition/nutrition_screen.dart
rg -n "foodPhotoAnalysisStable" flutter/lib/feature/nutrition/photo
git status --short
```

Expected:

- no disk-write API in new server modules;
- `inlineData` may exist only inside the provider adapter request construction and never in logs/session objects;
- no barcode primary UI references;
- the experimental flag/badge is present;
- only intended task files are staged.

- [ ] **Step 8: Run the private accuracy evaluation when the licensed set exists**

```powershell
$env:FOOD_EVAL_DIR = (Resolve-Path "server\evaluation\private").Path
node server\evaluation\run_evaluation.js
```

Expected: at least 30 meal and 20 label cases are evaluated. If any target fails or the private set is unavailable, keep `foodPhotoAnalysisStable = false`, report the missing/failed gate, and do not claim stable accuracy.

- [ ] **Step 9: Optional physical Android verification**

Only when `flutter devices` lists an attached Android device:

```powershell
cd flutter
$devices = flutter devices --machine | ConvertFrom-Json
$deviceId = ($devices | Where-Object { $_.targetPlatform -like 'android*' } | Select-Object -First 1).id
if (-not $deviceId) { throw 'Không có thiết bị Android thật đang kết nối.' }
flutter run -d $deviceId
cd ..
```

Manually verify rear-camera preview, permission denial/retry, clear meal, side-angle second photo, clear label, app background/resume, cancel, and that no location/storage permission is requested. Record device/OS and actual result. If no device is attached, state that physical-camera verification remains outstanding.

- [ ] **Step 10: Commit the release gate and docs**

```powershell
git add .gitignore README.md server/evaluation/manifest.example.json server/evaluation/run_evaluation.js server/evaluation/README.md server/test/evaluation_harness_test.js
git commit -m "test: add food photo accuracy gate"
```

If the approved spec required a factual contract correction, stage it explicitly and explain it in the commit; otherwise leave the spec untouched.

---

## Final Acceptance Checklist

- [ ] `Chụp món ăn` is the primary photo action; barcode UI is absent and manual entry remains available.
- [ ] Meal and label images follow one typed contract with strict discriminators.
- [ ] A second image is requested only by the approved confidence/ambiguity rules.
- [ ] Low-confidence observations after the second image require manual completion.
- [ ] Household portions work without grams; grams remain an advanced override.
- [ ] Only deterministic confirmed calculations reach `READY`.
- [ ] The final UI shows min/mid/max calories and macros, confidence, uncertainty, and explanation.
- [ ] Drift writes occur only after Save; daily totals use midpoint; full audit metadata is attached.
- [ ] Existing nutrition history survives schema v3 migration.
- [ ] Client and backend retain no photo or EXIF; sessions expire after 15 minutes.
- [ ] Error paths offer recapture, retry, or manual entry as appropriate.
- [ ] Legacy endpoints still work for older builds.
- [ ] Backend and Flutter automated suites pass.
- [ ] Physical camera result is reported honestly.
- [ ] Accuracy targets are either passed by the licensed private set or the feature remains explicitly experimental.

## Plan Self-Review

Before execution, the implementing worker must verify:

```powershell
$plan = Get-Content docs/superpowers/plans/2026-07-20-photo-food-analysis.md
$reviewStart = ($plan | Select-String '^## Plan Self-Review$').LineNumber
$plan[0..($reviewStart - 2)] | Select-String 'TODO|TBD|placeholder|same as|similar to|\.\.\.'
rg -n "NEEDS_SECOND_IMAGE|NEEDS_CONFIRMATION|READY|UNRECOGNIZED" docs/superpowers/plans/2026-07-20-photo-food-analysis.md
rg -n "0\\.60|0\\.55|15 minutes|5 MB|CAMERA_ANALYSIS" docs/superpowers/plans/2026-07-20-photo-food-analysis.md
```

Review every match from the first command and remove implementation placeholders. Confirm all paths exist or are intentionally marked Create, all enum names agree with the Canonical Contract, every production task starts with a failing test, every task has a focused verification command, and no task deletes legacy barcode endpoints.
