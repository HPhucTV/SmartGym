# Home Action Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the cramped mock-data Home dashboard with a spacious dark-neon action dashboard backed only by persisted workout and nutrition data.

**Architecture:** Keep Home as a screen-level ViewModel plus stateless Compose screen. Add a pure mapper for date, workout, history, and nutrition inputs so business calculations are unit-testable; pass destination callbacks from the existing navigation host.

**Tech Stack:** Kotlin, coroutines/StateFlow, Jetpack Compose Material 3, Navigation Compose, JUnit, kotlinx-coroutines-test, Android Compose UI tests.

---

### Task 1: Real Home state mapping

**Files:**
- Create: `app/src/test/java/com/example/myapplication/feature/home/HomeStateMapperTest.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/home/HomeViewModel.kt`

- [ ] **Step 1: Write failing mapper tests**

Cover a current session, no session, current-week completion count, consecutive daily streak ending today or yesterday, nutrition with a target, and nutrition without a target. Assert nullable workout fields and nullable calorie target instead of populated fallback values.

- [ ] **Step 2: Run the focused tests and verify failure**

Run: `./gradlew.bat testDebugUnitTest --tests "com.example.myapplication.feature.home.HomeStateMapperTest"`

Expected: FAIL because `mapHomeUiState` and the revised state fields do not exist.

- [ ] **Step 3: Implement the immutable state and pure mapper**

Use these state boundaries:

```kotlin
data class HomeUiState(
    val epochDay: Long,
    val workoutTitle: String?,
    val workoutFocus: String?,
    val durationMinutes: Int?,
    val completedExercises: Int,
    val totalExercises: Int,
    val completedThisWeek: Int,
    val streakDays: Int,
    val caloriesConsumed: Int,
    val caloriesTarget: Int?,
)

internal fun mapHomeUiState(
    epochDay: Long,
    workout: WorkoutSession?,
    completed: List<CompletedWorkout>,
    nutrition: NutritionDay,
): HomeUiState
```

Count only completions between Monday and Sunday for `completedThisWeek`. Compute a daily streak from distinct completion dates, beginning today when completed or yesterday otherwise. Never fabricate workout, calorie, or history values.

- [ ] **Step 4: Wire the ViewModel combine to the mapper**

Replace the existing inline mock calculations with `mapHomeUiState(currentEpochDay(), currentWorkout, completedList, nutritionDay)`.

- [ ] **Step 5: Run focused tests**

Run the Task 1 command. Expected: PASS.

### Task 2: Full-width dark-neon Home UI

**Files:**
- Create: `app/src/androidTest/java/com/example/myapplication/feature/home/HomeScreenTest.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/home/HomeScreen.kt`

- [ ] **Step 1: Write failing Compose tests**

Render populated and empty `HomeUiState` instances. Assert tags `home-workout-action`, `home-nutrition-action`, `home-checkin-action`, and `home-recommendations-action`; assert click callbacks and empty-state copy `Chưa có buổi tập hiện tại`.

- [ ] **Step 2: Run the focused instrumentation test**

Run: `./gradlew.bat connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.myapplication.feature.home.HomeScreenTest`

Expected: FAIL because the new actions and tags do not exist. If no emulator is connected, record the environment limitation and continue with compilation plus unit verification.

- [ ] **Step 3: Replace the two-column screen**

Change the screen contract to:

```kotlin
fun HomeScreen(
    state: HomeUiState,
    onNavigateToWorkouts: () -> Unit,
    onNavigateToNutrition: () -> Unit,
    onNavigateToCheckIn: () -> Unit,
    onNavigateToRecommendations: () -> Unit,
    modifier: Modifier = Modifier,
)
```

Build one vertical scrolling column containing a date header, a full-width workout hero, a three-item equal-weight status row, and three full-width action cards. Keep `#070B19`, `#0F172A`, neon green, orange, and restrained blue. Remove circular calorie canvases and the weekly bar chart.

- [ ] **Step 4: Add explicit empty states and semantics**

Show zero history honestly, show consumed calories without a denominator when target is absent, and disable only the workout CTA when there is no current session. Add the required test tags and 48 dp minimum targets.

- [ ] **Step 5: Compile and run available UI verification**

Run: `./gradlew.bat assembleDebug` and, when available, the Task 2 instrumentation command. Expected: build PASS and Compose assertions PASS.

### Task 3: Navigation callbacks

**Files:**
- Modify: `app/src/main/java/com/example/myapplication/app/GymApp.kt`
- Test: `app/src/androidTest/java/com/example/myapplication/app/GymAppNavigationTest.kt`

- [ ] **Step 1: Add failing navigation assertions**

Assert that Home actions navigate to `workouts`, `nutrition`, `checkin`, and `recommendations` through the existing graph.

- [ ] **Step 2: Expand the Home content contract**

Replace the single callback with four named callbacks in `GymApp` and `ActiveGoalNavigation`, then route each callback through the existing `NavController` destinations. Do not create a second controller or new route.

- [ ] **Step 3: Pass callbacks into HomeScreen**

Update the production `homeContent` factory to supply all four callbacks to the revised screen.

- [ ] **Step 4: Run navigation tests or compile fallback**

Run the focused navigation instrumentation test when an emulator is available; always run `./gradlew.bat assembleDebug`. Expected: PASS.

### Task 4: Regression verification

**Files:**
- Modify only files required by failures caused by Tasks 1-3.

- [ ] **Step 1: Run Home unit tests**

Run: `./gradlew.bat testDebugUnitTest --tests "com.example.myapplication.feature.home.*"`

- [ ] **Step 2: Run the full unit suite**

Run: `./gradlew.bat test`

- [ ] **Step 3: Build the debug APK**

Run: `./gradlew.bat assembleDebug`

- [ ] **Step 4: Review the final diff**

Run: `git diff --check` and `git status --short`. Confirm there are no generated outputs, secrets, `local.properties`, or unrelated refactors in the change set.
