const test = require('node:test');
const assert = require('node:assert/strict');
const { AnalysisSessionStore } = require('../src/food-analysis/analysis_session_store');
const { FoodAnalysisService } = require('../src/food-analysis/food_analysis_service');
const { FoodDatabase } = require('../src/food-analysis/food_database');
const { NutritionEstimator } = require('../src/food-analysis/nutrition_estimator');
const {
  mealConfirmationSchema,
  parseConfirmation,
  providerObservationSchema,
} = require('../src/food-analysis/contracts');

function validJpeg() {
  return {
    bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
    mimeType: 'image/jpeg',
  };
}

function mealObservation(confidence = 0.8, overrides = {}) {
  return {
    imageType: 'MEAL',
    confidence,
    uncertaintyReasons: [],
    components: [{
      id: 'component-1',
      nameVi: 'Cơm trắng',
      confidence,
      isMajor: true,
      suggestedPortion: {
        kind: 'HOUSEHOLD',
        unit: 'BOWL',
        quantity: 1,
        size: 'MEDIUM',
      },
    }],
    labelFacts: null,
    ...overrides,
  };
}

function labelObservation(overrides = {}) {
  return {
    imageType: 'NUTRITION_LABEL',
    confidence: 0.94,
    uncertaintyReasons: [],
    components: null,
    labelFacts: {
      nameVi: 'Snack',
      basis: 'PER_100G',
      facts: {
        calories: 498,
        proteinGrams: 4.4,
        carbsGrams: 49.8,
        fatGrams: 31.1,
      },
      servingSizeGrams: null,
      servingsPerContainer: null,
      netWeightGrams: 57,
      confidence: 0.94,
      missingFields: [],
    },
    ...overrides,
  };
}

function sequenceObserver(observations) {
  let index = 0;
  return {
    observePrimary: async () => observations[index++],
    observeSecondary: async () => observations[index++],
  };
}

function validMealConfirmation(overrides = {}) {
  return {
    kind: 'MEAL',
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
    ...overrides,
  };
}

function makeService({ observer, now = () => 0, estimator } = {}) {
  let id = 0;
  const sessionStore = new AnalysisSessionStore({
    now,
    idFactory: () => `analysis-${++id}`,
  });
  const fakeEstimator = estimator || {
    database: {
      match(name) {
        return name === 'Cơm trắng' ? { id: 'white-rice' } : null;
      },
    },
    estimateMeal() {
      return {
        estimate: {
          calories: { min: 169, mid: 195, max: 221 },
          proteinGrams: { min: 3.5, mid: 4.1, max: 4.6 },
          carbsGrams: { min: 36.4, mid: 42, max: 47.6 },
          fatGrams: { min: 0.4, mid: 0.5, max: 0.5 },
        },
        confidenceLevel: 'HIGH',
        calculationSummaryVi: 'Ước tính từ 1 bát cơm vừa.',
      };
    },
    estimateLabel() {
      return {
        estimate: {
          calories: { min: 284, mid: 284, max: 284 },
          proteinGrams: { min: 2.5, mid: 2.5, max: 2.5 },
          carbsGrams: { min: 28.4, mid: 28.4, max: 28.4 },
          fatGrams: { min: 17.7, mid: 17.7, max: 17.7 },
        },
        confidenceLevel: 'HIGH',
        calculationSummaryVi: 'Tính theo nhãn đã xác nhận.',
      };
    },
  };
  const service = new FoodAnalysisService({
    observer,
    estimator: fakeEstimator,
    sessionStore,
    logger: { event() {} },
  });
  service.sessionStore = sessionStore;
  return service;
}

test('provider schema accepts the full strict observation and rejects provider totals', () => {
  assert.equal(providerObservationSchema.safeParse(mealObservation()).success, true);
  assert.equal(providerObservationSchema.safeParse({
    ...mealObservation(),
    totalCalories: 195,
  }).success, false);
});

test('meal confirmation schema accepts the canonical client body without uncertainty reasons', () => {
  const { kind, ...canonicalBody } = validMealConfirmation();
  assert.equal(mealConfirmationSchema.safeParse(canonicalBody).success, true);
});

test('provider schema requires null required label facts to be named as missing', () => {
  const observation = labelObservation();
  observation.labelFacts.facts.calories = null;

  assert.equal(providerObservationSchema.safeParse(observation).success, false);
  observation.labelFacts.missingFields = ['CALORIES'];
  assert.equal(providerObservationSchema.safeParse(observation).success, true);
});

test('first image below 0.60 requests a second image without retaining bytes', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.58, { uncertaintyReasons: ['OVERLAP'] })]),
  });

  const response = await service.start(validJpeg());

  assert.equal(response.status, 'NEEDS_SECOND_IMAGE');
  assert.equal(response.analysisId, 'analysis-1');
  const stored = service.sessionStore.get('analysis-1');
  assert.equal(stored.imageBytes, undefined);
  assert.equal(JSON.stringify(stored).includes('base64'), false);
});

test('first image at 0.60 goes directly to confirmation and matches curated food IDs', async () => {
  const service = makeService({ observer: sequenceObserver([mealObservation(0.60)]) });

  const response = await service.start(validJpeg());

  assert.equal(response.status, 'NEEDS_CONFIRMATION');
  assert.equal(response.components[0].matchedFoodId, 'white-rice');
  assert.equal(response.components[0].requiresManualPortion, false);
});

test('only major meal components control the first-image threshold', async () => {
  const observation = mealObservation(0.9);
  observation.components.push({
    id: 'garnish',
    nameVi: 'Rau thơm',
    confidence: 0.2,
    isMajor: false,
    suggestedPortion: null,
  });
  const service = makeService({ observer: sequenceObserver([observation]) });

  const response = await service.start(validJpeg());

  assert.equal(response.status, 'NEEDS_CONFIRMATION');
});

test('an overlapping first view requests the one allowed secondary image', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.9, { uncertaintyReasons: ['OVERLAP'] })]),
  });

  assert.equal((await service.start(validJpeg())).status, 'NEEDS_SECOND_IMAGE');
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

test('a retained manual low-confidence component still requires a portion', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.40), mealObservation(0.54)]),
  });
  const started = await service.start(validJpeg());
  await service.addSecondaryImage(started.analysisId, validJpeg());

  await assert.rejects(
    service.confirm(started.analysisId, validMealConfirmation({ components: [{
      observationId: 'component-1',
      foodId: 'white-rice',
      nameVi: 'Cơm trắng',
      portion: null,
    }] })),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});

test('a false-positive manual component can be deleted after the second image', async () => {
  const first = mealObservation(0.4);
  const second = mealObservation(0.8);
  second.components.push({
    id: 'false-positive',
    nameVi: 'Vật thể nhận nhầm',
    confidence: 0.4,
    isMajor: true,
    suggestedPortion: null,
  });
  const events = [];
  const service = makeService({ observer: sequenceObserver([first, second]) });
  service.logger = { event: (name, fields) => events.push({ name, fields }) };
  const started = await service.start(validJpeg());
  const reviewed = await service.addSecondaryImage(started.analysisId, validJpeg());
  assert.equal(reviewed.components[1].requiresManualPortion, true);

  const response = await service.confirm(started.analysisId, validMealConfirmation());

  assert.equal(response.status, 'READY');
  const completed = events.find(
    (event) => event.name === 'food_analysis_confirmation_completed',
  );
  assert.equal(completed.fields.componentCorrectionBucket, 'ONE');
  assert.equal(completed.fields.portionCorrectionBucket, 'NONE');
});

test('deleting every meal component remains an invalid confirmation', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.4), mealObservation(0.4)]),
  });
  const started = await service.start(validJpeg());
  await service.addSecondaryImage(started.analysisId, validJpeg());

  await assert.rejects(
    service.confirm(started.analysisId, {
      kind: 'MEAL',
      nameVi: 'Bữa ăn',
      components: [],
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
  assert.equal(service.sessionStore.get(started.analysisId).status, 'NEEDS_CONFIRMATION');
});

test('a clear label goes to confirmation while ambiguous required fields request a second image', async () => {
  const clearService = makeService({ observer: sequenceObserver([labelObservation()]) });
  assert.equal((await clearService.start(validJpeg())).status, 'NEEDS_CONFIRMATION');

  const ambiguous = labelObservation();
  ambiguous.labelFacts.basis = 'UNKNOWN';
  ambiguous.labelFacts.missingFields = ['BASIS'];
  const ambiguousService = makeService({ observer: sequenceObserver([ambiguous]) });
  assert.equal((await ambiguousService.start(validJpeg())).status, 'NEEDS_SECOND_IMAGE');
});

test('a label serving size without a consumed amount requests a second image', async () => {
  const observation = labelObservation();
  observation.labelFacts.basis = 'PER_SERVING';
  observation.labelFacts.servingSizeGrams = 40;
  observation.labelFacts.netWeightGrams = null;
  observation.labelFacts.missingFields = ['CONSUMED_AMOUNT'];
  const service = makeService({ observer: sequenceObserver([observation]) });

  assert.equal((await service.start(validJpeg())).status, 'NEEDS_SECOND_IMAGE');
});

test('provider schema rejects PER_SERVING observations without a serving size', () => {
  const observation = labelObservation();
  observation.labelFacts.basis = 'PER_SERVING';
  observation.labelFacts.servingSizeGrams = null;
  observation.labelFacts.missingFields = [];

  assert.equal(providerObservationSchema.safeParse(observation).success, false);
});

test('PER_100G ignores optional serving-size missing fields when required facts are complete', async () => {
  const observation = labelObservation();
  observation.labelFacts.servingSizeGrams = null;
  observation.labelFacts.missingFields = ['SERVING_SIZE_GRAMS'];
  const service = makeService({ observer: sequenceObserver([observation]) });

  assert.equal((await service.start(validJpeg())).status, 'NEEDS_CONFIRMATION');
});

test('after a second label image missing fields are exposed for manual correction without looping', async () => {
  const first = labelObservation();
  first.labelFacts.basis = 'UNKNOWN';
  first.labelFacts.facts.calories = null;
  first.labelFacts.missingFields = ['BASIS', 'CALORIES'];
  const second = structuredClone(first);
  const service = makeService({ observer: sequenceObserver([first, second]) });

  const started = await service.start(validJpeg());
  const response = await service.addSecondaryImage(started.analysisId, validJpeg());

  assert.equal(response.status, 'NEEDS_CONFIRMATION');
  assert.deepEqual(response.labelFacts.missingFields, ['BASIS', 'CALORIES']);
});

test('unknown images are unrecognized', async () => {
  const service = makeService({
    observer: sequenceObserver([{
      imageType: 'UNKNOWN',
      confidence: 0,
      uncertaintyReasons: [],
      components: null,
      labelFacts: null,
    }]),
  });

  assert.equal((await service.start(validJpeg())).status, 'UNRECOGNIZED');
});

test('a secondary image can be added only once and only while requested', async () => {
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.4), mealObservation(0.8)]),
  });
  const started = await service.start(validJpeg());
  await service.addSecondaryImage(started.analysisId, validJpeg());

  await assert.rejects(
    service.addSecondaryImage(started.analysisId, validJpeg()),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );

  const direct = makeService({ observer: sequenceObserver([mealObservation(0.8)]) });
  const directStarted = await direct.start(validJpeg());
  await assert.rejects(
    direct.addSecondaryImage(directStarted.analysisId, validJpeg()),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
});

test('confirmation is accepted only in confirmation state', async () => {
  const service = makeService({ observer: sequenceObserver([mealObservation(0.4)]) });
  const started = await service.start(validJpeg());

  await assert.rejects(
    service.confirm(started.analysisId, validMealConfirmation()),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
});

test('expired and unknown analysis IDs use stable errors', async () => {
  let now = 0;
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.8)]),
    now: () => now,
  });
  const started = await service.start(validJpeg());
  now = 15 * 60 * 1000 + 1;

  await assert.rejects(
    service.confirm(started.analysisId, validMealConfirmation()),
    (error) => error.code === 'ANALYSIS_EXPIRED',
  );
  await assert.rejects(
    service.confirm('unknown-analysis-id', validMealConfirmation()),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
});

test('successful confirmation returns READY estimator output and deletes the session', async () => {
  const service = makeService({ observer: sequenceObserver([mealObservation(0.8)]) });
  const started = await service.start(validJpeg());

  const response = await service.confirm(started.analysisId, validMealConfirmation());

  assert.equal(response.status, 'READY');
  assert.equal(response.analysisId, started.analysisId);
  assert.equal(response.estimate.calories.mid, 195);
  assert.equal(response.calculationSummary, 'Ước tính từ 1 bát cơm vừa.');
  assert.throws(
    () => service.sessionStore.get(started.analysisId),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
});

test('session remains usable after a correctable estimator confirmation error', async () => {
  let attempts = 0;
  const estimator = {
    database: { match: () => ({ id: 'white-rice' }) },
    estimateMeal() {
      attempts += 1;
      if (attempts === 1) {
        const error = new Error('correctable');
        error.code = 'INVALID_CONFIRMATION';
        throw error;
      }
      return {
        estimate: { calories: { min: 1, mid: 1, max: 1 } },
        confidenceLevel: 'HIGH',
        calculationSummaryVi: 'ok',
      };
    },
  };
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.8)]),
    estimator,
  });
  const started = await service.start(validJpeg());

  await assert.rejects(
    service.confirm(started.analysisId, validMealConfirmation()),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
  assert.equal(service.sessionStore.get(started.analysisId).status, 'NEEDS_CONFIRMATION');
  assert.equal((await service.confirm(started.analysisId, validMealConfirmation())).status, 'READY');
});

test('an over-limit deterministic total is correctable and keeps the session editable', async () => {
  const database = new FoodDatabase([{
    id: 'boundary-food',
    nameVi: 'Cơm trắng',
    aliases: [],
    nutrientsPer100g: {
      calories: 1000,
      proteinGrams: 100,
      carbsGrams: 100,
      fatGrams: 100,
    },
    householdPortions: {},
  }]);
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.8, {
      components: [{
        id: 'component-1',
        nameVi: 'Cơm trắng',
        confidence: 0.8,
        isMajor: true,
        suggestedPortion: { kind: 'GRAMS', grams: 500 },
      }],
    })]),
    estimator: new NutritionEstimator({ database }),
  });
  const started = await service.start(validJpeg());

  await assert.rejects(
    service.confirm(started.analysisId, validMealConfirmation({
      components: [{
        observationId: 'component-1',
        foodId: 'boundary-food',
        nameVi: 'Cơm trắng',
        portion: { kind: 'GRAMS', grams: 500.0001 },
      }],
    })),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );

  assert.equal(service.sessionStore.get(started.analysisId).status, 'NEEDS_CONFIRMATION');
});

test('an over-limit label total is correctable and keeps the session editable', async () => {
  const service = makeService({
    observer: sequenceObserver([labelObservation()]),
    estimator: new NutritionEstimator({ database: new FoodDatabase([]) }),
  });
  const started = await service.start(validJpeg());

  await assert.rejects(
    service.confirm(started.analysisId, {
      kind: 'NUTRITION_LABEL',
      nameVi: 'Nhãn kiểm tra biên',
      basis: 'PER_100G',
      facts: {
        calories: 1000,
        proteinGrams: 100,
        carbsGrams: 100,
        fatGrams: 22.2222222222,
      },
      consumed: { kind: 'GRAMS', amount: 500.0001 },
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );

  assert.equal(service.sessionStore.get(started.analysisId).status, 'NEEDS_CONFIRMATION');
});

test('emits bounded workflow telemetry including correction buckets and failures', async () => {
  const events = [];
  const service = makeService({ observer: sequenceObserver([mealObservation(0.8)]) });
  service.logger = { event: (name, fields) => events.push({ name, fields }) };

  const started = await service.start({ ...validJpeg(), requestId: 'request-1' });
  await service.confirm(started.analysisId, {
    ...validMealConfirmation(),
    nameVi: 'Tên đã sửa',
    components: [{
      ...validMealConfirmation().components[0],
      nameVi: 'Tên thành phần đã sửa',
      portion: { kind: 'GRAMS', grams: 150 },
    }],
  }, { requestId: 'request-2' });

  await assert.rejects(
    service.confirm(started.analysisId, validMealConfirmation(), { requestId: 'request-3' }),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
  assert.deepEqual(events.map((event) => event.name), [
    'food_analysis_completed',
    'food_analysis_confirmation_completed',
    'food_analysis_failed',
  ]);
  assert.equal(events[0].fields.requestId, 'request-1');
  assert.equal(events[1].fields.componentCorrectionBucket, 'ONE');
  assert.equal(events[1].fields.portionCorrectionBucket, 'ONE');
  assert.equal(events[2].fields.errorCode, 'ANALYSIS_UNAVAILABLE');
  assert.equal(JSON.stringify(events).includes('Tên đã sửa'), false);
  assert.equal(JSON.stringify(events).includes('Tên thành phần đã sửa'), false);
});

test('accepts the canonical meal confirmation and derives uncertainty from the stored observation', async () => {
  let estimated;
  const estimator = {
    database: { match: () => ({ id: 'white-rice' }) },
    estimateMeal(confirmation) {
      estimated = confirmation;
      return {
        estimate: { calories: { min: 100, mid: 120, max: 140 } },
        confidenceLevel: 'MEDIUM',
        calculationSummaryVi: 'ok',
      };
    },
  };
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.8, {
      uncertaintyReasons: ['HIDDEN_OIL'],
    })]),
    estimator,
  });
  const started = await service.start(validJpeg());

  const response = await service.confirm(started.analysisId, validMealConfirmation());

  assert.equal(response.status, 'READY');
  assert.deepEqual(estimated.uncertaintyReasons, ['HIDDEN_OIL']);
  assert.deepEqual(response.uncertaintyReasons, ['HIDDEN_OIL']);
});

test('requires the confirmation kind and rejects client-controlled uncertainty reasons', async () => {
  const missingKindService = makeService({
    observer: sequenceObserver([mealObservation(0.8)]),
  });
  const missingKindStarted = await missingKindService.start(validJpeg());
  const { kind, ...withoutKind } = validMealConfirmation();
  await assert.rejects(
    missingKindService.confirm(missingKindStarted.analysisId, withoutKind),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );

  const injectedService = makeService({
    observer: sequenceObserver([mealObservation(0.8, {
      uncertaintyReasons: ['HIDDEN_OIL'],
    })]),
  });
  const injectedStarted = await injectedService.start(validJpeg());
  await assert.rejects(
    injectedService.confirm(injectedStarted.analysisId, {
      ...validMealConfirmation(),
      uncertaintyReasons: [],
    }),
    (error) => error.code === 'INVALID_CONFIRMATION',
  );
});

test('maps component array validation to an observation-aware relative field', () => {
  const first = validMealConfirmation().components[0];
  assert.throws(
    () => parseConfirmation(mealConfirmationSchema, {
      nameVi: 'Bữa ăn',
      components: [
        { ...first, observationId: '1' },
        {
          ...first,
          observationId: 'other',
          portion: { ...first.portion, unit: 'INVALID' },
        },
      ],
    }),
    (error) => error.code === 'INVALID_CONFIRMATION'
      && error.details.observationId === 'other'
      && error.details.field === 'portion.unit',
  );
});

test('rejects duplicate provider component identifiers at the schema boundary', () => {
  const observation = mealObservation(0.8);
  observation.components.push({
    ...observation.components[0],
    nameVi: 'Trứng luộc',
  });

  assert.equal(providerObservationSchema.safeParse(observation).success, false);
});

test('keeps canonical nutrition-label confirmation working', async () => {
  const service = makeService({ observer: sequenceObserver([labelObservation()]) });
  const started = await service.start(validJpeg());

  const response = await service.confirm(started.analysisId, {
    kind: 'NUTRITION_LABEL',
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

  assert.equal(response.status, 'READY');
  assert.equal(response.imageType, 'NUTRITION_LABEL');
  assert.deepEqual(response.uncertaintyReasons, []);
});

test('uses parsed confirmation values for semantic correction telemetry', async () => {
  const events = [];
  let estimated;
  const estimator = {
    database: { match: () => ({ id: 'white-rice' }) },
    estimateMeal(confirmation) {
      estimated = confirmation;
      return {
        estimate: { calories: { min: 100, mid: 100, max: 100 } },
        confidenceLevel: 'HIGH',
        calculationSummaryVi: 'ok',
      };
    },
  };
  const service = makeService({
    observer: sequenceObserver([mealObservation(0.8)]),
    estimator,
  });
  service.logger = { event: (name, fields) => events.push({ name, fields }) };
  const started = await service.start(validJpeg());
  const component = validMealConfirmation().components[0];

  await service.confirm(started.analysisId, {
    kind: 'MEAL',
    nameVi: ' Cơm ',
    components: [{
      observationId: component.observationId,
      foodId: component.foodId,
      nameVi: ` ${component.nameVi} `,
      portion: {
        size: 'MEDIUM',
        quantity: 1,
        unit: 'BOWL',
        kind: 'HOUSEHOLD',
      },
    }],
  });

  assert.equal(estimated.nameVi, 'Cơm');
  const completed = events.find((event) => event.name === 'food_analysis_confirmation_completed');
  assert.equal(completed.fields.componentCorrectionBucket, 'NONE');
  assert.equal(completed.fields.portionCorrectionBucket, 'NONE');
});
