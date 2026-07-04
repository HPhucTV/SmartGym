package com.example.myapplication.feature.progress

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.core.model.*
import com.example.myapplication.core.program.ProgramSelectionResult
import com.example.myapplication.core.program.ProgramSelector
import com.example.myapplication.core.progress.ProgressCalculator
import com.example.myapplication.core.progress.WeeklyInsightEngine
import com.example.myapplication.core.progress.GoalForecast
import com.example.myapplication.core.progress.GoalForecastCalculator
import com.example.myapplication.data.WorkoutRepository
import com.example.myapplication.data.WorkoutFeedbackRepository
import com.example.myapplication.core.feedback.WorkoutFeedback
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.temporal.TemporalAdjusters
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch
import kotlinx.coroutines.ExperimentalCoroutinesApi

@OptIn(ExperimentalCoroutinesApi::class)
class ProgressViewModel(
    repository: WorkoutRepository,
    private val programs: List<ProgramTemplate> = emptyList(),
    private val exercises: List<ExerciseDefinition> = emptyList(),
    private val feedbackRepository: WorkoutFeedbackRepository? = null,
    private val currentEpochDay: () -> Long,
) : ViewModel() {
    private val today = MutableStateFlow(currentEpochDay())
    private val selectedMonth = MutableStateFlow(YearMonth.from(LocalDate.ofEpochDay(today.value)))
    private val _uiState = MutableStateFlow<ProgressUiState>(ProgressUiState.Loading)
    val uiState: StateFlow<ProgressUiState> = _uiState.asStateFlow()

    private val exercisesCatalog = exercises.associateBy { it.id }

    private data class ProgressInputs(
        val goal: ActiveGoal?,
        val completed: List<CompletedWorkout>,
        val history: List<WorkoutHistoryEntry>,
        val feedback: List<WorkoutFeedback>,
    )

    init {
        viewModelScope.launch {
            val feedbackFlow = repository.observeActiveGoal().flatMapLatest { goal ->
                if (goal == null || feedbackRepository == null) flowOf(emptyList())
                else feedbackRepository.observeForGoal(goal.id)
            }
            val inputs = combine(
                repository.observeActiveGoal(),
                repository.observeCompletedWorkouts(),
                repository.observeWorkoutHistory(),
                feedbackFlow,
            ) { goal, completed, history, feedback ->
                ProgressInputs(goal, completed, history, feedback)
            }
            combine(
                inputs,
                today,
                selectedMonth,
            ) { data, currentDay, month ->
                resolve(data.goal, data.completed, data.history, data.feedback, currentDay, month)
            }
                .collect { _uiState.value = it }
        }
    }

    fun refreshToday() {
        today.value = currentEpochDay()
    }

    fun previousMonth() = moveMonth(-1)
    fun nextMonth() = moveMonth(1)

    private fun moveMonth(delta: Long) {
        selectedMonth.value = runCatching { selectedMonth.value.plusMonths(delta) }
            .getOrElse { selectedMonth.value }
    }

    private fun resolve(
        goal: ActiveGoal?,
        completedHistory: List<CompletedWorkout>,
        workoutHistory: List<WorkoutHistoryEntry>,
        feedback: List<WorkoutFeedback>,
        currentDay: Long,
        month: YearMonth,
    ): ProgressUiState {
        val allDates = completedHistory.map { it.completedEpochDay }
        val marked = allDates.asSequence()
            .filter { YearMonth.from(LocalDate.ofEpochDay(it)) == month }
            .toSet()
        val monthCount = ProgressCalculator.completedSessionsByMonth(allDates)[month] ?: 0
        val canPrevious = month != YearMonth.of(-999_999_999, 1)
        val canNext = month != YearMonth.of(999_999_999, 12)

        // 1. Calculate Weekly Stats (last 4 weeks)
        val currentMonday = LocalDate.ofEpochDay(currentDay)
            .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val weeklyStats = (3 downTo 0).map { weeksAgo ->
            val monday = currentMonday.minusWeeks(weeksAgo.toLong())
            val sunday = monday.plusDays(6)
            val count = allDates.count { it in monday.toEpochDay()..sunday.toEpochDay() }
            val label = when (weeksAgo) {
                0 -> "Tuần này"
                1 -> "Tuần trước"
                else -> "$weeksAgo tuần trước"
            }
            WeeklyCompletedStats(label, count)
        }

        if (goal == null) {
            return ProgressUiState.NoActiveGoal(
                selectedMonth = month,
                markedEpochDays = marked,
                completedInMonth = monthCount,
                canNavigatePrevious = canPrevious,
                canNavigateNext = canNext,
                weeklyStats = weeklyStats,
                muscleStats = emptyList()
            )
        }

        val activeDates = completedHistory.asSequence()
            .filter { it.goalId == goal.id }
            .map { it.completedEpochDay }
            .toList()

        // 2. Calculate Muscle Stats (based on active goal program sequence)
        val muscleStats = mutableMapOf<MuscleGroup, Int>()
        val programSelection = ProgramSelector.select(goal.config, programs)
        if (programSelection is ProgramSelectionResult.Found) {
            val program = programSelection.program
            // Workouts completed correspond to the first N workouts in sequence
            val completedCount = activeDates.size
            val completedWorkouts = program.workouts.sortedBy { it.sequence }.take(completedCount)
            for (workout in completedWorkouts) {
                for (presc in workout.exercises) {
                    val definition = exercisesCatalog[presc.exerciseId]
                    if (definition != null) {
                        muscleStats[definition.primaryMuscle] = (muscleStats[definition.primaryMuscle] ?: 0) + 1
                    }
                }
            }
        }
        val sortedMuscleStats = muscleStats.map { MuscleCompletedStats(it.key, it.value) }
            .sortedByDescending { it.count }
        val weeklyInsights = WeeklyInsightEngine.generate(
            history = workoutHistory.filter { it.goalId == goal.id },
            feedback = feedback,
            todayEpochDay = currentDay,
        )
        val activeHistory = workoutHistory.filter { it.goalId == goal.id }
        val firstDue = activeHistory.minOfOrNull { it.dueEpochDay }
        val finalDue = activeHistory.maxOfOrNull { it.dueEpochDay }
        val elapsedWeeks = firstDue?.let { due ->
            runCatching { Math.subtractExact(currentDay, due).coerceAtLeast(0L) / 7L }.getOrDefault(0L)
        } ?: 0L
        val forecast = if (firstDue == null || finalDue == null) {
            GoalForecast.InsufficientData
        } else {
            runCatching {
                GoalForecastCalculator.calculate(
                    totalSessions = goal.totalWorkouts,
                    completedSessions = activeDates.size,
                    sessionsPerWeek = goal.config.sessionsPerWeek,
                    firstDueEpochDay = firstDue,
                    plannedFinalDueEpochDay = finalDue,
                    todayEpochDay = currentDay,
                )
            }.getOrDefault(GoalForecast.InsufficientData)
        }

        return ProgressUiState.Content(
            percentage = ProgressCalculator.percentage(activeDates.size, goal.totalWorkouts),
            completedActive = activeDates.size,
            totalActive = goal.totalWorkouts,
            weeklyStreak = ProgressCalculator.weeklyStreak(activeDates, goal.config.sessionsPerWeek, currentDay),
            targetPerWeek = goal.config.sessionsPerWeek,
            selectedMonth = month,
            markedEpochDays = marked,
            completedInMonth = monthCount,
            canNavigatePrevious = canPrevious,
            canNavigateNext = canNext,
            weeklyStats = weeklyStats,
            muscleStats = sortedMuscleStats,
            weeklyInsights = weeklyInsights,
            goalForecast = forecast,
            forecastCompletedSessions = activeDates.size,
            forecastElapsedWeeks = elapsedWeeks,
        )
    }
}
