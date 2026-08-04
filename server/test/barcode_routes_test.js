const assert = require('node:assert/strict');
const test = require('node:test');
const express = require('express');
const request = require('supertest');
const { createBarcodeRouter, normalizeProduct } = require('../src/barcode/router');

function appFor(options) {
  const app = express();
  app.use('/api/barcodes', createBarcodeRouter(options));
  return app;
}

test('rejects malformed barcodes before any upstream request', async () => {
  let called = false;
  const response = await request(appFor({
    fetchImpl: async () => {
      called = true;
      throw new Error('must not be called');
    },
  })).get('/api/barcodes/not-a-barcode');

  assert.equal(response.status, 400);
  assert.equal(response.body.error, 'invalid_barcode');
  assert.equal(called, false);
});

test('returns a bundled product without calling the network', async () => {
  const product = { dishName: 'Sản phẩm đã duyệt', totalCalories: 100 };
  const response = await request(appFor({
    bundledProducts: { 8931234567890: product },
    fetchImpl: async () => { throw new Error('must not be called'); },
  })).get('/api/barcodes/8931234567890');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, product);
});

test('normalizes bounded Open Food Facts data and requires confirmation', async () => {
  const response = await request(appFor({
    fetchImpl: async () => ({
      ok: true,
      json: async () => ({
        status: 1,
        product: {
          product_name_vi: 'Sữa thử nghiệm',
          serving_quantity: 200,
          nutriments: {
            'energy-kcal_100g': 70,
            proteins_100g: 4,
            carbohydrates_100g: 8,
            fat_100g: 2,
          },
        },
      }),
    }),
  })).get('/api/barcodes/8931234567890');

  assert.equal(response.status, 200);
  assert.equal(response.body.totalCalories, 140);
  assert.equal(response.body.proteinGrams, 8);
  assert.equal(response.body.needsUserConfirmation, true);
  assert.match(response.body.calculationProcess, /Open Food Facts/);
});

test('does not accept negative or unbounded upstream nutrition values', () => {
  const normalized = normalizeProduct({
    product_name: 'Dữ liệu lỗi',
    serving_quantity: 100,
    nutriments: {
      'energy-kcal_100g': Number.POSITIVE_INFINITY,
      proteins_100g: -10,
      carbohydrates_100g: 1_000,
      fat_100g: 1_000,
    },
  });

  assert.equal(normalized.totalCalories, 0);
  assert.equal(normalized.proteinGrams, 0);
  assert.equal(normalized.carbsGrams, 100);
  assert.equal(normalized.fatGrams, 100);
});

test('maps missing products and upstream failures to bounded responses', async () => {
  const missing = await request(appFor({
    fetchImpl: async () => ({ ok: true, json: async () => ({ status: 0 }) }),
  })).get('/api/barcodes/8931234567890');
  const unavailable = await request(appFor({
    fetchImpl: async () => { throw new Error('private upstream detail'); },
  })).get('/api/barcodes/8931234567890');

  assert.equal(missing.status, 404);
  assert.equal(missing.body.error, 'product_not_found');
  assert.equal(unavailable.status, 503);
  assert.equal(unavailable.body.error, 'barcode_lookup_unavailable');
  assert.doesNotMatch(JSON.stringify(unavailable.body), /private upstream detail/);
});
