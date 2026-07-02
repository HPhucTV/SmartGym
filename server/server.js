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
              text: `Bạn là trợ lý dinh dưỡng thông minh của ứng dụng Gym App. Hãy phân tích hình ảnh đĩa thức ăn này và trả về kết quả cấu trúc dưới dạng JSON có cấu trúc chính xác như bên dưới (không có các ký tự markdown như \`\`\`json ở ngoài).

Cấu trúc JSON yêu cầu:
{
  "dishName": "Tên đĩa ăn tổng quát bằng tiếng Việt",
  "totalCalories": 550, (số nguyên ước lượng calo)
  "proteinGrams": 30, (số nguyên đạm)
  "carbsGrams": 55, (số nguyên tinh bột)
  "fatGrams": 18, (số nguyên chất béo)
  "fitnessScore": 8, (số nguyên từ 1 đến 10 đánh giá độ lành mạnh với mục tiêu tập luyện)
  "advice": "Lời khuyên dinh dưỡng bằng tiếng Việt ngắn gọn từ 1 đến 2 câu.",
  "sweatPayment": {
    "exerciseId": "bodyweight_squat", (Mã bài tập cần bù đắp, hãy chọn 1 trong các mã sau: 'bodyweight_squat' (Squat không tạ), 'push_up' (Chống đẩy), 'glute_bridge' (Cầu mông), 'plank' (Plank cẳng tay))
    "exerciseName": "Squat không tạ", (Tên tiếng Việt hiển thị bài tập)
    "extraSets": 2 (số lượng hiệp tập cần bù thêm từ 1 đến 3 hiệp dựa theo lượng calo dư thừa)
  },
  "components": [ (Danh sách các thành phần phân tích trên đĩa ăn)
    {"name": "Tên thành phần 1", "calories": 250, "protein": 22, "carbs": 0, "fat": 15},
    {"name": "Tên thành phần 2", "calories": 200, "protein": 4, "carbs": 45, "fat": 1}
  ]
}

Hãy ước tính calo và các chỉ số dinh dưỡng hợp lý nhất có thể.`
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

