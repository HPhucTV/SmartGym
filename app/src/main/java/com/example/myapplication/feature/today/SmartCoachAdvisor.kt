package com.example.myapplication.feature.today

import com.example.myapplication.core.model.FitnessGoal
import com.example.myapplication.data.NutritionData

object SmartCoachAdvisor {
    fun getLocalAdvice(
        goal: FitnessGoal,
        completedToday: Boolean,
        nutrition: NutritionData,
        sessionTitle: String
    ): String {
        val calories = nutrition.caloriesEaten
        val protein = nutrition.proteinEaten
        val isOverCalorie = calories > 2000 // default limit or approximation

        return when (goal) {
            FitnessGoal.MUSCLE_GAIN -> {
                if (completedToday) {
                    if (protein < 60) {
                        "Bạn đã hoàn thành buổi tập [$sessionTitle] rất tốt! Tuy nhiên, đạm (Protein) nạp vào hôm nay hơi thấp (${protein}g). Hãy bổ sung thêm trứng, sữa chua hoặc thịt gà để hỗ trợ phục hồi và xây dựng cơ bắp nhé! 🥚"
                    } else {
                        "Buổi tập [$sessionTitle] hoàn thành xuất sắc! Lượng đạm ${protein}g nạp vào đang rất tốt để phát triển cơ bắp. Hãy ngủ đủ giấc để cơ thể phục hồi tối đa! 💪"
                    }
                } else {
                    "Hôm nay có buổi tập [$sessionTitle] đang chờ bạn kích hoạt cơ bắp. Đừng quên nạp tinh bột tốt trước tập để có nguồn năng lượng dồi dào nhé! ⚡"
                }
            }
            FitnessGoal.FAT_LOSS_CONDITIONING -> {
                if (completedToday) {
                    if (nutrition.sweatActive) {
                        "Đã tập xong buổi [$sessionTitle]! Bạn nạp vượt calo định mức (${calories} kcal), nhưng nhiệm vụ Sweat Payment [${nutrition.sweatExerciseName}] đã tự động cộng thêm hiệp để bù đắp. Tuyệt vời! 💦"
                    } else if (isOverCalorie) {
                        "Buổi tập [$sessionTitle] đã xong! Lượng calo nạp vào hôm nay hơi cao (${calories} kcal). Hãy chú ý giảm bớt đồ ăn ngọt và chất béo trong thực đơn ngày mai nhé! 🥗"
                    } else {
                        "Chúc mừng bạn đã hoàn thành buổi tập [$sessionTitle] và kiểm soát calo nạp vào cực tốt (${calories} kcal). Bạn đang đi đúng hướng để đốt mỡ hiệu quả! 🧘"
                    }
                } else {
                    "Hãy cố gắng hoàn thành buổi tập [$sessionTitle] hôm nay để duy trì thâm hụt calo đốt mỡ. Uống đủ nước trước và trong khi tập nhé! 💧"
                }
            }
            FitnessGoal.ENDURANCE -> {
                if (completedToday) {
                    "Hoàn thành buổi tập sức bền [$sessionTitle]! Thể lực của bạn đang được nâng cấp qua từng ngày. Hãy bổ sung đầy đủ nước và chất điện giải nhé! 🏃‍♂️"
                } else {
                    "Buổi tập luyện tim mạch và sức bền [$sessionTitle] đang chờ bạn chinh phục. Tập trung vào nhịp thở đều đặn và duy trì nhịp độ nhé! 💨"
                }
            }
            FitnessGoal.GENERAL_FITNESS -> {
                if (completedToday) {
                    "Tuyệt vời! Bạn đã duy trì thói quen vận động tốt hôm nay với bài [$sessionTitle]. Ăn uống cân bằng và ngủ đủ giấc để cơ thể luôn tràn đầy sinh khí nhé! 🍎"
                } else {
                    "Một buổi tập nhẹ nhàng [$sessionTitle] đang chờ bạn. Hãy vận động hôm nay để duy trì lối sống năng động, khỏe mạnh và giảm stress! 🚶"
                }
            }
        }
    }
}
