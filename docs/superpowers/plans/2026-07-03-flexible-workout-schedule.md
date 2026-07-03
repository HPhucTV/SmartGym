# Flexible Workout Schedule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users choose one to six training weekdays and a 30–90 minute session duration, then deterministically adapt reviewed preset workouts to that schedule.

**Architecture:** Extend goal configuration and Room persistence with selected weekdays and a duration bucket. Keep existing program assets as reviewed base blueprints; a pure adapter cycles those blueprints for the requested weekly frequency and retains ordered exercises according to the time budget, without random selection.

**Tech Stack:** Kotlin, kotlinx.serialization, Room, Jetpack Compose Material 3, coroutines, JUnit, Android Compose tests.

---

### Task 1: Goal schedule contract

**Files:**
- Modify: `app/src/main/java/com/example/myapplication/core/model/GoalModels.kt`
- Create: `app/src/test/java/com/example/myapplication/core/program/TrainingScheduleTest.kt`

- [ ] Add failing tests for one to six weekdays, duplicate rejection, duration buckets `30, 45, 60, 75, 90`, and evenly spaced legacy defaults.
- [ ] Add `trainingDays: Set<DayOfWeek>` and `sessionDurationMinutes: Int` to `GoalConfig`, preserving source compatibility through deterministic defaults.
- [ ] Add validation requiring `trainingDays.size == sessionsPerWeek`, one to six sessions, and an approved duration bucket.
- [ ] Run the focused tests and keep them green.

### Task 2: Deterministic preset adaptation

**Files:**
- Create: `app/src/main/java/com/example/myapplication/core/program/AdaptiveProgramPlanner.kt`
- Create: `app/src/test/java/com/example/myapplication/core/program/AdaptiveProgramPlannerTest.kt`
- Modify: `app/src/main/java/com/example/myapplication/core/program/ProgramSelector.kt`

- [ ] Write failing tests showing that one to six sessions cycle reviewed base workouts in order and that identical inputs produce identical output.
- [ ] Write failing tests showing that 30-minute sessions retain a non-empty ordered core and longer buckets monotonically add exercises.
- [ ] Implement deterministic base-program matching by goal, level, and equipment without requiring the base program's original weekly frequency.
- [ ] Estimate each ordered prescription's time from sets, duration/repetitions, and rest; retain the largest ordered prefix that fits the bucket, always keeping at least one prescription.
- [ ] Generate `sessionsPerWeek * durationWeeks` workout snapshots with contiguous sequences.
- [ ] Run planner and selector tests.

### Task 3: Selected-weekday scheduling

**Files:**
- Modify: `app/src/main/java/com/example/myapplication/core/program/SchedulePlanner.kt`
- Modify: `app/src/test/java/com/example/myapplication/core/program/SchedulePlannerTest.kt`

- [ ] Write failing tests for Monday/Wednesday/Friday scheduling, week rollover, one-day schedules, and six-day schedules.
- [ ] Implement `dueEpochDays(startEpochDay, trainingDays, workoutCount)` using ordered future selected weekdays.
- [ ] Preserve ordered missed-workout carry-forward by moving later sessions onto the next selected weekday slots.
- [ ] Run schedule tests.

### Task 4: Room persistence and migration

**Files:**
- Modify: `app/src/main/java/com/example/myapplication/data/local/GoalEntity.kt`
- Modify: `app/src/main/java/com/example/myapplication/data/local/GymDatabase.kt`
- Modify: `app/src/main/java/com/example/myapplication/data/RoomWorkoutRepository.kt`
- Create: `app/schemas/com.example.myapplication.data.local.GymDatabase/3.json`
- Modify: `app/src/androidTest/java/com/example/myapplication/data/GymDatabaseMigrationTest.kt`

- [ ] Add failing migration assertions for `trainingDaysMask` and `sessionDurationMinutes` while preserving goals and workout history.
- [ ] Add Room migration 2→3 with evenly spaced weekday masks derived from existing `sessionsPerWeek` and legacy duration 45.
- [ ] Map the new columns to and from `GoalConfig`.
- [ ] Adapt the selected base program before persisting sessions and schedule due dates on selected weekdays.
- [ ] Compile Android migration tests and run them when a device is available.

### Task 5: Clear onboarding flow

**Files:**
- Modify: `app/src/main/java/com/example/myapplication/feature/onboarding/OnboardingUiState.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/onboarding/OnboardingViewModel.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/onboarding/OnboardingScreen.kt`
- Modify: `app/src/test/java/com/example/myapplication/feature/onboarding/OnboardingViewModelTest.kt`
- Modify: `app/src/androidTest/java/com/example/myapplication/feature/onboarding/OnboardingScreenTest.kt`

- [ ] Add failing ViewModel tests for selecting one to six weekdays, rejecting a seventh, selecting duration, back navigation, and creating a matched adaptive plan.
- [ ] Replace the fixed commitment step with `TRAINING_DAYS` and `SESSION_DURATION` steps.
- [ ] Add `Bước N/7`, explanatory choice copy, weekday chips, duration cards, prior-selection summary, and review details.
- [ ] Keep create disabled until every required choice is valid.
- [ ] Explain unsupported goal/level/equipment combinations without silently substituting another configuration.
- [ ] Compile Compose tests and run JVM ViewModel tests.

### Task 6: Catalog and regression verification

**Files:**
- Modify tests under `app/src/test/java/com/example/myapplication/core/catalog/` only when constructor changes require it.
- Modify: `docs/data/program-review-checklist.md`

- [ ] Validate every base program has non-empty ordered workouts and enough reviewed content for deterministic adaptation.
- [ ] Run `./gradlew.bat test`.
- [ ] Run `./gradlew.bat compileDebugAndroidTestKotlin`.
- [ ] Run `./gradlew.bat assembleDebug`.
- [ ] Run `git diff --check` and confirm no generated build output, secrets, or unrelated refactors are included.
