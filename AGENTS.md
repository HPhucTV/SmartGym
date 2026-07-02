# Gym App Working Agreement

## Product scope

Build a single-user Android workout companion that works fully offline. The user creates one active goal, receives a preset daily workout, ticks each exercise, completes the session, and reviews progress.

The expanded release may add a local personal profile and body-weight history, nutrition tracking, hybrid personalization, and optional consent-gated AI explanations. Core workout planning and local rules must continue working fully offline. Do not add accounts, cloud sync, random or AI-generated workouts, medical treatment, or exercise weight/repetition logging.

## Current stack

- Kotlin
- Jetpack Compose with Material 3
- Single Android application module (`app`)
- Minimum SDK 24; target SDK 36
- Room for goals, generated sessions, exercise completion, and history
- DataStore for small preferences such as reminder time and rest-day behavior
- Bundled JSON assets for exercises and preset programs

Keep the application offline-first. Do not add network permissions or runtime API dependencies without explicit approval.

## Architecture

Use small, feature-oriented units with clear responsibilities:

- onboarding and goal creation
- program catalog and selection
- today's workout and completion
- progress calculations and history
- settings and goal replacement
- local persistence and bundled asset loading

Compose screens consume immutable UI state from screen-level ViewModels. Business rules belong outside Composables. Keep program selection, schedule advancement, streak calculation, and persistence behind focused interfaces so they can be unit tested without Android UI.

Do not introduce extra modules, dependency injection frameworks, generic base classes, or speculative abstractions unless the existing implementation clearly needs them.

## Workout data rules

- Start from the public-domain Free Exercise DB, but import only a reviewed subset of common exercises.
- Store Vietnamese display names and concise Vietnamese technique instructions.
- Every catalog exercise must have a stable ID, equipment, difficulty, movement pattern, primary muscle group, and instructions.
- Every exercise reference inside a program session must add sets, repetitions or duration, and rest time.
- Preset programs are authoritative; never assemble a daily workout randomly.
- Programs must be indexed by goal, level, available equipment, sessions per week, and duration.
- A missed workout remains the current workout and shifts the remaining schedule.
- A session completes only after every exercise is checked.
- Validate all asset references and required fields in automated tests.

## UI direction

- White (`#FFFFFF`) is the dominant background.
- Primary text: dark navy (`#14213D`).
- Completion and progress: green (`#22C55E`).
- Primary actions and today's workout accents: orange (`#F97316`).
- Supporting surfaces: light gray (`#F3F4F6`).
- Do not use gradients.
- Use moderate corner radii, thin borders, restrained shadows, strong headings, large progress values, and touch targets suitable for one-handed use.
- Keep navigation to three primary destinations: Today, Progress, and Settings.

## Behavior and safety

- If no program matches a goal configuration, ask the user to change the configuration. Never silently substitute a random plan.
- Confirm destructive goal replacement or deletion and preserve completed history.
- Persist exercise checks and session completion atomically.
- Base program advancement on ordered sessions so clock or timezone changes do not lose workouts.
- Present the app as a general fitness planner, not medical advice. Do not add injury rehabilitation prescriptions.

## Testing and verification

Add tests with each behavior change. At minimum, cover:

- program selection and no-match behavior
- bundled JSON schema and cross-reference validation
- missed-workout carry-forward
- rest-day scheduling
- exercise and session completion rules
- progress percentage, calendar history, and weekly streaks
- goal replacement while preserving history
- the onboarding-to-completion Compose flow

Useful Windows commands:

```powershell
.\gradlew.bat test
.\gradlew.bat assembleDebug
.\gradlew.bat connectedAndroidTest
```

Run the smallest relevant tests while iterating, then run the full applicable suite before claiming completion.

## Change discipline

- Preserve user changes and avoid unrelated refactors.
- Keep files focused and names domain-specific.
- Update the design specification when product behavior changes.
- Record dataset provenance and license details alongside imported assets.
- Do not commit generated build output, secrets, machine-local configuration, or `local.properties`.
