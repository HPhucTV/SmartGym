package com.example.myapplication.feature.today

import com.example.myapplication.core.achievement.AchievementType
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WorkoutShareTextTest {
    @Test
    fun `completed workout summary contains accurate progress and unlocked badges`() {
        val text = buildWorkoutShareText(
            workoutTitle = "Toàn thân A",
            completed = 3,
            total = 3,
            achievements = listOf(AchievementType.FIRST_WORKOUT),
        )

        assertTrue(text.contains("Toàn thân A"))
        assertTrue(text.contains("3/3 bài tập (100% hoàn thành)"))
        assertTrue(text.contains("Huy hiệu mới: Ngọn Lửa Đầu Tiên"))
    }

    @Test
    fun `summary never claims one hundred percent for incomplete data`() {
        val text = buildWorkoutShareText("Toàn thân A", completed = 2, total = 3, achievements = emptyList())

        assertTrue(text.contains("2/3 bài tập (67% hoàn thành)"))
        assertFalse(text.contains("Huy hiệu mới"))
    }
}
