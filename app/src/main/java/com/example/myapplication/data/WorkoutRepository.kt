package com.example.myapplication.data

import com.example.myapplication.core.model.ActiveGoal
import com.example.myapplication.core.model.CompletedWorkout
import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate
import com.example.myapplication.core.model.WorkoutSession
import kotlinx.coroutines.flow.Flow

interface WorkoutRepository {
    fun observeActiveGoal(): Flow<ActiveGoal?>
    fun observeCurrentWorkout(): Flow<WorkoutSession?>
    fun observeCompletedWorkouts(): Flow<List<CompletedWorkout>>
    suspend fun createGoal(config: GoalConfig, program: ProgramTemplate, startEpochDay: Long)
    suspend fun setExerciseChecked(sessionId: Long, orderIndex: Int, checked: Boolean)
    suspend fun completeWorkout(sessionId: Long, completedEpochDay: Long): CompleteWorkoutResult
    suspend fun substituteExercise(
        sessionId: Long,
        orderIndex: Int,
        replacementExerciseId: String,
    ): ExerciseSubstitutionResult = ExerciseSubstitutionResult.InvalidCandidate
    suspend fun applyTimeBudget(sessionId: Long, minutes: Int?): TimeBudgetResult =
        TimeBudgetResult.StaleSession
    suspend fun archiveActiveGoal()
}

sealed interface TimeBudgetResult {
    data object Applied : TimeBudgetResult
    data object InvalidBudget : TimeBudgetResult
    data object HasCheckedExercises : TimeBudgetResult
    data object StaleSession : TimeBudgetResult
}

sealed interface ExerciseSubstitutionResult {
    data object Applied : ExerciseSubstitutionResult
    data object InvalidCandidate : ExerciseSubstitutionResult
    data object StaleSession : ExerciseSubstitutionResult
    data object AlreadyChecked : ExerciseSubstitutionResult
}

sealed interface CompleteWorkoutResult {
    data object Completed : CompleteWorkoutResult
    data object BlockedByUncheckedExercises : CompleteWorkoutResult
    data object AlreadyCompleted : CompleteWorkoutResult
}
