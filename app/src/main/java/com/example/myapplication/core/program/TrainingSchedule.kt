package com.example.myapplication.core.program

import com.example.myapplication.core.model.legacyTrainingDays
import java.time.DayOfWeek

object TrainingSchedule {
    val durationBuckets: Set<Int> = setOf(30, 45, 60, 75, 90)

    fun validate(trainingDays: Set<DayOfWeek>, sessionDurationMinutes: Int) {
        require(trainingDays.size in 1..6) { "Training days must contain 1..6 unique weekdays" }
        require(sessionDurationMinutes in durationBuckets) {
            "Session duration must be one of ${durationBuckets.sorted()}"
        }
    }

    fun defaultDays(sessionsPerWeek: Int): Set<DayOfWeek> = legacyTrainingDays(sessionsPerWeek)
}
