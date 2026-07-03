# Home Light Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle Home from dark neon to the approved white, navy, orange, and green gym design system without changing behavior.

**Architecture:** Preserve `HomeUiState`, navigation callbacks, content hierarchy, and test tags. Centralize the Home palette in immutable color constants, then verify rendered root and hero colors through Compose semantics.

**Tech Stack:** Kotlin, Jetpack Compose Material 3, Android Compose UI tests, Gradle.

---

### Task 1: Lock the light palette with a failing test

**Files:**
- Modify: `app/src/androidTest/java/com/example/myapplication/feature/home/HomeScreenTest.kt`
- Modify: `app/src/main/java/com/example/myapplication/feature/home/HomeScreen.kt`

- [ ] Add `home-root` and `home-workout-hero` assertions to the Compose test and assert that both nodes exist while legacy dark palette constants are absent from source.
- [ ] Run `./gradlew.bat compileDebugAndroidTestKotlin`; expect failure because the new semantic tags do not exist.
- [ ] Change Home to `#FFFFFF`, `#14213D`, `#F97316`, `#22C55E`, `#F3F4F6`, `#E5E7EB`, and `#64748B`.
- [ ] Keep the workout hero navy, make all other surfaces white/light gray, and preserve existing callbacks and copy.
- [ ] Run `./gradlew.bat compileDebugAndroidTestKotlin`; expect success.

### Task 2: Verify the app

**Files:**
- Modify only files required by failures caused by Task 1.

- [ ] Run `./gradlew.bat test` and expect `BUILD SUCCESSFUL`.
- [ ] Run `./gradlew.bat assembleDebug` and expect `BUILD SUCCESSFUL`.
- [ ] Run `rg -n "070B19|0F172A|26344D|3B82F6|Neon|DarkBg|CardBg|ElectricBlue" app/src/main/java/com/example/myapplication/feature/home/HomeScreen.kt`; expect no matches.
- [ ] Run `git diff --check` and confirm no generated files or unrelated edits were introduced by this theme change.
