# Adaptive Nutrition, Training, and Gym-style UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add body-profile-based nutrition targets and a hybrid personalization engine that automatically applies small reversible changes, requests confirmation for material changes, and presents everything through the approved gym-style interface.

**Architecture:** Room becomes the durable source for profile, weight, daily nutrition, check-ins, and adaptation history. A pure Kotlin rules engine produces deterministic `AUTO_APPLY` or `REQUIRES_CONFIRMATION` decisions; Gemini may explain a decision but never creates or applies one. Existing reviewed workout templates remain authoritative, and all applied changes are recorded with undo data.

**Tech Stack:** Kotlin, Jetpack Compose Material 3, Room, DataStore, Kotlin coroutines/Flow, kotlinx.serialization, OkHttp, Node.js/Express backend, JUnit, Compose UI tests.

**Design references:**
- `docs/superpowers/specs/2026-07-02-gym-style-ui-upgrade-design.md`
- `docs/design/gym-style-concept.png`
- `docs/backend-nutrition-integration.md`

---

## Guardrails fixed by this plan

- Collect age, metabolic sex, height, current weight, target weight, activity level, and desired pace with explicit consent.
- Treat calculated calories and macros as wellness estimates, not medical prescriptions.
- Automatically apply only reversible weekly nutrition changes capped at the smaller of 5 percent or 150 kcal, plus recovery recommendations that do not delete or reorder workouts.
- Require confirmation before changing the active program, sessions per week, target weight/date, exercise volume, or any calorie change outside the automatic cap.
- Never modify completed history.
- Every decision stores inputs, reason, before/after values, status, timestamp, and undo payload.
- Gemini can rewrite the explanation in Vietnamese; rule-engine output remains authoritative.
- Never send profile or health data to the backend without a separate opt-in setting.

---

### Task 0: Secure and snapshot the current expanded baseline

**Files:**
- Modify: `AGENTS.md`
- Create: `server/.gitignore`
- Create: `server/.env.example`
- Modify: `.gitignore`
- Modify: `docs/backend-nutrition-integration.md`

- [ ] **Step 1: Record the approved scope expansion and current user-owned file set**

Update `AGENTS.md` only to replace the obsolete nutrition/body-profile prohibition with the approved scope in this plan: local personal profile, nutrition management, and hybrid personalization are allowed; accounts, cloud sync, random/AI-authored workouts, and medical treatment remain out of scope. Preserve all other working agreements.

Run:
```powershell
git status --short
git diff --name-only
git ls-files --others --exclude-standard
```

Expected: nutrition/backend/UI work is visible; `server/.env`, `server/node_modules`, and `.vscode` are not staged.

- [ ] **Step 2: Add secret and generated-file exclusions**

```gitignore
# server/.gitignore
.env
node_modules/
npm-debug.log*
```

```dotenv
# server/.env.example
PORT=3000
GEMINI_API_KEY=replace_with_local_key
```

Add these root exclusions without removing existing rules:
```gitignore
.vscode/
server/.env
server/node_modules/
```

- [ ] **Step 3: Verify no secret is tracked**

Run:
```powershell
git ls-files server/.env server/node_modules .vscode
git grep -n "GEMINI_API_KEY=" -- ':!server/.env.example'
```

Expected: both commands return no secret or generated dependency paths.

- [ ] **Step 4: Commit only baseline safety files**

```powershell
git add AGENTS.md .gitignore server/.gitignore server/.env.example docs/backend-nutrition-integration.md
git commit -m "chore: secure nutrition backend baseline"
```

---

### Task 1: Define profile, nutrition-target, and adaptation contracts

**Files:**
- Create: `app/src/main/java/com/example/myapplication/core/profile/ProfileModels.kt`
- Create: `app/src/main/java/com/example/myapplication/core/profile/ProfileGoalValidator.kt`
- Create: `app/src/main/java/com/example/myapplication/core/adaptation/AdaptationModels.kt`
- Test: `app/src/test/java/com/example/myapplication/core/profile/ProfileModelsTest.kt`

- [ ] **Step 1: Write failing validation tests**

```kotlin
@Test fun `valid profile accepts all personalization inputs`() {
    val profile = PersonalProfile(
        birthDateEpochDay = LocalDate.of(1995, 6, 15).toEpochDay(),
        metabolicSex = MetabolicSex.MALE,
        heightCm = 175.0,
        currentWeightKg = 78.0,
        targetWeightKg = 72.0,
        activityLevel = ActivityLevel.MODERATE,
        goalPace = GoalPace.GRADUAL,
        personalizationConsent = true,
        cloudAiConsent = false,
    )
    assertEquals(emptyList<String>(), profile.validationIssues(LocalDate.of(2026, 7, 2)))
}

@Test fun `invalid anthropometrics are rejected`() {
    val profile = validProfile().copy(heightCm = 0.0, currentWeightKg = -1.0)
    assertTrue(profile.validationIssues(LocalDate.of(2026, 7, 2)).isNotEmpty())
}
```

- [ ] **Step 2: Run tests and confirm RED**

Run:
```powershell
.\gradlew.bat testDebugUnitTest --tests "com.example.myapplication.core.profile.*"
```

Expected: compilation fails for missing profile contracts.

- [ ] **Step 3: Implement immutable contracts**

```kotlin
enum class MetabolicSex { FEMALE, MALE }
enum class ActivityLevel(val multiplier: Double) {
    SEDENTARY(1.20), LIGHT(1.375), MODERATE(1.55), HIGH(1.725)
}
enum class GoalPace { GRADUAL, STANDARD }

data class PersonalProfile(
    val birthDateEpochDay: Long,
    val metabolicSex: MetabolicSex,
    val heightCm: Double,
    val currentWeightKg: Double,
    val targetWeightKg: Double,
    val activityLevel: ActivityLevel,
    val goalPace: GoalPace,
    val personalizationConsent: Boolean,
    val cloudAiConsent: Boolean,
)

enum class AdaptationMode { AUTO_APPLY, REQUIRES_CONFIRMATION }
enum class AdaptationStatus { PROPOSED, APPLIED, REJECTED, UNDONE }
enum class AdaptationKind { CALORIE_TARGET, MACRO_TARGET, RECOVERY_DAY, WORKOUT_VOLUME, PROGRAM_CHANGE }
```

`PersonalProfile.validationIssues(today)` accepts ages 18–100, height 100–250 cm, weights 30–350 kg, and requires personalization consent. `ProfileGoalValidator.validate(profile, fitnessGoal)` separately verifies that target-weight direction matches the selected fitness goal. Invalid values block saving and show a non-medical explanation.

- [ ] **Step 4: Run tests and commit**

```powershell
.\gradlew.bat testDebugUnitTest --tests "com.example.myapplication.core.profile.*"
git add app/src/main/java/com/example/myapplication/core app/src/test/java/com/example/myapplication/core
git commit -m "feat: define personalization contracts"
```

---

### Task 2: Persist profile, measurements, nutrition days, check-ins, and decisions

**Files:**
- Create: `app/src/main/java/com/example/myapplication/data/local/PersonalProfileEntity.kt`
- Create: `app/src/main/java/com/example/myapplication/data/local/WeightMeasurementEntity.kt`
- Create: `app/src/main/java/com/example/myapplication/data/local/DailyNutritionEntity.kt`
- Create: `app/src/main/java/com/example/myapplication/data/local/WeeklyCheckInEntity.kt`
- Create: `app/src/main/java/com/example/myapplication/data/local/AdaptationDecisionEntity.kt`
- Create: `app/src/main/java/com/example/myapplication/data/local/PersonalizationDao.kt`
- Modify: `app/src/main/java/com/example/myapplication/data/local/GymDatabase.kt`
- Modify: `app/src/main/java/com/example/myapplication/app/AppContainer.kt`
- Test: `app/src/androidTest/java/com/example/myapplication/data/PersonalizationDatabaseTest.kt`
- Test: `app/src/androidTest/java/com/example/myapplication/data/GymDatabaseMigrationTest.kt`

- [ ] **Step 1: Write failing in-memory Room tests**

```kotlin
@Test fun profile_measurements_and_decisions_survive_reopen() = runTest {
    dao.upsertProfile(profileEntity())
    dao.insertWeight(WeightMeasurementEntity(epochDay = 20636, weightKg = 78.0))
    dao.insertDecision(decisionEntity(status = "APPLIED"))
    assertEquals(78.0, dao.latestWeightNow()!!.weightKg, 0.001)
    assertEquals(1, dao.decisionHistoryNow().size)
}
```

- [ ] **Step 2: Add normalized entities and DAO**

Use a singleton profile primary key `id = 1`, unique `epochDay` for weight and daily nutrition, unique `weekStartEpochDay` for check-ins, and an auto-generated decision ID. Store decision payloads as versioned JSON strings so undo restores the exact previous target.

- [ ] **Step 3: Migrate Room version 1 to 2**

Add `MIGRATION_1_2` with five `CREATE TABLE` statements and indices. Do not destructively migrate. Export schema to `app/schemas/.../2.json` and add a migration test using the committed version-1 schema.

- [ ] **Step 4: Verify and commit**

```powershell
.\gradlew.bat testDebugUnitTest assembleDebugAndroidTest assembleDebug
.\gradlew.bat connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.myapplication.data.PersonalizationDatabaseTest
git add app/src/main app/src/androidTest app/schemas
git commit -m "feat: persist personalization history"
```

---

### Task 3: Build deterministic calorie and macro target calculation

**Files:**
- Create: `app/src/main/java/com/example/myapplication/core/nutrition/NutritionTargetCalculator.kt`
- Create: `app/src/main/java/com/example/myapplication/core/nutrition/NutritionTarget.kt`
- Test: `app/src/test/java/com/example/myapplication/core/nutrition/NutritionTargetCalculatorTest.kt`

- [ ] **Step 1: Write failing calculator tests**

```kotlin
@Test fun `male profile calculates deterministic maintenance target`() {
    val profile = PersonalProfile(
        birthDateEpochDay = LocalDate.of(1995, 6, 15).toEpochDay(),
        metabolicSex = MetabolicSex.MALE,
        heightCm = 175.0,
        currentWeightKg = 78.0,
        targetWeightKg = 72.0,
        activityLevel = ActivityLevel.MODERATE,
        goalPace = GoalPace.GRADUAL,
        personalizationConsent = true,
        cloudAiConsent = false,
    )
    val target = assertIs<CalculationResult.Target>(
        calculator.calculate(profile = profile, ageYears = 31),
    ).value
    assertEquals(1724, target.basalCalories)
    assertEquals(2672, target.maintenanceCalories)
    val macroCalories = target.proteinGrams * 4 + target.carbsGrams * 4 + target.fatGrams * 9
    assertTrue(abs(target.calories - macroCalories) <= 4)
}

@Test fun `automatic weekly adjustment is capped`() {
    assertEquals(120, calculator.capAutomaticCalorieDelta(currentCalories = 2400, requestedDelta = 400))
    assertEquals(-100, calculator.capAutomaticCalorieDelta(currentCalories = 2000, requestedDelta = -400))
}
```

- [ ] **Step 2: Implement the pure calculator**

Use the Mifflin–St Jeor equations:
```kotlin
val base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears
val bmr = if (sex == MetabolicSex.MALE) base + 5 else base - 161
val maintenance = bmr * activityLevel.multiplier
```

Start gradual loss/gain targets at 10 percent below/above maintenance. Calculate protein at 1.6 g/kg, fat at 25 percent of calories, and assign remaining calories to carbohydrates. Round displayed targets but retain raw values for audit. Automatic weekly calorie movement is capped to `min(current * 0.05, 150)`; larger movement becomes `REQUIRES_CONFIRMATION`.

```kotlin
data class NutritionTarget(
    val basalCalories: Int,
    val maintenanceCalories: Int,
    val calories: Int,
    val proteinGrams: Int,
    val carbsGrams: Int,
    val fatGrams: Int,
)

sealed interface CalculationResult {
    data class Target(val value: NutritionTarget) : CalculationResult
    data class NeedsProfessionalReview(val reason: String) : CalculationResult
}
```

- [ ] **Step 3: Add safety outcomes**

Return `CalculationResult.NeedsProfessionalReview` instead of a target when age/profile validation fails, the requested timeline implies a change faster than 0.9 kg/week, or the computed target is non-positive. Do not diagnose or prescribe treatment.

- [ ] **Step 4: Run and commit**

```powershell
.\gradlew.bat testDebugUnitTest --tests "com.example.myapplication.core.nutrition.*"
git add app/src/main/java/com/example/myapplication/core/nutrition app/src/test/java/com/example/myapplication/core/nutrition
git commit -m "feat: calculate personalized nutrition targets"
```

---

### Task 4: Replace daily-only nutrition storage with dated history

**Files:**
- Create: `app/src/main/java/com/example/myapplication/core/nutrition/NutritionDay.kt`
- Modify: `app/src/main/java/com/example/myapplication/data/NutritionRepository.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/nutrition/NutritionViewModel.kt`
- Test: `app/src/test/java/com/example/myapplication/data/NutritionRepositoryTest.kt`
- Test: `app/src/test/java/com/example/myapplication/feature/nutrition/NutritionViewModelTest.kt`

- [ ] **Step 1: Write failing date-isolation tests**

```kotlin
@Test fun `adding food changes only selected day`() = runTest {
    repository.addNutrients(
        epochDay = 20636,
        nutrients = Nutrients(calories = 500, proteinGrams = 30, carbsGrams = 60, fatGrams = 15),
        source = EntrySource.MANUAL,
    )
    assertEquals(500, repository.observeDay(20636).first().consumed.calories)
    assertEquals(0, repository.observeDay(20637).first().consumed.calories)
}
```

- [ ] **Step 2: Deepen the repository contract**

```kotlin
data class Nutrients(
    val calories: Int,
    val proteinGrams: Int,
    val carbsGrams: Int,
    val fatGrams: Int,
)

enum class EntrySource { MANUAL, CAMERA_ANALYSIS }

data class NutritionDay(
    val epochDay: Long,
    val consumed: Nutrients,
    val target: NutritionTarget?,
)

interface NutritionRepository {
    fun observeDay(epochDay: Long): Flow<NutritionDay>
    fun observeRange(startEpochDay: Long, endEpochDay: Long): Flow<List<NutritionDay>>
    suspend fun addNutrients(epochDay: Long, nutrients: Nutrients, source: EntrySource)
    suspend fun setTarget(epochDay: Long, target: NutritionTarget)
}
```

Keep one migration reader for existing DataStore totals: on first launch after Room v2, copy them into today’s row, set `nutrition_room_migrated = true`, and leave unrelated settings keys untouched.

- [ ] **Step 3: Move network code behind an interface**

Create `FoodAnalysisClient` and `OkHttpFoodAnalysisClient`; inject it into `NutritionViewModel`. Cancellation is rethrown, HTTP errors remain recoverable, and tests use a hand fake rather than live network.

- [ ] **Step 4: Verify and commit**

```powershell
.\gradlew.bat testDebugUnitTest --tests "*Nutrition*"
git add app/src/main/java/com/example/myapplication/data app/src/main/java/com/example/myapplication/feature/nutrition app/src/test
git commit -m "feat: store dated nutrition history"
```

---

### Task 5: Add profile setup and weekly check-in flows

**Files:**
- Create: `app/src/main/java/com/example/myapplication/feature/profile/ProfileUiState.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/profile/ProfileViewModel.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/profile/ProfileScreen.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/checkin/WeeklyCheckInScreen.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/checkin/WeeklyCheckInViewModel.kt`
- Modify: `app/src/main/java/com/example/myapplication/app/GymApp.kt`
- Test: `app/src/test/java/com/example/myapplication/feature/profile/ProfileViewModelTest.kt`
- Test: `app/src/androidTest/java/com/example/myapplication/feature/profile/ProfileScreenTest.kt`

- [ ] **Step 1: Test one-decision profile validation**

Cover every required field, decimal input using Vietnamese locale, consent unchecked, invalid ranges, successful persistence, and editing without losing weight history.

- [ ] **Step 2: Implement profile screens in the approved gym style**

Use bold navy section headers, white cards, orange primary actions, explicit units, and no gradients. Sensitive fields include an explanation and remain local unless cloud consent is enabled.

- [ ] **Step 3: Implement weekly check-in**

Collect current weight, energy (1–5), hunger (1–5), recovery (1–5), sleep quality (1–5), and an optional note. A check-in can trigger evaluation but cannot directly mutate the workout program.

- [ ] **Step 4: Verify and commit**

```powershell
.\gradlew.bat testDebugUnitTest --tests "*Profile*" --tests "*CheckIn*"
.\gradlew.bat assembleDebugAndroidTest assembleDebug
git add app/src/main app/src/test app/src/androidTest
git commit -m "feat: add profile and weekly check-ins"
```

---

### Task 6: Implement the hybrid adaptation rules engine

**Files:**
- Create: `app/src/main/java/com/example/myapplication/core/adaptation/AdaptationEngine.kt`
- Create: `app/src/main/java/com/example/myapplication/core/adaptation/WeeklySnapshot.kt`
- Test: `app/src/test/java/com/example/myapplication/core/adaptation/AdaptationEngineTest.kt`

- [ ] **Step 1: Write a decision table as failing tests**

```kotlin
@Test fun `small nutrition correction auto applies`() {
    val decision = engine.evaluate(snapshot(needsCalorieDelta = -100)).single()
    assertEquals(AdaptationMode.AUTO_APPLY, decision.mode)
}

@Test fun `program and volume changes always require confirmation`() {
    assertTrue(engine.evaluate(snapshot(missedSessions = 2)).all {
        it.kind !in setOf(AdaptationKind.PROGRAM_CHANGE, AdaptationKind.WORKOUT_VOLUME) ||
            it.mode == AdaptationMode.REQUIRES_CONFIRMATION
    })
}
```

- [ ] **Step 2: Implement deterministic rules**

Evaluate only after at least seven days of data and one check-in. Auto-apply a capped nutrition correction when adherence is at least 70 percent and the two most recent weights are valid. Generate a recovery suggestion after repeated low recovery, but never mark or skip a workout automatically. Program, weekly frequency, target weight/date, and volume decisions always require confirmation.

- [ ] **Step 3: Add conflict and cooldown rules**

Emit at most one calorie decision per seven days and one workout decision per program week. If data is missing or contradictory, emit no mutation and explain which input is required.

- [ ] **Step 4: Verify and commit**

```powershell
.\gradlew.bat testDebugUnitTest --tests "com.example.myapplication.core.adaptation.*"
git add app/src/main/java/com/example/myapplication/core/adaptation app/src/test/java/com/example/myapplication/core/adaptation
git commit -m "feat: add hybrid adaptation rules"
```

---

### Task 7: Apply, confirm, reject, and undo decisions atomically

**Files:**
- Create: `app/src/main/java/com/example/myapplication/data/AdaptationRepository.kt`
- Create: `app/src/main/java/com/example/myapplication/data/RoomAdaptationRepository.kt`
- Modify: `app/src/main/java/com/example/myapplication/data/local/PersonalizationDao.kt`
- Test: `app/src/androidTest/java/com/example/myapplication/data/RoomAdaptationRepositoryTest.kt`

- [ ] **Step 1: Write transactional tests**

Test auto application, confirmation-required no-op, accept, reject, double accept idempotency, undo, undo after a newer conflicting decision, and preservation of completed workouts.

- [ ] **Step 2: Implement atomic application**

Within `RoomDatabase.withTransaction`, validate current state, write before/after payloads, update the nutrition target or pending workout modifier, and mark the decision `APPLIED`. Reject stale decisions whose expected before-value no longer matches.

- [ ] **Step 3: Implement undo**

Undo only the latest non-conflicting applied decision. Write a new audit transition rather than deleting history. Program replacement continues to use the existing confirmed `createGoal` workflow.

- [ ] **Step 4: Verify and commit**

```powershell
.\gradlew.bat connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.myapplication.data.RoomAdaptationRepositoryTest
git add app/src/main app/src/androidTest
git commit -m "feat: apply and undo personalization decisions"
```

---

### Task 8: Add the recommendation center and decision explanations

**Files:**
- Create: `app/src/main/java/com/example/myapplication/feature/recommendations/RecommendationUiState.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/recommendations/RecommendationViewModel.kt`
- Create: `app/src/main/java/com/example/myapplication/feature/recommendations/RecommendationScreen.kt`
- Create: `app/src/main/java/com/example/myapplication/data/CoachExplanationClient.kt`
- Modify: `server/server.js`
- Test: `app/src/test/java/com/example/myapplication/feature/recommendations/RecommendationViewModelTest.kt`

- [ ] **Step 1: Test pending, applied, undo, and offline states**

The screen must show why a decision exists, its exact before/after values, whether it was automatic, and its current undo eligibility. Offline mode uses the deterministic local explanation.

- [ ] **Step 2: Implement optional AI explanation**

Send only a decision summary when `cloudAiConsent` is true. The backend response can replace explanatory prose but cannot change `kind`, `mode`, before/after payloads, or status. Validate response length and fall back locally on timeout or malformed JSON.

- [ ] **Step 3: Implement gym-style decision cards**

Use navy structure, orange confirmation, green applied state plus check icon, and a visible undo action. Avoid dark-only screens and gradients.

- [ ] **Step 4: Verify and commit**

```powershell
.\gradlew.bat testDebugUnitTest --tests "*Recommendation*"
node --check server/server.js
git add app/src/main server/server.js app/src/test
git commit -m "feat: add personalization recommendation center"
```

---

### Task 9: Apply the approved gym-style system across feature surfaces

**Files:**
- Create: `app/src/main/java/com/example/myapplication/ui/components/GymHeroCard.kt`
- Create: `app/src/main/java/com/example/myapplication/ui/components/GymMetric.kt`
- Create: `app/src/main/java/com/example/myapplication/ui/components/GymSectionHeader.kt`
- Modify: `app/src/main/java/com/example/myapplication/ui/theme/Color.kt`
- Modify: `app/src/main/java/com/example/myapplication/ui/theme/Theme.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/today/TodayScreen.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/progress/ProgressScreen.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/nutrition/NutritionScreen.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/catalog/ExerciseCatalogScreen.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/onboarding/OnboardingScreen.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/settings/SettingsScreen.kt`
- Test: `app/src/androidTest/java/com/example/myapplication/GymStyleAccessibilityTest.kt`

- [ ] **Step 1: Lock visual semantics before refactoring**

Test 48 dp touch targets, selected/checked semantics, disabled primary actions, content descriptions, and small-screen scrolling. Do not assert pixel-perfect layout in Compose semantics tests.

- [ ] **Step 2: Create components only after two real usages**

Extract the hero, metric, and section header from Today and Progress first. Keep feature-specific nutrition, AI Coach, and exercise content in their feature packages.

- [ ] **Step 3: Migrate screens in order**

Migrate Today, Progress, Nutrition, Catalog, Onboarding, then Settings. After each screen run its focused unit and Compose tests. Preserve current ViewModels and user-authored behavior.

- [ ] **Step 4: Verify the visual constraints**

```powershell
rg -n "Brush\.|gradient|dynamicLightColorScheme|dynamicDarkColorScheme" app/src/main
.\gradlew.bat lintDebug assembleDebugAndroidTest assembleDebug
```

Expected: no gradients or dynamic colors; white remains dominant; navy/orange/green match the approved spec.

- [ ] **Step 5: Commit**

```powershell
git add app/src/main/java/com/example/myapplication/ui app/src/main/java/com/example/myapplication/feature app/src/androidTest
git commit -m "feat: apply gym-style personalized experience"
```

---

### Task 10: Verify privacy, safety, offline behavior, and the complete journey

**Files:**
- Create: `app/src/androidTest/java/com/example/myapplication/AdaptiveJourneyEndToEndTest.kt`
- Create: `docs/verification/adaptive-personalization-checklist.md`
- Modify: `docs/backend-nutrition-integration.md`

- [ ] **Step 1: Write the end-to-end test**

Cover profile setup, initial nutrition target, food entry, workout completion, weekly check-in, one automatic capped nutrition adjustment, one confirmation-required workout proposal, accept/reject, undo, process relaunch, and preserved history.

- [ ] **Step 2: Test offline and consent boundaries**

With the backend stopped, profile, targets, check-ins, rules, application, undo, and workout completion must work. With cloud consent disabled, assert that no explanation HTTP request is made. Camera food analysis may report a recoverable offline error.

- [ ] **Step 3: Run the complete gate**

```powershell
.\gradlew.bat testDebugUnitTest
.\gradlew.bat connectedDebugAndroidTest
.\gradlew.bat lintDebug
.\gradlew.bat assembleDebugAndroidTest
.\gradlew.bat assembleDebug
node --check server/server.js
```

Expected: all commands succeed, no tests are skipped, and `app/build/outputs/apk/debug/app-debug.apk` exists.

- [ ] **Step 4: Complete the manual matrix**

Record small/large portrait, landscape, accessibility font scaling, Android 13+ camera/notification accepted and denied, offline/online AI, metric/imperial-like decimal input handling, undo visibility, and secret-free source control. Mark unexecuted rows `NOT RUN`; never infer manual pass from compiled tests.

- [ ] **Step 5: Commit**

```powershell
git add app/src/androidTest docs/verification docs/backend-nutrition-integration.md
git commit -m "test: verify adaptive nutrition journey"
git status --short
```

Expected: only intentionally uncommitted user work remains; no secret or generated server dependency is staged.

---

## Recommended execution order

1. Secure and snapshot the current expanded baseline.
2. Ship profile and persistence without changing workout behavior.
3. Ship deterministic nutrition targets and dated history.
4. Ship check-ins and the rules engine in recommendation-only mode.
5. Enable auto-apply only after audit and undo tests pass.
6. Add optional AI explanations after local decisions are stable.
7. Apply the gym-style migration one screen at a time.
8. Run the full privacy, offline, connected, and manual release gates.
