# ADR-003: Android release signing and backup policy

- Status: Accepted
- Date: 2026-08-04
- Scope: Flutter Android application and release process

## Context

The Android release build used the debug signing configuration, and an ignored
keystore was stored at the repository root. Local profile, weight and nutrition
history also had no explicit backup exclusion. These defaults are unsuitable
for a distributable app holding personal fitness data.

## Decision

1. Keystores and passwords remain external to Git. The example properties file
   documents names only and contains no usable secret.
2. Any release task fails when `key.properties` or a required signing field is
   absent. Debug signing is never used as a release fallback.
3. Release builds enable code minification and resource shrinking.
4. Android cloud backup and device-to-device transfer are disabled and all
   local storage domains are explicitly excluded in both backup-rule formats.
5. CI verifies debug assembly only. A release is valid only after an operator
   builds with external secrets and independently verifies the APK signature,
   certificate and checksum.

## Consequences

- A developer without release credentials can still build and test debug APKs.
- Release configuration errors fail early and cannot create a deceptively
  release-named APK signed by the debug identity.
- Device migration does not automatically transfer SmartGym health/history
  data; a future export/import feature must be explicit and user-controlled.
