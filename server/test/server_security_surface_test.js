const assert = require('node:assert/strict');
const test = require('node:test');
const request = require('supertest');

process.env.ALLOWED_ORIGINS = 'https://trusted.example';
const { app } = require('../server');

test('applies security headers without advertising Express', async () => {
  const response = await request(app).get('/api/barcodes/not-a-barcode');

  assert.equal(response.status, 400);
  assert.equal(response.headers['x-powered-by'], undefined);
  assert.equal(response.headers['x-content-type-options'], 'nosniff');
  assert.ok(response.headers['content-security-policy']);
});

test('allows the configured browser origin and withholds CORS from others', async () => {
  const trusted = await request(app)
    .get('/api/barcodes/not-a-barcode')
    .set('Origin', 'https://trusted.example');
  assert.equal(trusted.headers['access-control-allow-origin'], 'https://trusted.example');

  const untrusted = await request(app)
    .get('/api/barcodes/not-a-barcode')
    .set('Origin', 'https://untrusted.example');
  assert.equal(untrusted.headers['access-control-allow-origin'], undefined);
});

test('removed legacy mutation and coach routes stay unavailable', async () => {
  const routes = [
    ['post', '/api/analyze-food'],
    ['get', '/api/scan-barcode?barcode=8930000000001'],
    ['post', '/api/register-barcode'],
    ['post', '/api/coach-review'],
    ['post', '/api/explain-decision'],
  ];

  for (const [method, path] of routes) {
    const response = await request(app)[method](path);
    assert.equal(response.status, 404, `${method.toUpperCase()} ${path}`);
  }
});
