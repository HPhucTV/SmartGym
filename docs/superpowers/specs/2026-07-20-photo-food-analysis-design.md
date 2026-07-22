# Photo-Based Food Analysis Design

## Status

Accepted by the user on 2026-07-20.

## Context

The current nutrition flow favors barcode scanning. Barcodes work only for packaged products and depend on external product records being complete and correct. They do not help with ordinary meals such as rice plates, restaurant dishes, or home-cooked food.

The replacement must support both:

- a photograph of a prepared meal; and
- a photograph of product packaging or a nutrition label.

A single meal photograph cannot reveal exact weight, hidden oil, sauces, or ingredients. The feature must therefore present an honest estimate, ask for confirmation in familiar household units, and never treat model output as measured truth.

The implementation target is the existing Flutter client under `flutter/`, using Riverpod for state and Drift for local persistence, plus the existing Node.js/Express backend under `server/`.

## Goals

- Replace barcode scanning in the primary nutrition UI with photo capture.
- Automatically distinguish prepared meals from nutrition labels.
- Ask for a second image only when the first image is insufficient.
- Let users confirm portions using bowls, pieces, spoons, and small/medium/large sizes.
- Return calorie and macro ranges rather than false precision.
- Use deterministic calculations and curated nutrition data for the final estimate.
- Save nutrition only after explicit user confirmation.
- Preserve consent-gated cloud AI behavior and provide a manual fallback.
- Make accuracy measurable with a reproducible evaluation set.

## Non-Goals

- Estimating medically precise nutrition from an image.
- Training a custom food-vision model in this release.
- Using depth sensors, AR volume measurement, or specialized hardware.
- Storing meal photos in Drift or maintaining cloud photo history.
- Adding accounts, cloud sync, or community-contributed food data.
- Generating workout programs or medical advice from food images.
- Deleting the legacy barcode backend endpoints in the same release.

## Decision

Use a hybrid analysis pipeline:

1. AI or OCR identifies the image type and extracts structured observations.
2. The user confirms uncertain ingredients and portions.
3. A deterministic estimator matches confirmed components to curated nutrition data.
4. The estimator calculates minimum, midpoint, and maximum nutrition values.
5. The midpoint contributes to daily totals; the full range and confidence are retained for audit and later review.

AI is an observation source, not the final nutrition calculator.

## Alternatives Considered

### AI-only calculation

The backend sends the image to a multimodal model and accepts the returned calories and macros.

- Advantages: smallest implementation and shortest interaction.
- Rejected because: repeated analyses can vary, portion estimates are opaque, and precise-looking numbers can be fabricated.

### Hybrid recognition and deterministic calculation

AI identifies components and approximate portions; OCR reads labels; the user confirms; deterministic code calculates nutrition.

- Advantages: explainable, testable, correctable, and compatible with both meals and labels.
- Selected because: it provides the best accuracy-to-complexity trade-off for the current app.

### Specialized segmentation and depth estimation

Use custom segmentation, reference objects, depth data, or a trained Vietnamese-food model.

- Advantages: higher theoretical portion accuracy.
- Rejected because: it requires a large labeled dataset, device-specific work, model operations, and more complexity than this release justifies.

## User Experience

### Entry

The nutrition screen exposes one primary action: **Chụp món ăn**. Barcode scanning is removed from the primary UI.

Photo analysis remains unavailable until the user enables cloud AI consent. Manual nutrition entry continues to work without consent or network access.

### First image

The camera guides the user to keep the whole plate or label inside the frame. Before upload, the app checks for:

- excessive blur;
- insufficient light;
- major occlusion; and
- an image that is too small for useful analysis.

An invalid image is rejected locally with a recapture instruction.

### Image classification

The backend returns one of:

- `MEAL`;
- `NUTRITION_LABEL`; or
- `UNKNOWN`.

The response status is one of:

- `NEEDS_SECOND_IMAGE`;
- `NEEDS_CONFIRMATION`;
- `READY`; or
- `UNRECOGNIZED`.

`NEEDS_CONFIRMATION` means the observations are ready for the user to review. `READY` is returned only after the confirmation endpoint has produced a deterministic estimate; it does not mean the result has been saved to Drift. Initial image analysis therefore returns `NEEDS_SECOND_IMAGE`, `NEEDS_CONFIRMATION`, or `UNRECOGNIZED`.

### Conditional second image

A second image is requested only when:

- a major meal component has confidence below `0.60`;
- the first view cannot establish portion depth or separation;
- a label omits or obscures a required field; or
- the system cannot distinguish per-100-gram values from per-serving values.

For meals, the second image should be taken from a side angle. For labels, it should be a closer, front-facing image of the relevant text.

### Meal confirmation

The user reviews every identified component and can add, remove, or rename items. Portions use familiar choices instead of mandatory grams:

- rice: half, one, or one-and-a-half bowls;
- meat or fish: piece count plus small/medium/large;
- vegetables, soup, and sauce: little/medium/much;
- generic ingredients: small/medium/large serving.

Gram entry remains available as an advanced optional override.

### Label confirmation

The review shows:

- calories, protein, carbohydrates, and fat read from the label;
- whether values apply per 100 grams or per serving;
- serving size and serving count when present;
- net weight when present; and
- the deterministic calculation used for the consumed amount.

Missing required information must be confirmed or entered before an estimate is produced.

### Result and save

The final review shows:

- calorie range and midpoint;
- protein, carbohydrate, and fat ranges;
- confidence as high, medium, or low;
- uncertainty reasons such as hidden oil or sauce; and
- a concise calculation explanation.

The user must confirm before any nutrition data is written. The midpoint contributes to daily totals. The minimum, maximum, confidence, source, and calculation summary remain attached to the logged item.

## Flutter Components

### `FoodCaptureScreen`

Owns preview and capture through Flutter's official camera plugin, framing instructions, local quality checks, metadata-stripping re-encoding, and recapture actions. It does not call repositories or calculate nutrition.

### `FoodPhotoNotifier`

Uses Riverpod and exposes immutable screen state:

- `Idle`;
- `Capturing`;
- `Uploading`;
- `NeedsSecondPhoto`;
- `ReviewingMeal`;
- `ReviewingLabel`;
- `Saving`; and
- `Error`.

It coordinates the client and repository, but delegates nutrition calculations to the backend estimator contract.

### `FoodAnalysisClient`

Provides focused operations for:

- starting an analysis with the primary image;
- adding a requested secondary image; and
- submitting the user's confirmation.

Network, multipart, and response-parsing details stay behind this interface so notifier tests can use a hand-written fake.

## Backend Components

### `FoodAnalysisService`

Classifies the image, invokes the configured multimodal/OCR providers, validates provider output, and returns the discriminated analysis state.

### `NutritionEstimator`

Matches confirmed components to curated nutrition records and calculates min/mid/max values. It also performs deterministic label arithmetic. It never accepts model-supplied final totals without recalculation.

### Boundary schemas

Request data, uploaded files, confirmation payloads, and every third-party response are validated once at the system boundary. Internal code consumes only validated types.

## API Contract

### `POST /api/food-analyses`

Multipart request:

- `primaryImage`: required image;
- `secondaryImage`: optional and normally absent.

Response:

- `analysisId`: unguessable identifier;
- `imageType`;
- `status`;
- `components` for a meal or `labelFacts` for a label;
- `confidence`;
- `uncertaintyReasons`; and
- `expiresAt`.

### `POST /api/food-analyses/{analysisId}/images`

Adds the secondary image to an unexpired analysis whose current status is `NEEDS_SECOND_IMAGE`. It returns the same response shape as the initial analysis.

### `POST /api/food-analyses/{analysisId}/confirmations`

Accepts the user's confirmed component list and portions, or corrected label values. It returns:

- min/mid/max calories;
- min/mid/max protein, carbohydrate, and fat;
- confidence level;
- uncertainty reasons; and
- calculation summary.

### Error contract

All API errors use one shape:

```json
{
  "error": {
    "code": "IMAGE_TOO_BLURRY",
    "message": "Ảnh bị mờ. Vui lòng chụp lại.",
    "details": {}
  }
}
```

Stable error codes include:

- `INVALID_IMAGE`;
- `IMAGE_TOO_BLURRY`;
- `IMAGE_TOO_LARGE`;
- `UNSUPPORTED_IMAGE_TYPE`;
- `INVALID_CONFIRMATION`;
- `ANALYSIS_EXPIRED`;
- `ANALYSIS_UNAVAILABLE`;
- `INVALID_PROVIDER_RESPONSE`; and
- `DATABASE_NO_MATCH`.

`NEEDS_SECOND_IMAGE` is an analysis state, not an error.

## Confidence and Range Rules

- If a major meal component has confidence below `0.60`, request a second image.
- After the second image, confidence below `0.55` prevents an automatic nutrition estimate. The user must complete the missing portions manually.
- A label cannot become `READY` while per-100-gram versus per-serving basis remains ambiguous.
- Hidden oil, sauce, overlapping foods, or weak database matches widen the output range.
- Results outside configured physiological plausibility bounds are rejected rather than displayed.
- The product safety envelope for one confirmed photo result is `5,000 kcal`
  and `500 g` for each macro range value. It is applied after deterministic
  portion arithmetic and before a result can become `READY` or be persisted.
  These limits are feature-level rejection guards against amplified but
  schema-valid inputs; they are not nutrition targets or medical advice.
- All macro-derived calorie checks are performed deterministically.
- No result is saved automatically, regardless of confidence.

## Persistence

Write to Drift only after final confirmation. A camera-derived logged food stores:

- midpoint calories and macros for existing daily totals;
- minimum and maximum calories and macros;
- confidence level;
- source `CAMERA_ANALYSIS`;
- image type; and
- calculation summary.

Raw photos, base64 data, provider prompts, and provider responses are not persisted in Drift.

The schema migration must preserve all existing logged nutrition history.

## Failure Handling

- Blur, darkness, or framing failure: reject locally and request recapture.
- Network timeout: keep the image only in memory while the screen remains alive and offer retry.
- App process termination: discard the pending image and analysis.
- Backend or provider unavailable: offer retry and manual entry.
- Database match missing: ask the user to choose a close known food or enter nutrition manually.
- Expired analysis: require a new analysis instead of accepting stale confirmation.
- Cancellation: stop the active request, discard transient images, and write nothing.

## Privacy and Security

- Require explicit cloud AI consent before upload.
- Remove EXIF metadata, including location, before upload.
- Normalize supported input to JPEG, PNG, or WebP.
- Enforce a `5 MB` maximum and verify file signatures rather than trusting extensions or MIME headers.
- Use HTTPS for production transport.
- Keep provider API keys only in backend environment variables.
- Apply bounded upload and analysis rate limits.
- Treat model output as untrusted and validate it against strict schemas and numeric bounds.
- Never log images, base64 payloads, API keys, complete request bodies, or nutrition history.
- Keep structured analysis sessions for at most 15 minutes.
- Hold uploaded image bytes in memory only for the active request and release them after processing.
- Do not claim control over provider-side retention. Production configuration and consent text must accurately reflect the selected AI provider's current data-handling policy.

## Compatibility and Migration

- Add the new endpoints instead of changing the existing `/api/analyze-food` response contract.
- Remove barcode scanning from the primary Flutter UI when the new flow ships.
- Keep `/api/analyze-food`, `/api/scan-barcode`, and `/api/register-barcode` temporarily so existing builds are not broken.
- Do not extend the old barcode cache for new photo analyses.
- Delete legacy barcode client and backend code only in a later, separately verified cleanup after every supported client uses the new contract.

## Testing

### Unit tests

- deterministic label calculations for per-100-gram and per-serving data;
- serving count and net-weight conversions;
- nutrition range and midpoint calculations;
- confidence thresholds and second-image decisions;
- implausible-value rejection;
- third-party response schema validation;
- confirmation validation; and
- persistence mapping for midpoint, range, confidence, and source.

### Notifier and widget tests

- camera consent and permission behavior;
- first image to second-image request;
- first image directly to confirmation;
- meal component editing;
- label correction;
- retry after timeout;
- manual fallback;
- cancellation; and
- confirmation-to-save without duplicate writes.

Camera and network dependencies use fakes in Dart tests. Real camera capture is verified separately on a physical Android device.

### Backend integration tests

- multipart type, signature, and size enforcement;
- consistent error bodies;
- expired or invalid analysis IDs;
- second-image state validation;
- rate limiting;
- provider timeout and malformed output;
- deterministic result after confirmation; and
- proof that uploaded image bytes are not written to disk.

### End-to-end tests

- clear meal image, one-photo path;
- ambiguous meal image, two-photo path;
- clear nutrition label;
- ambiguous serving basis requiring confirmation;
- offline/manual fallback; and
- confirmed result persisted in history.

## Accuracy Evaluation

Maintain a private or properly licensed evaluation set that is not populated from user uploads:

- at least 30 common Vietnamese meals with known ingredients and weights;
- at least 20 nutrition labels photographed under varied lighting and angles; and
- documented provenance and usage rights for every evaluation image.

The following are release targets, not claims about current performance:

- at least `90%` correct identification of major meal components;
- after user confirmation, median absolute calorie error no greater than `20%`;
- at least `90%` of confirmed meal estimates within `35%` calorie error;
- at least `95%` complete extraction of required fields from clear nutrition-label images; and
- zero automatic nutrition saves without user confirmation.

If these targets are not met, the feature remains labeled as experimental and cannot replace manual entry as the recommended fallback.

## Observability

Answer these operational questions without collecting food or user content:

- What fraction of analyses require a second image?
- What fraction fail, and by which bounded error code?
- How often do users correct components or portions?
- How wide are the returned calorie ranges?
- What are p50 and p95 end-to-end analysis latencies?

Use structured events with correlation IDs and bounded fields such as image type, status, confidence bucket, error code, second-image flag, and duration bucket. Do not include user IDs, dish names, image content, nutrition history, raw URLs, or free-form model output in metric labels or logs.

## Acceptance Criteria

- Barcode scanning is no longer the primary nutrition action.
- A user can photograph either a prepared meal or a nutrition label.
- The system requests a second image only under the documented uncertainty rules.
- Users can correct components and portions without knowing grams.
- The final response presents min/mid/max values and uncertainty reasons.
- Only confirmed midpoint values affect daily nutrition totals.
- The full range, confidence, source, and calculation summary are persisted.
- Photo analysis fails safely to recapture, retry, or manual entry.
- The Flutter client and Gym App backend do not retain images or image metadata after processing; provider-side handling is disclosed separately in consent text.
- Automated tests cover contracts, calculations, state transitions, persistence, failures, and privacy boundaries.
- Accuracy is evaluated against the documented release targets before the feature is treated as stable.

## Official References

- [Gemini image understanding](https://ai.google.dev/gemini-api/docs/image-understanding)
- [Flutter camera plugin](https://pub.dev/packages/camera)
- [Dart image library](https://pub.dev/packages/image)
- [Drift reactive persistence](https://pub.dev/packages/drift)
