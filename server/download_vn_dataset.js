const fs = require('fs');
const path = require('path');

async function downloadDataset() {
  console.log('Starting download of Vietnamese food dataset from Open Food Facts...');
  
  const outputPath = path.join(__dirname, 'vietnam_products.json');
  const pageSize = 100;
  let page = 1;
  let allProducts = {};
  
  // Load existing products if the file exists
  if (fs.existsSync(outputPath)) {
    try {
      allProducts = JSON.parse(fs.readFileSync(outputPath, 'utf8'));
      console.log(`Loaded ${Object.keys(allProducts).length} existing products from ${outputPath}`);
    } catch (e) {
      console.log('No existing valid JSON database found. Starting fresh.');
    }
  }

  let totalProcessed = Object.keys(allProducts).length;
  let consecutiveErrors = 0;
  
  while (consecutiveErrors < 3) {
    const url = `https://world.openfoodfacts.org/api/v2/search?countries_tags=vietnam&page_size=${pageSize}&page=${page}&fields=code,product_name,product_name_vi,brands,nutriments,serving_quantity`;
    console.log(`Fetching page ${page} from: ${url}`);
    
    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'GymAppCalorieCalculator - Android - Version 1.0'
        }
      });
      
      if (!response.ok) {
        consecutiveErrors++;
        console.error(`HTTP Error ${response.status} on page ${page}. Consecutive errors: ${consecutiveErrors}/3. Retrying in 5 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 5000));
        continue;
      }
      
      const data = await response.json();
      const products = data.products || [];
      consecutiveErrors = 0; // reset error count
      
      console.log(`Page ${page} returned ${products.length} products (Total in database: ${data.count})`);
      
      if (products.length === 0) {
        console.log('No more products returned. Download finished.');
        break;
      }
      
      let validInPage = 0;
      for (const p of products) {
        if (!p.code) continue;
        
        // Skip if already in database
        if (allProducts[p.code]) continue;
        
        const name = p.product_name_vi || p.product_name;
        if (!name) continue; // Skip products without a name
        
        const brand = p.brands ? ` [${p.brands}]` : '';
        const dishName = `${name}${brand}`.trim();
        
        const nutriments = p.nutriments || {};
        const caloriesPer100g = parseFloat(nutriments['energy-kcal_100g']) || parseFloat(nutriments['energy-kcal']) || 0;
        const proteinPer100g = parseFloat(nutriments['proteins_100g']) || 0;
        const carbsPer100g = parseFloat(nutriments['carbohydrates_100g']) || 0;
        const fatPer100g = parseFloat(nutriments['fat_100g']) || 0;
        
        const isWater = dishName.toLowerCase().includes('nước khoáng') || dishName.toLowerCase().includes('nước tinh khiết') || dishName.toLowerCase().includes('aquafina') || dishName.toLowerCase().includes('dasani');
        
        const servingQuantity = parseFloat(p.serving_quantity) || 100;
        const factor = servingQuantity / 100;
        
        const totalCalories = isWater ? 0 : Math.round(caloriesPer100g * factor);
        const proteinGrams = isWater ? 0 : Math.round(proteinPer100g * factor);
        const carbsGrams = isWater ? 0 : Math.round(carbsPer100g * factor);
        const fatGrams = isWater ? 0 : Math.round(fatPer100g * factor);
        
        if (!isWater && totalCalories === 0 && proteinGrams === 0 && carbsGrams === 0 && fatGrams === 0) {
          continue;
        }
        
        allProducts[p.code] = {
          dishName: dishName,
          totalCalories: totalCalories,
          proteinGrams: proteinGrams,
          carbsGrams: carbsGrams,
          fatGrams: fatGrams,
          advice: `Sản phẩm đóng gói Việt Nam. Khẩu phần tính: ${servingQuantity}g/ml.`,
          constituents: [],
          sweatPayment: totalCalories > 300 ? { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: Math.ceil(totalCalories / 120) } : null,
          calculationProcess: `Nguồn: Open Food Facts\nKhẩu phần tính: ${servingQuantity}g/ml\n(Dinh dưỡng/100g: ${caloriesPer100g} kcal, ${proteinPer100g}g đạm, ${carbsPer100g}g tinh bột, ${fatPer100g}g béo)`,
          confidence: 1.0,
          needsUserConfirmation: false
        };
        
        validInPage++;
        totalProcessed++;
      }
      
      console.log(`Page ${page} processed. Valid: ${validInPage}. Cumulative: ${totalProcessed}`);
      
      // Save progress incrementally after each page
      fs.writeFileSync(outputPath, JSON.stringify(allProducts, null, 2), 'utf8');
      
      page++;
      // Cooldown to respect rate limits
      await new Promise(resolve => setTimeout(resolve, 1000));
      
    } catch (e) {
      consecutiveErrors++;
      console.error(`Error processing page ${page}:`, e.message, `Consecutive errors: ${consecutiveErrors}/3`);
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
  
  console.log(`\nFinished downloading. Successfully saved ${totalProcessed} Vietnamese products to ${outputPath}`);
}

downloadDataset();
