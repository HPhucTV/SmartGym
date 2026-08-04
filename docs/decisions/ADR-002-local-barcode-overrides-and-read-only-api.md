# ADR-002: Local barcode overrides and read-only public API

- Status: Accepted
- Date: 2026-08-04
- Scope: Flutter nutrition persistence and Node barcode API

## Context

The legacy unauthenticated `POST /api/register-barcode` route wrote user input
into a shared JSON file. Any public client could therefore change nutrition
data returned to other users. Barcode methods also lived beside the unrelated
photo-analysis state machine, and the old lookup could fall through to an LLM
for a value that should be verified against a product label.

## Decision

1. The public barcode surface is the read-only
   `GET /api/barcodes/:barcode` route.
2. The server checks reviewed bundled records and then Open Food Facts. It does
   not use Gemini for barcode lookup and does not persist client input.
3. User-confirmed corrections are keyed by barcode in the local Drift v4
   `barcode_overrides` table.
4. Flutter resolves local override first, then the remote catalog through a
   focused `BarcodeRepository`.
5. Remote results require user confirmation. A missing product falls back to
   manual entry and becomes reusable locally after confirmation.
6. The legacy analyze/barcode/register endpoints are removed rather than kept
   as hidden compatibility writes.

## Consequences

- One device cannot poison the catalog for another user.
- Confirmed corrections remain available offline on that device.
- Corrections do not sync because the product explicitly has no accounts or
  cloud-sync boundary.
- Future reviewed shared data needs an authenticated moderation/import path,
  not a public mutation route.
