const {
  FoodAnalysisError,
  labelConfirmationSchema,
  mealConfirmationSchema,
  parseConfirmation,
  providerObservationSchema,
} = require('./contracts');
const {
  confidenceBucket,
  confirmationCorrectionBuckets,
  durationBucket,
  rangeWidthBucket,
} = require('../http/analysis_logger');

const FIRST_IMAGE_CONFIDENCE = 0.60;
const SECOND_IMAGE_CONFIDENCE = 0.55;
const REQUIRED_LABEL_FACTS = ['calories', 'proteinGrams', 'carbsGrams', 'fatGrams'];
const REQUIRED_LABEL_MISSING_FIELDS = new Set([
  'BASIS',
  'CALORIES',
  'PROTEIN_GRAMS',
  'CARBS_GRAMS',
  'FAT_GRAMS',
  'CONSUMED_AMOUNT',
]);

function unavailable() {
  return new FoodAnalysisError(
    'ANALYSIS_UNAVAILABLE',
    'Phiên phân tích không khả dụng.',
    409,
  );
}

function invalidConfirmation(field = 'confirmation', observationId) {
  return new FoodAnalysisError(
    'INVALID_CONFIRMATION',
    'Xác nhận dinh dưỡng không hợp lệ.',
    400,
    observationId ? { observationId, field } : { field },
  );
}

class FoodAnalysisService {
  constructor({ observer, estimator, sessionStore, logger }) {
    this.observer = observer;
    this.estimator = estimator;
    this.sessionStore = sessionStore;
    this.logger = logger;
  }

  listKnownFoods() {
    return this.estimator.database.publicCatalog();
  }

  async start({ bytes, mimeType, requestId }) {
    const startedAt = Date.now();
    try {
      const observation = this.#validated(await this.observer.observePrimary({ bytes, mimeType }));
      const status = this.#initialStatus(observation);
      const session = this.sessionStore.create({
        imageType: observation.imageType,
        status,
        observation,
        usedSecondImage: false,
      });
      const response = this.#reviewResponse(session);
      this.#emit('food_analysis_completed', {
        requestId,
        imageType: response.imageType,
        status: response.status,
        confidenceBucket: confidenceBucket(response.confidence),
        usedSecondImage: false,
        durationBucket: durationBucket(Date.now() - startedAt),
      });
      return response;
    } catch (error) {
      this.#emitFailure(error, requestId, startedAt);
      throw error;
    }
  }

  async addSecondaryImage(analysisId, { bytes, mimeType, requestId }) {
    const startedAt = Date.now();
    try {
      const session = this.sessionStore.get(analysisId);
      if (session.status !== 'NEEDS_SECOND_IMAGE' || session.usedSecondImage) throw unavailable();
      const observation = this.#validated(await this.observer.observeSecondary({
        bytes,
        mimeType,
        previousObservation: session.observation,
      }));
      const status = observation.imageType === 'UNKNOWN'
        ? 'UNRECOGNIZED'
        : 'NEEDS_CONFIRMATION';
      const updated = this.sessionStore.update(analysisId, {
        imageType: observation.imageType,
        status,
        observation,
        usedSecondImage: true,
      });
      const response = this.#reviewResponse(updated);
      this.#emit('food_analysis_completed', {
        requestId,
        imageType: response.imageType,
        status: response.status,
        confidenceBucket: confidenceBucket(response.confidence),
        usedSecondImage: true,
        durationBucket: durationBucket(Date.now() - startedAt),
      });
      return response;
    } catch (error) {
      this.#emitFailure(error, requestId, startedAt);
      throw error;
    }
  }

  async confirm(analysisId, confirmation, { requestId } = {}) {
    const startedAt = Date.now();
    try {
      const session = this.sessionStore.get(analysisId);
      if (session.status !== 'NEEDS_CONFIRMATION') throw unavailable();
      const cleanConfirmation = this.#confirmationFor(session, confirmation);
      this.#requireManualComponents(session, cleanConfirmation);

      const estimatorConfirmation = session.imageType === 'MEAL'
        ? {
          ...cleanConfirmation,
          uncertaintyReasons: session.observation.uncertaintyReasons,
        }
        : cleanConfirmation;
      const result = session.imageType === 'MEAL'
        ? this.estimator.estimateMeal(estimatorConfirmation)
        : this.estimator.estimateLabel(cleanConfirmation);
      const response = {
        analysisId,
        imageType: session.imageType,
        status: 'READY',
        nameVi: cleanConfirmation.nameVi,
        estimate: result.estimate,
        confidenceLevel: result.confidenceLevel,
        uncertaintyReasons: session.imageType === 'MEAL'
          ? session.observation.uncertaintyReasons
          : [],
        calculationSummary: result.calculationSummary || result.calculationSummaryVi,
      };
      this.sessionStore.delete(analysisId);
      this.#emit('food_analysis_confirmation_completed', {
        requestId,
        imageType: response.imageType,
        status: response.status,
        confidenceBucket: response.confidenceLevel,
        usedSecondImage: session.usedSecondImage,
        ...confirmationCorrectionBuckets(
          this.#observationWithMatches(session.observation),
          cleanConfirmation,
        ),
        rangeWidthBucket: rangeWidthBucket(response.estimate),
        durationBucket: durationBucket(Date.now() - startedAt),
      });
      return response;
    } catch (error) {
      this.#emitFailure(error, requestId, startedAt);
      throw error;
    }
  }

  #emitFailure(error, requestId, startedAt) {
    this.#emit('food_analysis_failed', {
      requestId,
      errorCode: typeof error?.code === 'string' ? error.code : 'INTERNAL_ERROR',
      durationBucket: durationBucket(Date.now() - startedAt),
    });
  }

  #emit(name, fields) {
    try {
      this.logger?.event?.(name, fields);
    } catch {
      // Telemetry is best effort and must not affect analysis behavior.
    }
  }

  #validated(value) {
    const parsed = providerObservationSchema.safeParse(value);
    if (!parsed.success) {
      throw new FoodAnalysisError(
        'INVALID_PROVIDER_RESPONSE',
        'Phản hồi phân tích ảnh không hợp lệ.',
        502,
      );
    }
    return this.#sanitizeProviderPortions(parsed.data);
  }

  #sanitizeProviderPortions(observation) {
    if (observation.imageType !== 'MEAL') return observation;
    const database = this.estimator.database;
    if (!database || typeof database.supportsPortion !== 'function') {
      return observation;
    }
    return {
      ...observation,
      components: observation.components.map((component) => {
        const portion = component.suggestedPortion;
        const record = database.match(component.nameVi);
        return portion && database.supportsPortion(record, portion)
          ? component
          : { ...component, suggestedPortion: null };
      }),
    };
  }

  #initialStatus(observation) {
    if (observation.imageType === 'UNKNOWN') return 'UNRECOGNIZED';
    if (observation.imageType === 'MEAL') {
      const uncertainMajor = observation.components.some((component) => component.isMajor
        && (component.confidence < FIRST_IMAGE_CONFIDENCE || component.suggestedPortion === null));
      const separationAmbiguous = observation.uncertaintyReasons.includes('OVERLAP');
      return uncertainMajor || separationAmbiguous
        ? 'NEEDS_SECOND_IMAGE'
        : 'NEEDS_CONFIRMATION';
    }
    return this.#labelNeedsMoreInformation(observation.labelFacts)
      ? 'NEEDS_SECOND_IMAGE'
      : 'NEEDS_CONFIRMATION';
  }

  #labelNeedsMoreInformation(labelFacts) {
    const factsComplete = REQUIRED_LABEL_FACTS.every((field) => labelFacts.facts[field] !== null);
    const consumedAmountKnown = labelFacts.netWeightGrams !== null;
    const requiredMissingFields = new Set(REQUIRED_LABEL_MISSING_FIELDS);
    if (labelFacts.basis === 'PER_SERVING') {
      requiredMissingFields.add('SERVING_SIZE_GRAMS');
    }
    return labelFacts.basis === 'UNKNOWN'
      || !factsComplete
      || !consumedAmountKnown
      || (labelFacts.basis === 'PER_SERVING' && labelFacts.servingSizeGrams === null)
      || labelFacts.missingFields.some((field) => requiredMissingFields.has(field));
  }

  #reviewResponse(session) {
    const observation = session.observation;
    return {
      analysisId: session.id,
      imageType: session.imageType,
      status: session.status,
      components: observation.imageType === 'MEAL'
        ? observation.components.map((component) => ({
          ...component,
          matchedFoodId: this.#matchedFoodId(component.nameVi),
          requiresManualPortion: session.usedSecondImage
            && component.isMajor
            && (component.confidence < SECOND_IMAGE_CONFIDENCE || component.suggestedPortion === null),
        }))
        : null,
      labelFacts: observation.imageType === 'NUTRITION_LABEL'
        ? observation.labelFacts
        : null,
      confidence: observation.confidence,
      uncertaintyReasons: observation.uncertaintyReasons,
      expiresAt: session.expiresAt,
    };
  }

  #confirmationFor(session, confirmation) {
    if (!confirmation || typeof confirmation !== 'object' || Array.isArray(confirmation)) {
      throw invalidConfirmation();
    }
    const { kind, ...cleanConfirmation } = confirmation;
    if (kind !== session.imageType) throw invalidConfirmation('kind');
    return parseConfirmation(
      session.imageType === 'MEAL' ? mealConfirmationSchema : labelConfirmationSchema,
      cleanConfirmation,
    );
  }

  #observationWithMatches(observation) {
    if (!Array.isArray(observation.components)) return observation;
    return {
      ...observation,
      components: observation.components.map((component) => ({
        ...component,
        matchedFoodId: this.#matchedFoodId(component.nameVi),
      })),
    };
  }

  #matchedFoodId(nameVi) {
    return this.estimator.database?.match(nameVi)?.id || null;
  }

  #requireManualComponents(session, confirmation) {
    if (session.imageType !== 'MEAL' || !session.usedSecondImage) return;
    const manualIds = session.observation.components
      .filter((component) => component.isMajor
        && (component.confidence < SECOND_IMAGE_CONFIDENCE || component.suggestedPortion === null))
      .map((component) => component.id);
    if (manualIds.length === 0) return;
    if (!Array.isArray(confirmation.components)) throw invalidConfirmation('components');
    const confirmedById = new Map(confirmation.components
      .map((component) => [component?.observationId, component]));
    // Omitting an observed component is an explicit user deletion. A retained
    // low-confidence component must still have a completed portion.
    const incomplete = manualIds.find((id) => confirmedById.has(id)
      && !confirmedById.get(id)?.portion);
    if (incomplete) throw invalidConfirmation('portion', incomplete);
  }
}

module.exports = {
  FIRST_IMAGE_CONFIDENCE,
  SECOND_IMAGE_CONFIDENCE,
  FoodAnalysisService,
};
