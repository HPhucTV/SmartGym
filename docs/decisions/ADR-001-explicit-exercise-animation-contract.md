# ADR-001: Explicit exercise animation contract

- Status: Accepted
- Date: 2026-08-04
- Scope: Flutter exercise catalog and local 3D renderer

## Context

The existing WebView renderer selected movement branches by testing substrings
inside an exercise ID. Unknown IDs silently received a walking animation. This
made valid exercises such as split squat and hanging knee raise enter the wrong
branch, left some exercises static, and made catalog changes impossible to
verify at the data boundary. Several catalog records also referenced missing
`3d/*.png` fallback assets through `gif3dPath`.

The current visual is a local Canvas stick figure with projected 3D joints. It
is not a GLB model and should not be described as an anatomical 3D model.

## Decision

1. `ExerciseDefinition.animationId` is the only catalog-to-renderer key.
2. The bundled catalog declares one unique animation ID for each of its 64
   exercises.
3. `exercise_animations.js` publishes `supportedAnimationIds` and
   `isSupported()`. Unknown IDs fail closed and return `null`.
4. Movement routing uses explicit sets. Specialized exercises may share useful
   primitives, but must retain distinguishable poses and props where technique
   differs.
5. Flutter shows the 3D action only when `animationId` is present. The old
   unresolved `gif3dPath` contract is removed.
6. The WebView dialog remains the replaceable UI boundary. Renderer internals
   may later move to native CustomPainter or GLB without changing workout UI
   state or catalog semantics.
7. Animation timing is elapsed-time based, scales for device pixel ratio, stops
   requesting frames while paused, honors reduced-motion preference, and
   supports rotation and zoom input.

## Consequences

- Adding or removing a bundled exercise requires updating both the catalog and
  renderer registry in the same change.
- Unsupported content is visible as an explicit fallback instead of an
  unrelated animation.
- Contract tests can catch static poses, invalid coordinates, registry drift,
  and known cross-family regressions without booting Android.
- The stick figure remains intentionally lightweight. Higher-fidelity GLB
  assets require a separate asset license, size/performance budget, and
  technique review before adoption.

## Alternatives considered

- Keep substring routing and add more exceptions: rejected because ordering
  remains fragile and unknown IDs still produce plausible but false output.
- Introduce GLB immediately: deferred because the repository has no licensed
  model set, loader, compression budget, or device performance baseline.
- Move directly to Flutter CustomPainter: viable future option, but it would
  increase migration scope without first fixing the data contract.

## Verification

- `node --test test/exercise_animations_contract_test.js` from `server/`
- `flutter test test/core/catalog/catalog_parser_test.dart`
- `flutter test test/core/catalog/catalog_validator_test.dart`
- `flutter test test/feature/today/exercise_card_3d_test.dart`
