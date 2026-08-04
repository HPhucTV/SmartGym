const express = require('express');
const cors = require('cors');
const fs = require('fs');
const helmet = require('helmet');
const path = require('path');
require('dotenv').config();
const { AnalysisSessionStore } = require('./src/food-analysis/analysis_session_store');
const { FoodAnalysisService } = require('./src/food-analysis/food_analysis_service');
const { FoodDatabase } = require('./src/food-analysis/food_database');
const { GeminiFoodObserver } = require('./src/food-analysis/gemini_food_observer');
const { NutritionEstimator } = require('./src/food-analysis/nutrition_estimator');
const { createFoodAnalysisRouter } = require('./src/food-analysis/router');
const { createBarcodeRouter } = require('./src/barcode/router');
const { createCoachRouter } = require('./src/coach/router');
const { AnalysisLogger } = require('./src/http/analysis_logger');
const { sendApiError } = require('./src/http/api_error');

const app = express();
const trustedProxyHops = Number.parseInt(process.env.TRUST_PROXY_HOPS ?? '0', 10);
app.set(
  'trust proxy',
  Number.isSafeInteger(trustedProxyHops) && trustedProxyHops > 0
    ? trustedProxyHops
    : false,
);
const port = process.env.PORT || 3000;
const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const allowedOrigins = new Set(
  (process.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.has(origin)) return callback(null, true);
    return callback(null, false);
  },
  methods: ['GET', 'POST'],
}));

const approvedFoods = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'data', 'vietnamese_foods.json'), 'utf8'),
);
const photoFoodDatabase = new FoodDatabase(approvedFoods);
const photoNutritionEstimator = new NutritionEstimator({ database: photoFoodDatabase });
const photoFoodObserver = new GeminiFoodObserver({
  apiKey: process.env.GEMINI_API_KEY,
  model: geminiModel,
});
const photoAnalysisStore = new AnalysisSessionStore({ ttlMs: 15 * 60 * 1000 });
const photoAnalysisLogger = new AnalysisLogger();
const photoAnalysisService = new FoodAnalysisService({
  observer: photoFoodObserver,
  estimator: photoNutritionEstimator,
  sessionStore: photoAnalysisStore,
  logger: photoAnalysisLogger,
});
app.use('/api/food-analyses', createFoodAnalysisRouter({
  service: photoAnalysisService,
  logger: photoAnalysisLogger,
}));

const bundledBarcodeProducts = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'vietnam_products.json'), 'utf8'),
);
app.use('/api/barcodes', createBarcodeRouter({
  bundledProducts: bundledBarcodeProducts,
}));
app.use('/api/coach', createCoachRouter({
  apiKey: process.env.GEMINI_API_KEY,
  model: geminiModel,
}));
app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  return sendApiError(res, error);
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server Gym App Backend đang chạy tại http://localhost:${port}`);
  });
}

module.exports = { app };

