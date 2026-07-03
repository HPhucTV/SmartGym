package com.example.myapplication.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.WorkoutSession
import com.example.myapplication.core.motivation.MotivationRepository
import com.example.myapplication.core.nutrition.NutritionDay
import com.example.myapplication.data.NutritionRepository
import com.example.myapplication.data.WorkoutRepository
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class HomeUiState(
    val epochDay: Long = 0,
    val workoutTitle: String? = null,
    val workoutFocus: String? = null,
    val durationMinutes: Int? = null,
    val completedExercises: Int = 0,
    val totalExercises: Int = 0,
    val completedThisWeek: Int = 0,
    val streakDays: Int = 0,
    val caloriesConsumed: Int = 0,
    val caloriesTarget: Int? = null,
    val dailyQuote: String = "",
)

internal fun mapHomeUiState(
    epochDay: Long,
    workout: WorkoutSession?,
    completed: List<CompletedWorkout>,
    nutrition: NutritionDay,
    dailyQuote: String = "",
): HomeUiState {
    val today = LocalDate.ofEpochDay(epochDay)
    val weekStart = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).toEpochDay()
    val weekEnd = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY)).toEpochDay()
    val completedDays = completed.map { it.completedEpochDay }.toSet()

    var streakCursor = if (epochDay in completedDays) epochDay else epochDay - 1
    var streakDays = 0
    while (streakCursor in completedDays) {
        streakDays++
        streakCursor--
    }

    return HomeUiState(
        epochDay = epochDay,
        workoutTitle = workout?.titleVi,
        workoutFocus = workout?.focusVi,
        durationMinutes = workout?.estimatedMinutes,
        completedExercises = workout?.exercises?.count { it.checked } ?: 0,
        totalExercises = workout?.exercises?.size ?: 0,
        completedThisWeek = completed.count { it.completedEpochDay in weekStart..weekEnd },
        streakDays = streakDays,
        caloriesConsumed = nutrition.consumed.calories,
        caloriesTarget = nutrition.target?.calories,
        dailyQuote = dailyQuote,
    )
}
class HomeViewModel(
    repository: WorkoutRepository,
    nutritionRepository: NutritionRepository,
    motivationRepository: MotivationRepository? = null,
    private val currentEpochDay: () -> Long = { LocalDate.now().toEpochDay() },
) : ViewModel() {
    private val quote = motivationRepository?.getDailyQuote(currentEpochDay()) ?: ""

    val uiState: StateFlow<HomeUiState> = combine(
        repository.observeCurrentWorkout(),
        repository.observeCompletedWorkouts(),
        nutritionRepository.observeDay(currentEpochDay()),
    ) { currentWorkout, completedList, nutritionDay ->
        mapHomeUiState(currentEpochDay(), currentWorkout, completedList, nutritionDay, quote)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = HomeUiState(epochDay = currentEpochDay(), dailyQuote = quote),
    )
}
