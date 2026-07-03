package com.example.myapplication.feature.today

import com.example.myapplication.core.achievement.AchievementType
import kotlin.math.roundToInt

internal fun buildWorkoutShareText(
    workoutTitle: String,
    completed: Int,
    total: Int,
    achievements: List<AchievementType>,
): String {
    val safeTotal = total.coerceAtLeast(0)
    val safeCompleted = completed.coerceIn(0, safeTotal)
    val percentage = if (safeTotal == 0) {
        0
    } else {
        (safeCompleted * 100.0 / safeTotal).roundToInt()
    }
    val lines = mutableListOf(
        "🏋️ KẾT QUẢ LUYỆN TẬP SMARTGYM 🏋️",
        "💪 Tôi vừa hoàn thành: $workoutTitle",
        "✅ Tiến độ: $safeCompleted/$safeTotal bài tập ($percentage% hoàn thành)",
    )
    if (achievements.isNotEmpty()) {
        lines += "🏆 Huy hiệu mới: ${achievements.joinToString { it.titleVi }}"
    }
    lines += "🔥 Tập luyện thông minh, offline-first cùng SmartGym!"
    return lines.joinToString(separator = "\n")
}
