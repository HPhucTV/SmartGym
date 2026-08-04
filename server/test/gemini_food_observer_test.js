const test = require('node:test');
const assert = require('node:assert/strict');
const { GeminiFoodObserver } = require('../src/food-analysis/gemini_food_observer');

function mealObservation() {
  return {
    imageType: 'MEAL',
    confidence: 0.8,
    uncertaintyReasons: ['HIDDEN_OIL'],
    components: [{
      id: 'component-1',
      nameVi: 'Cơm trắng',
      confidence: 0.8,
      isMajor: true,
      suggestedPortion: {
        kind: 'HOUSEHOLD',
        unit: 'BOWL',
        quantity: 1,
        size: 'MEDIUM',
      },
    }],
    labelFacts: null,
  };
}

function geminiResponse(text, status = 200) {
  return new Response(JSON.stringify({
    candidates: [{
      content: {
        role: 'model',
        parts: [{ text }],
      },
      finishReason: 'STOP',
      index: 0,
    }],
    usageMetadata: {
      promptTokenCount: 10,
      candidatesTokenCount: 10,
      totalTokenCount: 20,
    },
  }), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

test('observes primary images from plain JSON with a no-totals structured prompt', async () => {
  let requestedUrl;
  let requestedOptions;
  const observer = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    fetchImpl: async (url, options) => {
      requestedUrl = url;
      requestedOptions = options;
      return geminiResponse(JSON.stringify(mealObservation()));
    },
  });

  const result = await observer.observePrimary({
    bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
    mimeType: 'image/jpeg',
  });

  assert.deepEqual(result, mealObservation());
  assert.match(requestedUrl, /gemini-test:generateContent\?key=test-key$/);
  const request = JSON.parse(requestedOptions.body);
  const prompt = request.contents[0].parts[0].text;
  assert.match(prompt, /observation only/i);
  assert.match(prompt, /must not calculate or return final calories or macros/i);
  assert.deepEqual(request.contents[0].parts[1], {
    inlineData: {
      mimeType: 'image/jpeg',
      data: '/9j/2Q==',
    },
  });
  assert.equal(result.prompt, undefined);
  assert.equal(result.rawProviderResponse, undefined);
});

test('observes secondary images from fenced JSON using the previous structured observation', async () => {
  let request;
  const observation = mealObservation();
  observation.confidence = 0.9;
  observation.components[0].confidence = 0.9;
  const observer = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    fetchImpl: async (_url, options) => {
      request = JSON.parse(options.body);
      return geminiResponse(`\n\`\`\`json\n${JSON.stringify(observation)}\n\`\`\`\n`);
    },
  });

  const result = await observer.observeSecondary({
    bytes: Buffer.from('png'),
    mimeType: 'image/png',
    previousObservation: mealObservation(),
  });

  assert.equal(result.confidence, 0.9);
  assert.match(request.contents[0].parts[0].text, /previous validated observation/i);
  assert.match(request.contents[0].parts[0].text, /"imageType":"MEAL"/);
});

test('rejects malformed JSON and strict-schema violations without exposing raw output', async () => {
  const originalConsoleError = console.error;
  const logs = [];
  console.error = (...parts) => logs.push(parts.join(' '));
  try {
  const malformed = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    fetchImpl: async () => geminiResponse('{not json'),
  });
  await assert.rejects(
    malformed.observePrimary({ bytes: Buffer.from('x'), mimeType: 'image/jpeg' }),
    (error) => error.code === 'INVALID_PROVIDER_RESPONSE'
      && !JSON.stringify(error).includes('{not json'),
  );

  const withTotals = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    fetchImpl: async () => geminiResponse(JSON.stringify({
      ...mealObservation(),
      totalCalories: 195,
    })),
  });
  await assert.rejects(
    withTotals.observePrimary({ bytes: Buffer.from('x'), mimeType: 'image/jpeg' }),
    (error) => error.code === 'INVALID_PROVIDER_RESPONSE'
      && error.details === undefined,
  );
  } finally {
    console.error = originalConsoleError;
  }
  assert.equal(logs.some((line) => line.includes('{not json')), false);
  assert.equal(logs.some((line) => line.includes('totalCalories')), false);
  assert.equal(logs.some((line) => line.includes('INVALID_JSON')), true);
  assert.equal(logs.some((line) => line.includes('SCHEMA_MISMATCH')), true);
});

test('maps HTTP and network failures to ANALYSIS_UNAVAILABLE', async () => {
  const unavailable = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    fetchImpl: async () => new Response('provider down', { status: 503 }),
  });
  await assert.rejects(
    unavailable.observePrimary({ bytes: Buffer.from('x'), mimeType: 'image/jpeg' }),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );

  const networkFailure = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    fetchImpl: async () => {
      throw new TypeError('network failed');
    },
  });
  await assert.rejects(
    networkFailure.observePrimary({ bytes: Buffer.from('x'), mimeType: 'image/jpeg' }),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE'
      && !JSON.stringify(error).includes('network failed'),
  );
});

test('fails closed without a Gemini key and never calls fetch', async () => {
  let called = false;
  const observer = new GeminiFoodObserver({
    apiKey: '',
    model: 'gemini-test',
    fetchImpl: async () => {
      called = true;
      throw new Error('must not be called');
    },
  });

  await assert.rejects(
    observer.observePrimary({
      bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]),
      mimeType: 'image/jpeg',
    }),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
  assert.equal(called, false);
});

test('aborts provider requests at the configured timeout', async () => {
  let observedAbort = false;
  const observer = new GeminiFoodObserver({
    apiKey: 'test-key',
    model: 'gemini-test',
    timeoutMs: 5,
    fetchImpl: async (_url, { signal }) => new Promise((_resolve, reject) => {
      signal.addEventListener('abort', () => {
        observedAbort = true;
        reject(new DOMException('aborted', 'AbortError'));
      }, { once: true });
    }),
  });

  await assert.rejects(
    observer.observePrimary({ bytes: Buffer.from('x'), mimeType: 'image/jpeg' }),
    (error) => error.code === 'ANALYSIS_UNAVAILABLE',
  );
  assert.equal(observedAbort, true);
});
