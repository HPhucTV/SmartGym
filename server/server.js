const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

function cleanJsonResponse(text) {
  if (typeof text !== 'string') return '';
  let cleaned = text.trim();
  if (cleaned.startsWith('```')) {
    cleaned = cleaned.replace(/^```(json)?/, '').replace(/```$/, '').trim();
  }
  return cleaned;
}

const vietnameseFoodDatabase = {
  "cơm trắng": { name: "Cơm trắng", caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28.0, fatPer100g: 0.3 },
  "ức gà": { name: "Ức gà luộc/hấp", caloriesPer100g: 165, proteinPer100g: 31.0, carbsPer100g: 0.0, fatPer100g: 3.6 },
  "trứng chiên": { name: "Trứng chiên", caloriesPerUnit: 98, proteinPerUnit: 6.8, carbsPerUnit: 0.5, fatPerUnit: 7.5 },
  "trứng luộc": { name: "Trứng luộc", caloriesPerUnit: 78, proteinPerUnit: 6.3, carbsPerUnit: 0.6, fatPerUnit: 5.3 },
  "trứng ốp la": { name: "Trứng ốp la", caloriesPerUnit: 98, proteinPerUnit: 6.8, carbsPerUnit: 0.5, fatPerUnit: 7.5 },
  "trứng gà": { name: "Trứng gà luộc", caloriesPerUnit: 78, proteinPerUnit: 6.3, carbsPerUnit: 0.6, fatPerUnit: 5.3 },
  "thịt heo kho": { name: "Thịt heo kho", caloriesPer100g: 260, proteinPer100g: 16.5, carbsPer100g: 1.5, fatPer100g: 21.5 },
  "cá chiên": { name: "Cá chiên", caloriesPer100g: 200, proteinPer100g: 18.0, carbsPer100g: 0.0, fatPer100g: 14.0 },
  "rau luộc": { name: "Rau luộc", caloriesPer100g: 35, proteinPer100g: 1.5, carbsPer100g: 7.0, fatPer100g: 0.2 },
  "rau xanh": { name: "Rau luộc", caloriesPer100g: 35, proteinPer100g: 1.5, carbsPer100g: 7.0, fatPer100g: 0.2 },
  "phở bò": { name: "Phở bò", caloriesPerUnit: 350, proteinPerUnit: 18, carbsPerUnit: 52, fatPerUnit: 8 },
  "bún bò": { name: "Bún bò Huế", caloriesPerUnit: 450, proteinPerUnit: 22, carbsPerUnit: 60, fatPerUnit: 12 },
  "bánh mì": { name: "Bánh mì kẹp thịt", caloriesPerUnit: 400, proteinPerUnit: 15, carbsPerUnit: 55, fatPerUnit: 13 },
  "xôi": { name: "Xôi", caloriesPer100g: 344, proteinPer100g: 6.5, carbsPer100g: 75.0, fatPer100g: 1.5 },
  "mì gói": { name: "Mì gói", caloriesPerUnit: 350, proteinPerUnit: 7, carbsPerUnit: 50, fatPerUnit: 13 }
};

function removeVietnameseTones(str) {
  if (typeof str !== 'string') return '';
  str = str.toLowerCase();
  str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a");
  str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e");
  str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i");
  str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o");
  str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u");
  str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y");
  str = str.replace(/đ/g, "d");
  return str;
}

function findDatabaseFood(componentName) {
  if (!componentName) return null;
  const normName = removeVietnameseTones(componentName).trim();

  // 1. First pass: Exact match
  for (const key of Object.keys(vietnameseFoodDatabase)) {
    const normKey = removeVietnameseTones(key).trim();
    if (normName === normKey) {
      return vietnameseFoodDatabase[key];
    }
  }

  // 2. Second pass: Prevent matching generic short words to specific multi-word dishes
  const genericShortWords = ["thit", "ca", "trung", "rau", "com"];
  if (genericShortWords.includes(normName)) {
    if (normName === "com") return vietnameseFoodDatabase["cơm trắng"];
    if (normName === "rau") return vietnameseFoodDatabase["rau luộc"];
    return null;
  }

  // 3. Third pass: Substring matching for longer or more specific terms
  for (const key of Object.keys(vietnameseFoodDatabase)) {
    const normKey = removeVietnameseTones(key).trim();
    if (normName.includes(normKey) || normKey.includes(normName)) {
      return vietnameseFoodDatabase[key];
    }
  }
  return null;
}

// Setup multer for in-memory file uploads
const upload = multer({ limits: { fileSize: 10 * 1024 * 1024 } }); // 10MB limit

app.post('/api/analyze-food', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Không tìm thấy tệp tin hình ảnh tải lên.' });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'Chưa cấu hình GEMINI_API_KEY trên server backend.' });
    }

    // Convert image buffer to base64
    const base64Image = req.file.buffer.toString('base64');
    const mimeType = req.file.mimetype;

    const requestPayload = {
      contents: [
        {
          parts: [
            {
              text: `Bạn là trợ lý dinh dưỡng thông minh của ứng dụng Gym App. Hãy phân tích hình ảnh này (có thể là đĩa thức ăn, món ăn thực tế, hoặc ảnh chụp bao bì/bảng thành phần dinh dưỡng của sản phẩm) và trả về kết quả cấu trúc dưới dạng JSON có cấu trúc chính xác như bên dưới (không có các ký tự markdown như \`\`\`json ở ngoài).

QUY TẮC PHÂN TÍCH:
1. NẾU LÀ ẢNH CHỤP BẢNG THÀNH PHẦN DINH DƯỠNG (Nutrition Facts) hoặc BAO BÌ SẢN PHẨM:
   - Bạn PHẢI tìm kiếm và đọc chính xác (OCR) các thông số: Năng lượng (Calo), Chất đạm (Protein), Carbohydrat (Carbs), Chất béo (Fat).
   - Hãy xem kỹ chỉ số đó được tính trên "100g" hay trên "Khẩu phần" (Serving Size), và đọc kỹ "Khối lượng tịnh" (Net weight) hoặc số khẩu phần của cả gói để tính toán chính xác tổng dinh dưỡng cho TOÀN BỘ GÓI/SẢN PHẨM (trừ khi hình ảnh chỉ ra một lượng cụ thể được tiêu thụ).
   - Ví dụ trong ảnh: Nhãn ghi "GIÁ TRỊ DINH DƯỠNG TRONG 100 g: Năng lượng 498 kcal, Đạm 4.4g, Carbs 49.8g, Béo 31.1g" và ghi thêm "Khối lượng tịnh: 57 g" (hoặc xấp xỉ 0.6 lần 100g). Bạn phải tính toán giá trị cho gói 57g:
     * Calo = 498 * 0.57 = 284 kcal
     * Đạm = 4.4 * 0.57 = 2.5 g (làm tròn thành 3g)
     * Carbs = 49.8 * 0.57 = 28.4 g (làm tròn thành 28g)
     * Béo = 31.1 * 0.57 = 17.7 g (làm tròn thành 18g)
   - Tránh việc đoán mò khi có số liệu rõ ràng trên nhãn. Điền các giá trị đã tính toán này vào các trường tương ứng của JSON.

2. NẾU LÀ ẢNH ĐĨA THỨC ĂN/MÓN ĂN THỰC TẾ:
   - Hãy nhận diện các nguyên liệu chính trên đĩa và ước tính calo, đạm, carbs, chất béo hợp lý nhất.

Cấu trúc JSON yêu cầu:
{
  "dishName": "Tên món ăn/sản phẩm bằng tiếng Việt (ví dụ: 'Snack Toonies Chef' hoặc 'Khoai tây chiên xốt chấm')",
  "confidence": 0.95, (số thực từ 0.0 đến 1.0 thể hiện độ tin cậy của phép tính. Nếu là ảnh nhãn dinh dưỡng rõ ràng thì confidence >= 0.85, nếu là ảnh món ăn thực tế tự nấu ước lượng qua ảnh thì confidence chỉ nên khoảng 0.50 đến 0.80)
  "needsUserConfirmation": false, (boolean: true nếu là ảnh món ăn thực tế cần người dùng xác nhận khẩu phần, false nếu là ảnh nhãn dinh dưỡng rõ ràng có số liệu chính xác)
  "calculationProcess": "Bạn BẮT BUỘC phải ghi rõ các số liệu đọc được từ nhãn dinh dưỡng (nếu có) hoặc kích thước đĩa ăn ước lượng, công thức toán học và phép tính cụ thể dẫn đến kết quả Calo, Protein, Carbs, Fat để người dùng đối chiếu. Viết bằng tiếng Việt.",
  "totalCalories": 284, (số nguyên calo đã tính toán/ước lượng)
  "proteinGrams": 3, (số nguyên đạm)
  "carbsGrams": 28, (số nguyên tinh bột)
  "fatGrams": 18, (số nguyên chất béo)
  "fitnessScore": 4, (số nguyên từ 1 đến 10 đánh giá độ lành mạnh với mục tiêu tập luyện)
  "advice": "Lời khuyên dinh dưỡng bằng tiếng Việt ngắn gọn từ 1 đến 2 câu.",
  "sweatPayment": {
    "exerciseId": "bodyweight_squat", (Mã bài tập cần bù đắp, chọn 1 trong các mã: 'bodyweight_squat' (Squat không tạ), 'push_up' (Chống đẩy), 'glute_bridge' (Cầu mông), 'plank' (Plank cẳng tay))
    "exerciseName": "Squat không tạ", (Tên tiếng Việt hiển thị bài tập)
    "extraSets": 2 (số lượng hiệp tập cần bù thêm từ 1 đến 3 hiệp dựa theo lượng calo dư thừa)
  },
  "components": [ (Danh sách các thành phần phân tích)
    {
      "name": "Tên thành phần (ví dụ: 'Cơm trắng', 'Trứng chiên')", 
      "estimatedWeightGrams": 200, (số nguyên hoặc null nếu không đo bằng gram)
      "quantity": null, (số nguyên hoặc null nếu không dùng đơn vị đếm như quả, bát, cái)
      "portionSize": "medium", ("small", "medium" hoặc "large")
      "calories": 260, 
      "protein": 5, 
      "carbs": 56, 
      "fat": 1
    }
  ]
}

Hãy phân tích và tính toán các chỉ số dinh dưỡng chính xác nhất có thể.`
            },
            {
              inlineData: {
                mimeType: mimeType,
                data: base64Image
              }
            }
          ]
        }
      ],
      generationConfig: {
        responseMimeType: "application/json"
      }
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestPayload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini API Error:', errorText);
      return res.status(500).json({ error: 'Lỗi phản hồi từ Gemini API.' });
    }

    const data = await response.json();
    const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!responseText) {
      return res.status(500).json({ error: 'Không nhận được phân tích hợp lệ từ AI.' });
    }

    // Parse the JSON response from Gemini
    const cleanedText = cleanJsonResponse(responseText);
    const resultJson = JSON.parse(cleanedText);

    // Recalculate component values using database lookups if matched
    let hasDatabaseMatch = false;
    let dbCalculationLog = [];

    if (resultJson.components && Array.isArray(resultJson.components)) {
      resultJson.components = resultJson.components.map(comp => {
        const matched = findDatabaseFood(comp.name);
        if (matched) {
          hasDatabaseMatch = true;
          let calories, protein, carbs, fat;
          if (matched.caloriesPerUnit !== undefined) {
            const qty = comp.quantity || 1;
            calories = Math.round(matched.caloriesPerUnit * qty);
            protein = Math.round(matched.proteinPerUnit * qty);
            carbs = Math.round(matched.carbsPerUnit * qty);
            fat = Math.round(matched.fatPerUnit * qty);
            dbCalculationLog.push(`Khớp database: ${comp.name} -> ${matched.name} (${qty} phần).`);
          } else {
            let weight = comp.estimatedWeightGrams || 100;
            if (!comp.estimatedWeightGrams && comp.portionSize) {
              if (comp.portionSize === "small" || comp.portionSize === "Nhỏ") weight = 120;
              else if (comp.portionSize === "large" || comp.portionSize === "Lớn") weight = 280;
              else weight = 200;
            }
            const factor = weight / 100;
            calories = Math.round(matched.caloriesPer100g * factor);
            protein = Math.round(matched.proteinPer100g * factor);
            carbs = Math.round(matched.carbsPer100g * factor);
            fat = Math.round(matched.fatPer100g * factor);
            dbCalculationLog.push(`Khớp database: ${comp.name} -> ${matched.name} (${weight}g).`);
          }
          return {
            name: `${comp.name} (Database matched)`,
            calories,
            protein,
            carbs,
            fat
          };
        }
        return comp;
      });
    }

    if (hasDatabaseMatch) {
      let totalCal = 0;
      let totalProtein = 0;
      let totalCarbs = 0;
      let totalFat = 0;
      
      resultJson.components.forEach(comp => {
        totalCal += comp.calories || 0;
        totalProtein += comp.protein || 0;
        totalCarbs += comp.carbs || 0;
        totalFat += comp.fat || 0;
      });

      resultJson.totalCalories = totalCal;
      resultJson.proteinGrams = totalProtein;
      resultJson.carbsGrams = totalCarbs;
      resultJson.fatGrams = totalFat;
      
      const logText = dbCalculationLog.join("\n");
      resultJson.calculationProcess = (resultJson.calculationProcess ? resultJson.calculationProcess + "\n\n" : "") + 
        "--- NUTRITION DATABASE LOG ---\n" + logText;
    } else {
      // Recalculate calories to ensure mathematical consistency (Protein*4 + Carbs*4 + Fat*9)
      const p = parseInt(resultJson.proteinGrams) || 0;
      const c = parseInt(resultJson.carbsGrams) || 0;
      const f = parseInt(resultJson.fatGrams) || 0;
      const macroCalories = (p * 4) + (c * 4) + (f * 9);
      
      if (resultJson.totalCalories && Math.abs(resultJson.totalCalories - macroCalories) > 30) {
        console.log(`Calorie discrepancy detected! AI: ${resultJson.totalCalories}, Macros calc: ${macroCalories}. Aligning with macros.`);
        resultJson.totalCalories = Math.round(macroCalories);
      }
    }

    return res.json(resultJson);

  } catch (error) {
    console.error('Server error during food analysis:', error);
    return res.status(500).json({ error: 'Đã có lỗi hệ thống xảy ra trên server.', details: error.message });
  }
});

app.post('/api/coach-review', async (req, res) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'Chưa cấu hình GEMINI_API_KEY trên server backend.' });
    }

    const {
      goal,
      level,
      sessionTitle,
      completedToday,
      caloriesEaten,
      calorieLimit,
      proteinEaten,
      carbsEaten,
      fatEaten,
      sweatActive,
      sweatExerciseName,
      sweatExtraSets
    } = req.body;

    const requestPayload = {
      contents: [
        {
          parts: [
            {
              text: `Bạn là trợ lý huấn luyện viên thể hình và dinh dưỡng cá nhân AI Coach của ứng dụng Gym App.
Hãy đưa ra một nhận định và lời khuyên ngắn gọn bằng tiếng Việt (từ 1 đến 3 câu, khoảng 40-70 từ) dựa trên thông số ngày hôm nay của người dùng:

Thông số hiện tại:
- Mục tiêu tập: ${goal || 'Chưa thiết lập'}
- Cấp độ: ${level || 'Chưa thiết lập'}
- Bài tập hôm nay: ${sessionTitle || 'Chưa thiết lập'}
- Trạng thái tập: ${completedToday ? "Đã hoàn thành xong buổi tập hôm nay ✓" : "Chưa hoàn thành buổi tập"}
- Dinh dưỡng đã nạp: ${caloriesEaten || 0} / ${calorieLimit || 2000} kcal (Đạm: ${proteinEaten || 0}g, Tinh bột: ${carbsEaten || 0}g, Chất béo: ${fatEaten || 0}g)
- Bài tập bù Calo (Sweat Payment): ${sweatActive ? `Đang có nhiệm vụ tập thêm ${sweatExtraSets || 0} hiệp [${sweatExerciseName || ''}]` : "Không có"}

Yêu cầu lời khuyên:
1. Nhận xét tích cực, động viên và phân tích khoa học ngắn gọn dựa trên mục tiêu của họ.
2. Nếu họ đã tập xong, hãy động viên và nhắc nhở phục hồi hoặc bù calo nếu ăn dư.
3. Nếu họ chưa tập, hãy thúc đẩy họ hoàn thành bài tập.
4. Lời khuyên cần tự nhiên, gần gũi, hữu ích. Trả về dưới dạng chuỗi văn bản thông thường bằng tiếng Việt (không trả về JSON hay ký tự markdown).`
            }
          ]
        }
      ]
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestPayload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini API Error (Coach Review):', errorText);
      return res.status(500).json({ error: 'Lỗi phản hồi từ Gemini API.' });
    }

    const data = await response.json();
    const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!responseText) {
      return res.status(500).json({ error: 'Không nhận được phân tích hợp lệ từ AI.' });
    }

    return res.json({ review: responseText.trim() });

  } catch (error) {
    console.error('Server error during coach review:', error);
    return res.status(500).json({ error: 'Đã có lỗi hệ thống xảy ra trên server.', details: error.message });
  }
});

const localBarcodeDatabase = {
  "8934563138073": {
    dishName: "Snack Toonies Chef (Mã vạch)",
    totalCalories: 284,
    proteinGrams: 3,
    carbsGrams: 28,
    fatGrams: 18,
    advice: "Đồ ăn vặt đóng gói có lượng chất béo bão hòa cao. Hãy hạn chế ăn thường xuyên.",
    constituents: [],
    sweatPayment: { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: 2 },
    calculationProcess: "Tra cứu offline: Gói 57g",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8936011773005": {
    dishName: "Sữa tươi TH True Milk 180ml (Mã vạch)",
    totalCalories: 126,
    proteinGrams: 6,
    carbsGrams: 9,
    fatGrams: 7,
    advice: "Nguồn đạm và canxi tự nhiên tốt cho cơ bắp. Rất thích hợp sau tập.",
    constituents: [],
    sweatPayment: null,
    calculationProcess: "Tra cứu offline: Hộp 180ml",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8934563128906": {
    dishName: "Mì ăn liền Hảo Hảo (Mã vạch)",
    totalCalories: 350,
    proteinGrams: 7,
    carbsGrams: 50,
    fatGrams: 13,
    advice: "Món ăn nhiều tinh bột và muối natri. Nên bổ sung thêm thịt và rau xanh.",
    constituents: [],
    sweatPayment: { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: 3 },
    calculationProcess: "Tra cứu offline: Gói 85g",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8935049501503": {
    dishName: "Coca-Cola Original Taste 320ml (Mã vạch)",
    totalCalories: 134,
    proteinGrams: 0,
    carbsGrams: 34,
    fatGrams: 0,
    advice: "Nước ngọt có gas chứa lượng đường tinh luyện cao. Nên hạn chế khi giảm cân.",
    constituents: [],
    sweatPayment: { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: 1 },
    calculationProcess: "Tra cứu offline: Lon 320ml (Dinh dưỡng: 42kcal/100ml)",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8934588232220": {
    dishName: "Nước tăng lực Sting Dâu lon 330ml (Mã vạch)",
    totalCalories: 242,
    proteinGrams: 0,
    carbsGrams: 60,
    fatGrams: 0,
    advice: "Hàm lượng đường và caffeine cao. Tránh uống vào buổi tối muộn gây mất ngủ.",
    constituents: [],
    sweatPayment: { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: 2 },
    calculationProcess: "Tra cứu offline: Lon 330ml (Dinh dưỡng: ~73kcal/100ml)",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8934614030141": {
    dishName: "Sữa đậu nành Fami Nguyên chất 200ml (Mã vạch)",
    totalCalories: 116,
    proteinGrams: 6,
    carbsGrams: 16,
    fatGrams: 3,
    advice: "Nguồn đạm thực vật lành mạnh và chất béo tốt từ đậu nành.",
    constituents: [],
    sweatPayment: null,
    calculationProcess: "Tra cứu offline: Hộp 200ml (Dinh dưỡng: 58kcal/100ml)",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8934673606820": {
    dishName: "Sữa chua ăn Vinamilk có đường 100g (Mã vạch)",
    totalCalories: 105,
    proteinGrams: 4,
    carbsGrams: 16,
    fatGrams: 3,
    advice: "Cung cấp lợi khuẩn tốt cho hệ tiêu hóa và hỗ trợ hấp thu dưỡng chất tốt hơn.",
    constituents: [],
    sweatPayment: null,
    calculationProcess: "Tra cứu offline: Hộp 100g",
    confidence: 1.0,
    needsUserConfirmation: false
  },
  "8936036020380": {
    dishName: "Bánh Orion ChocoPie 33g (Mã vạch)",
    totalCalories: 140,
    proteinGrams: 2,
    carbsGrams: 22,
    fatGrams: 6,
    advice: "Bánh ngọt chứa lượng đường và chất béo cao. Ăn một lượng vừa phải sau tập để bổ sung năng lượng nhanh.",
    constituents: [],
    sweatPayment: { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: 1 },
    calculationProcess: "Tra cứu offline: Tính cho 1 chiếc bánh 33g trong hộp 12 gói",
    confidence: 1.0,
    needsUserConfirmation: false
  }
};

// Load offline dataset of Vietnamese products
let offlineBarcodeDatabase = {};
try {
  const datasetPath = path.join(__dirname, 'vietnam_products.json');
  if (fs.existsSync(datasetPath)) {
    offlineBarcodeDatabase = JSON.parse(fs.readFileSync(datasetPath, 'utf8'));
    console.log(`Successfully loaded ${Object.keys(offlineBarcodeDatabase).length} offline Vietnamese products from vietnam_products.json`);
  } else {
    console.log('Offline Vietnamese products dataset file (vietnam_products.json) not found.');
  }
} catch (e) {
  console.error('Failed to load offline products dataset:', e);
}

app.get('/api/barcode/:code', async (req, res) => {
  try {
    const { code } = req.params;
    if (!code) {
      return res.status(400).json({ error: 'Thiếu mã vạch cần tra cứu.' });
    }

    // 1. Check local mock database first
    if (localBarcodeDatabase[code]) {
      console.log(`Barcode ${code} found in local database.`);
      return res.json(localBarcodeDatabase[code]);
    }

    // 1b. Check loaded offline dataset
    if (offlineBarcodeDatabase[code]) {
      console.log(`Barcode ${code} found in offline dataset.`);
      return res.json(offlineBarcodeDatabase[code]);
    }

    // 2. Query Open Food Facts API online
    console.log(`Querying Open Food Facts for barcode: ${code}`);
    const offUrl = `https://world.openfoodfacts.org/api/v2/product/${code}.json`;
    
    let productData = null;
    try {
      const response = await fetch(offUrl, {
        headers: {
          'User-Agent': 'GymAppCalorieCalculator - Android - Version 1.0'
        }
      });
      if (response.ok) {
        productData = await response.json();
      }
    } catch (e) {
      console.error('Failed to fetch from Open Food Facts:', e);
    }

    if (!productData || productData.status !== 1 || !productData.product) {
      console.log(`Barcode ${code} not resolved online. Returning editable fallback.`);
      return res.json({
        dishName: `Mã vạch: ${code}`,
        totalCalories: 0,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
        fitnessScore: 5,
        advice: "Mã vạch này chưa có trong cơ sở dữ liệu. Vui lòng tự nhập thông tin dinh dưỡng của món ăn.",
        constituents: [],
        sweatPayment: null,
        calculationProcess: "Không tìm thấy thông tin trực tuyến. Bạn có thể tự điền thông số từ nhãn dinh dưỡng bao bì.",
        confidence: 0.0,
        needsUserConfirmation: true
      });
    }

    const product = productData.product;
    const dishName = product.product_name_vi || product.product_name || `Sản phẩm (${code})`;
    const nutriments = product.nutriments || {};

    // Get nutrients per 100g/100ml
    const caloriesPer100g = nutriments['energy-kcal_100g'] || nutriments['energy-kcal'] || 0;
    const proteinPer100g = nutriments['proteins_100g'] || 0;
    const carbsPer100g = nutriments['carbohydrates_100g'] || 0;
    const fatPer100g = nutriments['fat_100g'] || 0;

    // Check serving size
    const servingQuantity = parseFloat(product.serving_quantity) || 100; // fallback to 100g
    const factor = servingQuantity / 100;

    const totalCalories = Math.round(caloriesPer100g * factor);
    const proteinGrams = Math.round(proteinPer100g * factor);
    const carbsGrams = Math.round(carbsPer100g * factor);
    const fatGrams = Math.round(fatPer100g * factor);

    const brand = product.brands ? ` [${product.brands}]` : '';

    const scanResult = {
      dishName: `${dishName}${brand}`.trim(),
      totalCalories: totalCalories || 100, // safety fallback
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      fitnessScore: 5,
      advice: `Thông tin tra cứu từ Open Food Facts cho khẩu phần cỡ ${servingQuantity}g/ml.`,
      constituents: [],
      sweatPayment: totalCalories > 300 ? { exerciseId: "bodyweight_squat", exerciseName: "Squat không tạ", extraSets: Math.ceil(totalCalories / 120) } : null,
      calculationProcess: `Nguồn: Open Food Facts API\nMã vạch: ${code}\nKhẩu phần tính: ${servingQuantity}g/ml\n(Dinh dưỡng gốc/100g: ${caloriesPer100g} kcal, ${proteinPer100g}g đạm, ${carbsPer100g}g tinh bột, ${fatPer100g}g béo)`,
      confidence: 1.0,
      needsUserConfirmation: false
    };

    console.log(`Successfully resolved barcode ${code}: ${scanResult.dishName}`);
    return res.json(scanResult);

  } catch (error) {
    console.error('Error during barcode lookup:', error);
    return res.status(500).json({ error: 'Lỗi trong quá trình tra cứu thông tin mã vạch.', details: error.message });
  }
});

app.post('/api/explain-decision', async (req, res) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'Chưa cấu hình GEMINI_API_KEY trên server backend.' });
    }

    const { kind, reasonVi, beforeValue, afterValue } = req.body;

    if (!kind || !reasonVi) {
      return res.status(400).json({ error: 'Thiếu thông tin quyết định cần giải thích.' });
    }

    const requestPayload = {
      contents: [
        {
          parts: [
            {
              text: `Bạn là một trợ lý huấn luyện viên thể hình chuyên nghiệp của ứng dụng Gym App.
Hãy viết lại lời giải thích/nhận xét (khoảng 2-4 câu, tiếng Việt tự nhiên, thân thiện và mang tính động viên) cho quyết định điều chỉnh sau đây của người dùng:
- Loại điều chỉnh: ${kind}
- Lý do kỹ thuật: ${reasonVi}
- Trạng thái trước: ${beforeValue || 'Chưa rõ'}
- Trạng thái sau: ${afterValue || 'Chưa rõ'}

Yêu cầu:
1. Giải thích lý do vì sao sự thay đổi này lại tốt cho mục tiêu sức khỏe/thể hình của họ dựa trên dữ liệu lịch sử hoặc check-in.
2. Tuyệt đối không thay đổi các số liệu hoặc kết quả điều chỉnh trong 'Lý do kỹ thuật'.
3. Văn phong tích cực, ngắn gọn, phù hợp với phong cách gym chuyên nghiệp.
4. Trả về dưới dạng một chuỗi văn bản thuần bằng tiếng Việt (không trả về định dạng JSON hay markdown).`
            }
          ]
        }
      ]
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestPayload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini API Error (Explain Decision):', errorText);
      return res.status(500).json({ error: 'Lỗi phản hồi từ Gemini API.' });
    }

    const data = await response.json();
    const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!responseText) {
      return res.status(500).json({ error: 'Không nhận được phân tích hợp lệ từ AI.' });
    }

    return res.json({ explanation: responseText.trim() });

  } catch (error) {
    console.error('Server error during decision explanation:', error);
    return res.status(500).json({ error: 'Đã có lỗi hệ thống xảy ra trên server.', details: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server Gym App Backend đang chạy tại http://localhost:${port}`);
});

