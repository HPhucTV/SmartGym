const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { app } = require('../server');

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xd9]);

test('barcode limiter exhaustion cannot intercept photo-analysis errors or rate limits', async () => {
  for (let index = 0; index < 30; index += 1) {
    const response = await request(app).get('/api/barcodes/invalid');
    assert.equal(response.status, 400);
  }
  const barcodeLimited = await request(app).get('/api/barcodes/invalid');
  assert.equal(barcodeLimited.status, 429);
  assert.equal(typeof barcodeLimited.body.error, 'string');

  const telemetry = [];
  const originalWrite = process.stdout.write;
  process.stdout.write = function captureTelemetry(chunk, ...args) {
    const line = String(chunk);
    if (line.startsWith('{"event":"food_analysis_')) {
      telemetry.push(JSON.parse(line));
      return true;
    }
    return originalWrite.call(this, chunk, ...args);
  };

  let photoLimited;
  try {
    for (let index = 0; index < 10; index += 1) {
      const invalidImage = await request(app)
        .post('/api/food-analyses')
        .attach('primaryImage', Buffer.from('not-an-image'), 'meal.jpg');
      assert.equal(invalidImage.status, 400);
      assert.equal(invalidImage.body.error.code, 'INVALID_IMAGE');
    }

    photoLimited = await request(app)
      .post('/api/food-analyses')
      .attach('primaryImage', JPEG, 'meal.jpg');
  } finally {
    process.stdout.write = originalWrite;
  }

  assert.equal(photoLimited.status, 429);
  assert.deepEqual(photoLimited.body, {
    error: {
      code: 'RATE_LIMITED',
      message: 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
      details: {},
    },
  });
  assert.equal(telemetry.length, 11);
  assert.equal(telemetry.every((event) => (
    typeof event.requestId === 'string'
      && /^[0-9a-f-]{36}$/.test(event.requestId)
  )), true);
});
