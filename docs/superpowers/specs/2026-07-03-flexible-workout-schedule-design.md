# Flexible Workout Schedule Design

## 1. Goal

Redesign goal creation so the user understands every choice and can choose a realistic weekly schedule. The user selects one to six training days and a session duration from 30 to 90 minutes. The app then produces a reviewed, deterministic workout schedule that matches the goal, experience level, equipment, selected days, and time budget.

The system remains offline-first. It never chooses exercises randomly and never relies on AI to create the core workout.

## 2. Onboarding flow

The revised flow contains seven steps:

1. Goal.
2. Experience level.
3. Available equipment.
4. Training days.
5. Time per session.
6. Rest-day behavior.
7. Review and create.

Every step shows `Bước N/7`, a short explanation of why the choice matters, and a compact summary of earlier selections. The primary action remains visible at the bottom while the choices scroll independently.

Choice cards include a title and concise consequence. Examples:

- `Tăng cơ` — “Ưu tiên sức mạnh và phát triển nhóm cơ.”
- `Người mới` — “Kỹ thuật cơ bản, khối lượng vừa phải.”
- `45 phút` — “Khoảng 5–7 bài, gồm bài chính và bổ trợ.”

## 3. Weekly schedule selection

The Training days step displays seven day chips from Monday through Sunday.

- The user must select at least one and at most six days.
- The selected count becomes `sessionsPerWeek`; it is not inferred from the old catalog entry.
- The UI warns when six consecutive days leave little recovery, but does not silently change the selection.
- A live weekly preview distinguishes training days and recovery days.
- Returning to an earlier step preserves valid selected days.

## 4. Session duration

The user selects exactly one reviewed duration bucket: 30, 45, 60, 75, or 90 minutes.

Each bucket shows an estimated exercise range. The estimate is informational; the actual count depends on the reviewed session blueprint and exercise prescriptions.

No arbitrary minute input is accepted. Fixed buckets keep the generated session predictable and testable.

## 5. Deterministic program model

The current one-program-per-configuration model is replaced by a reviewed adaptive preset model.

Each program remains indexed by goal, level, and equipment. It provides:

- schedule variants for one through six sessions per week;
- reviewed session blueprints referenced by stable IDs;
- ordered exercise prescriptions inside each blueprint;
- a required `CORE` or optional `ACCESSORY` role for each exercise;
- an estimated time cost for each prescription;
- the existing sets, repetitions or duration, and rest time.

Recommended weekly structures are reviewed per goal rather than generated freely. Typical structures are:

- 1 day: full body;
- 2 days: full body A/B;
- 3 days: goal-specific three-day split;
- 4 days: upper/lower or goal-specific equivalent;
- 5 days: four-day base plus one reviewed focus session;
- 6 days: two reviewed three-day cycles.

These labels describe the default structure. Individual program assets may use a different reviewed structure when the goal requires it.

## 6. Time-budget adaptation

`SessionDurationAdapter` creates the session snapshot deterministically:

1. Resolve the reviewed blueprint for the selected weekly position.
2. Include every `CORE` prescription in its defined order.
3. Include `ACCESSORY` prescriptions in defined order while the estimated total remains within the selected duration bucket.
4. Reject the program asset during validation if its core block exceeds the shortest supported duration.
5. Persist the resulting exercise list as the generated session snapshot.

The adapter does not shuffle, substitute, or invent exercises. A given program, schedule, duration, and start date always produces the same sessions.

## 7. Data model and persistence

`GoalConfig` gains:

- `trainingDays: Set<DayOfWeek>`;
- `sessionDurationMinutes: Int`.

`sessionsPerWeek` remains a derived persisted value for efficient selection and reporting, and must equal `trainingDays.size`.

The active goal entity stores the selected days as a stable bit mask and stores the duration bucket as an integer. Generated workout sessions continue storing complete exercise snapshots so later catalog edits cannot mutate an existing plan.

For existing goals, the Room migration assigns deterministic evenly spaced training days matching the stored session count and uses 45 minutes as the legacy duration. Completed history is preserved.

## 8. Schedule behavior

- Initial due dates follow the selected weekdays starting from the goal start date.
- A missed workout remains current and shifts all remaining sessions, preserving their order.
- After a missed workout is completed, future sessions move to the next selected training-day slots.
- Rest-day behavior applies only to non-training days.
- Clock and timezone changes cannot skip an ordered session.

## 9. Matching and unsupported states

Program selection first matches goal, level, and equipment, then verifies that the program contains a reviewed schedule variant for the selected day count and valid blueprints for the selected duration.

If no valid program exists, the review screen explains which dimension is unsupported and offers concrete alternatives. It never silently changes the goal, days, duration, level, or equipment.

## 10. Review screen

The final review shows:

- goal, level, and equipment;
- selected weekdays and sessions per week;
- minutes per session;
- program duration in weeks;
- expected weekly structure;
- a sample first session with exercise count and estimated time;
- rest-day behavior;
- a short “Vì sao phù hợp” explanation based only on deterministic matching rules.

## 11. Testing

Automated coverage includes:

- selecting one through six unique weekdays;
- rejecting zero or seven training days;
- accepting only 30, 45, 60, 75, and 90 minutes;
- deterministic program and blueprint selection;
- core exercises always retained;
- accessories added in order within the time budget;
- no random or AI-generated workout path;
- asset schema and cross-reference validation;
- every supported schedule variant fitting the 30-minute core budget;
- missed-workout carry-forward onto selected weekdays;
- migration of existing goals while preserving history;
- onboarding selection, back navigation, review, unsupported state, and goal creation.

## 12. Non-goals

- No free-form exercise builder.
- No random workout assembly.
- No cloud requirement or account.
- No exercise weight or repetition logging.
- No medical or rehabilitation recommendations.
- No change to completed workout history.
