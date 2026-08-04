const {
  FoodAnalysisError,
  providerObservationSchema,
} = require('./contracts');

const OUTPUT_INSTRUCTIONS = `Return a food image observation only as one JSON object.
You must not calculate or return final calories or macros. Printed nutrient facts read from a nutrition label are observations, not calculated totals.
Use exactly one imageType: MEAL, NUTRITION_LABEL, or UNKNOWN.
For MEAL return confidence, bounded uncertaintyReasons, components, and labelFacts null. Each component has id, nameVi, confidence, isMajor, and nullable suggestedPortion.
For NUTRITION_LABEL return confidence, bounded uncertaintyReasons, components null, and labelFacts with nameVi, basis, nullable printed facts, nullable servingSizeGrams, nullable servingsPerContainer, nullable netWeightGrams, confidence, and bounded missingFields.
For UNKNOWN return confidence, uncertaintyReasons, components null, and labelFacts null.
Allowed uncertaintyReasons: HIDDEN_OIL, SAUCE, OVERLAP, WEAK_DATABASE_MATCH.
Allowed missingFields: BASIS, CALORIES, PROTEIN_GRAMS, CARBS_GRAMS, FAT_GRAMS, SERVING_SIZE_GRAMS, SERVINGS_PER_CONTAINER, NET_WEIGHT_GRAMS, CONSUMED_AMOUNT.
Return plain JSON without commentary.`;

function unavailable() {
  return new FoodAnalysisError(
    'ANALYSIS_UNAVAILABLE',
    'Không thể phân tích ảnh lúc này.',
    503,
  );
}

function invalidProviderResponse() {
  return new FoodAnalysisError(
    'INVALID_PROVIDER_RESPONSE',
    'Phản hồi phân tích ảnh không hợp lệ.',
    502,
  );
}

function sanitizeObservation(decoded) {
  if (!decoded || typeof decoded !== 'object') return decoded;

  if ('totalCalories' in decoded || 'totalProtein' in decoded || 'totalCarbs' in decoded || 'totalFat' in decoded) {
    return decoded;
  }

  const validUncertaintyReasons = new Set(['HIDDEN_OIL', 'SAUCE', 'OVERLAP', 'WEAK_DATABASE_MATCH']);
  const validMissingFields = new Set([
    'BASIS', 'CALORIES', 'PROTEIN_GRAMS', 'CARBS_GRAMS', 'FAT_GRAMS',
    'SERVING_SIZE_GRAMS', 'SERVINGS_PER_CONTAINER', 'NET_WEIGHT_GRAMS', 'CONSUMED_AMOUNT',
  ]);

  const allowedBaseKeys = ['imageType', 'confidence', 'uncertaintyReasons', 'components', 'labelFacts'];
  const sanitized = {};
  for (const key of allowedBaseKeys) {
    if (key in decoded) {
      sanitized[key] = decoded[key];
    }
  }

  if (typeof sanitized.confidence !== 'number' || isNaN(sanitized.confidence)) {
    sanitized.confidence = 0.8;
  }

  if (Array.isArray(sanitized.uncertaintyReasons)) {
    sanitized.uncertaintyReasons = sanitized.uncertaintyReasons.filter((r) => validUncertaintyReasons.has(r));
  } else {
    sanitized.uncertaintyReasons = [];
  }

  if (sanitized.imageType === 'MEAL') {
    sanitized.labelFacts = null;
    if (Array.isArray(sanitized.components)) {
      const seenIds = new Set();
      sanitized.components = sanitized.components.map((comp, idx) => {
        if (!comp || typeof comp !== 'object') return comp;
        let compId = typeof comp.id === 'string' && comp.id.trim() ? comp.id.trim() : `comp-${idx + 1}`;
        if (seenIds.has(compId)) {
          compId = `${compId}-${idx + 1}`;
        }
        seenIds.add(compId);

        let portion = comp.suggestedPortion;
        if (portion && typeof portion === 'object') {
          if (!portion.kind) {
            if (typeof portion.grams === 'number') {
              portion.kind = 'GRAMS';
            } else if (portion.unit && ['BOWL', 'PIECE', 'SPOON', 'SERVING'].includes(String(portion.unit).toUpperCase())) {
              portion.kind = 'HOUSEHOLD';
            }
          }
          if (portion.kind === 'HOUSEHOLD') {
            const allowedUnits = ['BOWL', 'PIECE', 'SPOON', 'SERVING'];
            const allowedSizes = ['SMALL', 'MEDIUM', 'LARGE'];
            const u = String(portion.unit || '').toUpperCase();
            const s = String(portion.size || '').toUpperCase();
            portion = {
              kind: 'HOUSEHOLD',
              unit: allowedUnits.includes(u) ? u : 'SERVING',
              quantity: typeof portion.quantity === 'number' && portion.quantity > 0 ? portion.quantity : 1,
              size: allowedSizes.includes(s) ? s : 'MEDIUM',
            };
          } else if (portion.kind === 'GRAMS') {
            portion = {
              kind: 'GRAMS',
              grams: typeof portion.grams === 'number' && portion.grams > 0 ? portion.grams : 100,
            };
          } else {
            portion = null;
          }
        } else {
          portion = null;
        }

        return {
          id: compId,
          nameVi: String(comp.nameVi || 'Thức ăn').trim(),
          confidence: typeof comp.confidence === 'number' ? comp.confidence : 0.8,
          isMajor: Boolean(comp.isMajor),
          suggestedPortion: portion,
        };
      });
    } else {
      sanitized.components = [];
    }
  } else if (sanitized.imageType === 'NUTRITION_LABEL') {
    sanitized.components = null;
    if (sanitized.labelFacts && typeof sanitized.labelFacts === 'object') {
      const lf = sanitized.labelFacts;
      const allowedBasis = ['PER_100G', 'PER_SERVING', 'UNKNOWN'];
      const basis = allowedBasis.includes(lf.basis) ? lf.basis : 'UNKNOWN';

      const facts = lf.facts || {};
      const safeFacts = {
        calories: typeof facts.calories === 'number' ? facts.calories : null,
        proteinGrams: typeof facts.proteinGrams === 'number' ? facts.proteinGrams : null,
        carbsGrams: typeof facts.carbsGrams === 'number' ? facts.carbsGrams : null,
        fatGrams: typeof facts.fatGrams === 'number' ? facts.fatGrams : null,
      };

      let missingFields = Array.isArray(lf.missingFields)
        ? lf.missingFields.filter((m) => validMissingFields.has(m))
        : [];

      const requiredChecks = [
        [basis === 'UNKNOWN', 'BASIS'],
        [safeFacts.calories === null, 'CALORIES'],
        [safeFacts.proteinGrams === null, 'PROTEIN_GRAMS'],
        [safeFacts.carbsGrams === null, 'CARBS_GRAMS'],
        [safeFacts.fatGrams === null, 'FAT_GRAMS'],
        [basis === 'PER_SERVING' && (lf.servingSizeGrams === null || lf.servingSizeGrams === undefined), 'SERVING_SIZE_GRAMS'],
        [(lf.netWeightGrams === null || lf.netWeightGrams === undefined), 'CONSUMED_AMOUNT'],
      ];

      for (const [isMissing, code] of requiredChecks) {
        if (isMissing && !missingFields.includes(code)) {
          missingFields.push(code);
        }
      }

      sanitized.labelFacts = {
        nameVi: String(lf.nameVi || 'Sản phẩm').trim(),
        basis,
        facts: safeFacts,
        servingSizeGrams: typeof lf.servingSizeGrams === 'number' && lf.servingSizeGrams > 0 ? lf.servingSizeGrams : null,
        servingsPerContainer: typeof lf.servingsPerContainer === 'number' && lf.servingsPerContainer > 0 ? lf.servingsPerContainer : null,
        netWeightGrams: typeof lf.netWeightGrams === 'number' && lf.netWeightGrams > 0 ? lf.netWeightGrams : null,
        confidence: typeof lf.confidence === 'number' ? lf.confidence : 0.8,
        missingFields,
      };
    }
  } else {
    sanitized.imageType = 'UNKNOWN';
    sanitized.components = null;
    sanitized.labelFacts = null;
  }

  return sanitized;
}

class GeminiFoodObserver {
  constructor({ apiKey, model, fetchImpl = fetch, timeoutMs = 30_000 }) {
    this.apiKey = apiKey;
    this.model = model;
    this.fetchImpl = fetchImpl;
    this.timeoutMs = timeoutMs;
  }

  async observePrimary({ bytes, mimeType }) {
    return this.#observe({
      bytes,
      mimeType,
      prompt: OUTPUT_INSTRUCTIONS,
    });
  }

  async observeSecondary({ bytes, mimeType, previousObservation }) {
    const parsedPrevious = providerObservationSchema.safeParse(previousObservation);
    if (!parsedPrevious.success) throw invalidProviderResponse();
    return this.#observe({
      bytes,
      mimeType,
      prompt: `${OUTPUT_INSTRUCTIONS}
This is a secondary image of the same food. Reconcile it with this previous validated observation:
${JSON.stringify(parsedPrevious.data)}`,
    });
  }

  async #observe({ bytes, mimeType, prompt }) {
    if (typeof this.apiKey !== 'string' || !this.apiKey.trim()) {
      throw unavailable();
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await this.fetchImpl(
        `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(this.model)}:generateContent?key=${encodeURIComponent(this.apiKey)}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          signal: controller.signal,
          body: JSON.stringify({
            contents: [{
              role: 'user',
              parts: [
                { text: prompt },
                {
                  inlineData: {
                    mimeType,
                    data: Buffer.from(bytes).toString('base64'),
                  },
                },
              ],
            }],
            generationConfig: {
              responseMimeType: 'application/json',
              temperature: 0,
            },
          }),
        },
      );
      if (!response?.ok) throw unavailable();

      let payload;
      try {
        payload = await response.json();
      } catch {
        throw invalidProviderResponse();
      }
      const text = payload?.candidates?.[0]?.content?.parts
        ?.map((part) => part.text)
        .filter((part) => typeof part === 'string')
        .join('');
      if (!text) throw invalidProviderResponse();

      let decoded;
      try {
        decoded = JSON.parse(this.#unwrapJson(text));
      } catch {
        console.error(JSON.stringify({
          event: 'food_observer_provider_response_rejected',
          code: 'INVALID_JSON',
        }));
        throw invalidProviderResponse();
      }
      const sanitized = sanitizeObservation(decoded);
      const parsed = providerObservationSchema.safeParse(sanitized);
      if (!parsed.success) {
        console.error(JSON.stringify({
          event: 'food_observer_provider_response_rejected',
          code: 'SCHEMA_MISMATCH',
          issueCount: Math.min(parsed.error.issues.length, 99),
        }));
        throw invalidProviderResponse();
      }
      return parsed.data;
    } catch (error) {
      if (error instanceof FoodAnalysisError) throw error;
      throw unavailable();
    } finally {
      clearTimeout(timeout);
    }
  }

  #unwrapJson(text) {
    const trimmed = text.trim();
    const fenced = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
    return fenced ? fenced[1] : trimmed;
  }
}

module.exports = { GeminiFoodObserver };
