const express = require('express');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');

const barcodeSchema = z.string().regex(/^\d{8,14}$/);
const REQUEST_TIMEOUT_MS = 8_000;

function boundedNumber(value, { max }) {
  const parsed = Number.parseFloat(value);
  if (!Number.isFinite(parsed) || parsed < 0) return 0;
  return Math.min(parsed, max);
}

function normalizeProduct(product) {
  if (!product || typeof product !== 'object') return null;
  const name = typeof product.product_name_vi === 'string' && product.product_name_vi.trim()
    ? product.product_name_vi.trim()
    : typeof product.product_name === 'string'
      ? product.product_name.trim()
      : '';
  if (!name) return null;

  const brand = typeof product.brands === 'string' && product.brands.trim()
    ? ` [${product.brands.trim()}]`
    : '';
  const dishName = `${name}${brand}`.slice(0, 150);
  const nutriments = product.nutriments && typeof product.nutriments === 'object'
    ? product.nutriments
    : {};
  const servingQuantity = boundedNumber(product.serving_quantity, { max: 10_000 }) || 100;
  const factor = servingQuantity / 100;
  const caloriesPer100g = boundedNumber(
    nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'],
    { max: 9_000 },
  );
  const proteinPer100g = boundedNumber(nutriments.proteins_100g, { max: 100 });
  const carbsPer100g = boundedNumber(nutriments.carbohydrates_100g, { max: 100 });
  const fatPer100g = boundedNumber(nutriments.fat_100g, { max: 100 });
  const isWater = ['nước khoáng', 'nước tinh khiết', 'aquafina', 'dasani']
    .some((candidate) => dishName.toLowerCase().includes(candidate));

  const totalCalories = isWater ? 0 : Math.round(caloriesPer100g * factor);
  const proteinGrams = isWater ? 0 : Math.round(proteinPer100g * factor);
  const carbsGrams = isWater ? 0 : Math.round(carbsPer100g * factor);
  const fatGrams = isWater ? 0 : Math.round(fatPer100g * factor);

  return {
    dishName,
    totalCalories,
    proteinGrams,
    carbsGrams,
    fatGrams,
    fitnessScore: 5,
    advice: `Dữ liệu Open Food Facts cho khẩu phần ${servingQuantity}g/ml. Hãy kiểm tra lại nhãn trước khi lưu.`,
    constituents: [],
    sweatPayment: totalCalories > 300
      ? {
        exerciseId: 'bodyweight_squat',
        exerciseName: 'Squat không tạ',
        extraSets: Math.min(6, Math.ceil(totalCalories / 120)),
      }
      : null,
    calculationProcess: `Nguồn: Open Food Facts\nKhẩu phần: ${servingQuantity}g/ml`,
    confidence: 0.9,
    needsUserConfirmation: true,
  };
}

function createBarcodeRouter({
  bundledProducts = {},
  fetchImpl = globalThis.fetch,
  rateLimitOptions = { windowMs: 10 * 60 * 1000, limit: 30 },
} = {}) {
  if (typeof fetchImpl !== 'function') throw new TypeError('fetchImpl is required');
  const router = express.Router();
  const localProducts = Object.assign(Object.create(null), bundledProducts);

  router.use(rateLimit({
    windowMs: rateLimitOptions.windowMs,
    limit: rateLimitOptions.limit,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
      error: 'Bạn đã thực hiện quá nhiều truy vấn mã vạch. Vui lòng thử lại sau.',
    },
  }));

  router.get('/:barcode', async (req, res) => {
    const parsedBarcode = barcodeSchema.safeParse(req.params.barcode);
    if (!parsedBarcode.success) {
      return res.status(400).json({
        error: 'invalid_barcode',
        message: 'Mã vạch phải gồm từ 8 đến 14 chữ số.',
      });
    }
    const barcode = parsedBarcode.data;
    const bundled = localProducts[barcode];
    if (bundled && typeof bundled === 'object') return res.json(bundled);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await fetchImpl(
        `https://world.openfoodfacts.org/api/v0/product/${encodeURIComponent(barcode)}.json`,
        {
          headers: { 'User-Agent': 'SmartGym-Android/1.0' },
          redirect: 'error',
          signal: controller.signal,
        },
      );
      if (!response.ok) throw new Error('OFF_HTTP_ERROR');
      const payload = await response.json();
      const product = payload?.status === 1 ? normalizeProduct(payload.product) : null;
      if (!product) {
        return res.status(404).json({
          error: 'product_not_found',
          message: 'Không tìm thấy sản phẩm ứng với mã vạch này.',
        });
      }
      return res.json(product);
    } catch {
      return res.status(503).json({
        error: 'barcode_lookup_unavailable',
        message: 'Không thể tra cứu mã vạch lúc này.',
      });
    } finally {
      clearTimeout(timeout);
    }
  });

  return router;
}

module.exports = {
  REQUEST_TIMEOUT_MS,
  barcodeSchema,
  createBarcodeRouter,
  normalizeProduct,
};
