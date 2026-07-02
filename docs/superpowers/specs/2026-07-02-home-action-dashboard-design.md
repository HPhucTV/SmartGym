# Home Action Dashboard Design

## 1. Goal

Redesign the Home screen as an action-first daily dashboard. The screen must feel spacious on portrait phones, help the user choose the next useful action, and show only values derived from real local data.

The existing dark-neon visual identity remains. This change is limited to the Home screen, its state model, navigation callbacks, and relevant tests.

## 2. Visual direction

- Keep the near-black navy background and dark navy cards.
- Use neon green for completion and genuine progress.
- Use orange for the primary daily action.
- Use blue only as a restrained supporting accent.
- Apply glow-like emphasis only through borders, progress indicators, and the primary action. Do not make every card compete for attention.
- Use full-width vertical sections instead of the current narrow two-column dashboard.

## 3. Information hierarchy

The content appears in this order:

1. A compact header with the current date and a short daily label.
2. A full-width workout hero showing the current session name, duration, exercise completion, and a Start or Continue action.
3. A compact status row summarizing real weekly completion, real streak, and today's nutrition progress.
4. Full-width action cards for Nutrition, Weekly Check-in, and Personalization recommendations.
5. Explicit empty states when a source has no data.

The workout hero is the only dominant card. Secondary actions remain visible without visually competing with it.

## 4. Data rules

- Remove all populated defaults and mock fallback chart values from `HomeUiState`.
- Do not estimate calories burned as a fixed number per completed exercise.
- Derive workout title, duration, and exercise completion from the current persisted workout.
- Derive weekly completion and streak from completed workout history.
- Derive consumed and target calories from the persisted nutrition day.
- Represent missing targets and missing records explicitly rather than substituting plausible-looking numbers.
- Keep calculations outside Composables and expose immutable display-ready state.

## 5. Interaction and navigation

- The workout hero navigates to the current workout screen.
- The Nutrition card opens Nutrition.
- The Weekly Check-in card opens Weekly Check-in.
- The Personalization card opens Recommendations.
- Every interactive surface has a clear label and at least a 48 dp touch target.
- Navigation callbacks are passed into `HomeScreen`; the screen does not own a navigation controller.

## 6. Responsive behavior

- The primary layout is a single vertically scrolling column.
- Content uses full available width with consistent horizontal padding.
- The compact status row may distribute three equal items when width permits; it must not use fixed-width dashboard columns.
- Text may wrap naturally and cards may grow vertically. Important values must not be clipped on small portrait screens.

## 7. Empty and boundary states

- No current workout: show an unavailable-session message without a fabricated duration or progress value.
- No completed sessions: weekly completion and streak both show zero with helpful labels.
- No nutrition target: show consumed calories and a prompt to complete profile/setup rather than assuming 2,000 kcal.
- Zero-exercise sessions must never divide by zero and cannot display false completion.
- Navigation actions remain available only when their destination is valid in the current app graph.

## 8. Testing

- Unit-test Home state mapping for a current workout, no workout, completed history, streak boundaries, nutrition with a target, and nutrition without a target.
- Compose-test the full-width hierarchy, primary workout action, secondary action callbacks, and empty-state copy.
- Run the smallest Home-related unit and Compose tests while iterating, then run the applicable unit suite and `assembleDebug` before completion.

## 9. Non-goals

- No light-theme redesign.
- No changes to workout generation, nutrition formulas, or personalization decisions.
- No new network calls, permissions, dependency-injection framework, or application module.
- No redesign of Today, Progress, Nutrition, Check-in, or Recommendations beyond the navigation entry points used by Home.
