# Online integrations and release hardening

- Status: Current
- Effective date: 2026-08-04
- Applies to: `flutter/`, `server/`, Android release configuration and CI

## Runtime boundaries

SmartGym remains single-user and local-first. Workout plans, completion,
profile, weight, nutrition history and user-confirmed barcode corrections are
stored on the device. The Node service provides optional online capabilities;
it is not an account, sync or shared user-data service.

| Capability | Current endpoint | Persistence |
|---|---|---|
| Known food capabilities | `GET /api/food-analyses/foods` | Reviewed server data, read-only |
| Photo analysis start | `POST /api/food-analyses` | In-memory session, 15-minute expiry |
| Photo analysis second image | `POST /api/food-analyses/:id/images` | In-memory session |
| Photo confirmation | `POST /api/food-analyses/:id/confirmations` | Client saves confirmed result locally |
| Barcode lookup | `GET /api/barcodes/:barcode` | Bundled catalog or Open Food Facts, read-only |
| Daily coach review | `POST /api/coach/review` | No server-side user-data persistence |
| Adaptation explanation | `POST /api/coach/decision-explanations` | No server-side user-data persistence |

The removed legacy routes are `POST /api/analyze-food`,
`GET /api/scan-barcode`, `POST /api/register-barcode`,
`POST /api/coach-review` and `POST /api/explain-decision`.

## Barcode ownership

Barcode values must contain 8-14 digits. Lookup checks a local Drift v4
override first, then calls the read-only backend. Editing or confirming a
product writes `barcode_overrides` on that device only. Remote catalog results
are not silently persisted and always require confirmation before logging.

This prevents an unauthenticated client from changing nutrition data seen by
other users while preserving offline reuse of the owner's correction.

## Server hardening

- Helmet supplies baseline security headers and Express does not advertise
  `X-Powered-By`.
- CORS accepts requests without a browser Origin (mobile/native clients) and
  exact values listed in comma-separated `ALLOWED_ORIGINS`.
- `TRUST_PROXY_HOPS` is explicit; use `1` behind one trusted Render proxy and
  leave it unset for direct local execution.
- Barcode and coach input is strict, bounded and independently rate limited.
- Open Food Facts and Gemini use fixed HTTPS hosts, timeouts and disabled
  redirects. User-controlled identifiers are encoded.
- Provider errors and logs expose only bounded codes; image bytes, raw model
  output, API keys and complete health payloads are not logged.

## Android release and local data

Release builds require `flutter/android/key.properties`. Use
`key.properties.example` as a template and keep the keystore outside the
repository. Missing signing fields fail release tasks immediately; release no
longer falls back to debug signing. R8 minification and resource shrinking are
enabled for release builds.

The current Android application ID is `com.smartgym.app`. Confirm that this is
the intended, owned publishing identity before the first store release; do not
change it after publishing unless the product is intentionally becoming a
separate application.

`android:allowBackup` is disabled. Both Android backup rule formats explicitly
exclude databases, shared preferences, internal files and external app files
from cloud backup and device-to-device transfer.

CI intentionally builds only a debug APK because it has no release secrets.
A release operator must build with external signing configuration, then verify
the APK signature and certificate independently before distribution.

## Dependency and CI gates

The EOL `sqlite3_flutter_libs` package was removed; Drift uses the supported
`sqlite3` native-assets path. The unused `get_it` dependency was also removed.

GitHub Actions runs two jobs on pushes to `main` and pull requests:

1. Server: `npm ci`, `npm test`, high-severity production audit.
2. Flutter: `flutter pub get`, analyzer with warning/error enforcement, full
   tests and debug APK assembly.

Dependabot checks npm, pub and GitHub Actions weekly.

## Local verification

```powershell
cd server
npm ci
npm test
npm audit --omit=dev

cd ..\flutter
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

For a release-signing readiness check without local secrets, invoke a release
build and confirm it stops with the explicit missing `key.properties` message.
Do not describe that check as a signed release build.
