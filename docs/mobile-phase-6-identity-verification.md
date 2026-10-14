# Mobile Phase 6 — Identity Verification

Guest-app identity verification flow required before check-in. It walks the
approved backend identity state machine (Document → Selfie → Matching → Result)
and represents every business state — it never invents states and never claims
approval before the repository confirms it.

## Document-only mode (2026-10-07) — current default

`IDENTITY_DOCUMENT_ONLY=true` (config `verification.document_only`, default
**true**): the guest only photographs the ID and verification completes.

- Flow: Intro → pick document type (no name / number / birth date) → photo
  (front, plus back where the type requires it) → review → upload →
  **AUTO_APPROVED** → reservation **VERIFIED** → check-in.
- Backend: no OCR call, no selfie, no face match. The photo is still stored
  encrypted on the private disk (staff can see it); `document_check_status`
  stays null; one automated decision row with `reason = document_only`.
  New state-machine edge `DOCUMENT_UPLOADED → AUTO_APPROVED`.
- `GET /guest/identity/document-types` adds `details_required` /
  `selfie_required` (both false in this mode); the app hides the details
  fields when `details_required` is false (missing → true, for older servers).
- Set `IDENTITY_DOCUMENT_ONLY=false` to restore the OCR + selfie flow below.
  PHPUnit runs with it false (phpunit.xml); `GuestIdentityDocumentOnlyTest`
  covers this mode.

## Real OCR document check (2026-09-26)

The ID-document upload now runs a **real server-side OCR check** before the
selfie step. Nothing about OCR runs in Flutter and no provider credential
exists in the app.

```
Guest → details form (type, full name, number, DOB) → capture ID → upload (progress)
  → backend: encrypt + store (private disk) → OCR provider (outside any DB txn)
  → normalize → MRZ parse/validate → compare with the typed details
  → document_check {status, reason codes, per-field outcome codes}
  → verified / needs_review → selfie → face match → AUTO_APPROVED / manual review
  → mismatch / ocr_failed / document_expired / document_unsupported → fix & retry
```

### Provider

**Azure AI Document Intelligence, `prebuilt-idDocument`, REST v4.0
`2024-11-30` (GA)** — `AzureDocumentIntelligenceProvider` behind
`IdentityDocumentProviderInterface` (next to, not replacing, the face-match
`IdentityVerificationProviderInterface`). `DummyIdentityDocumentProvider`
(synthetic ICAO "Utopia" specimen, real check digits) stays for automated
tests / local dev and is **refused in production** by the container binding.

Why Azure: worldwide passport extraction incl. the MRZ, national ID /
residence-permit models, Arabic OCR, a Delete-Analyze-Result API (provider
copy removed immediately instead of Azure's 24 h default), in-region
processing (UAE North), pay-per-page. AWS Textract AnalyzeID is US-documents
only and has no Arabic; Google's ID processors are US/limited and gated.
Dedicated IDV vendors (Regula, Uqudo, Sumsub…) have stronger GCC-ID coverage
and authenticity checks but need a contract + SDK — they fit behind the same
interface later.

### Decision (`DocumentCheckEvaluator`)

First match wins: `ocr_failed` (extraction failed / name or number
unreadable) → `document_unsupported` (driver licence, unknown) →
`document_expired` (expiry before the **check-in date**) → `mismatch`
(number, DOB or name contradicts the claim) → `needs_review` (anything
unconfirmed) → `verified`. `needs_review` opens the selfie step but the
session can then only end in `PENDING_MANUAL_REVIEW`, never `AUTO_APPROVED`.

- **Passports:** the MRZ (TD3) is parsed and every ICAO check digit verified
  (document number, DOB, expiry, optional, composite). A verified MRZ is
  authoritative for number/dates; the printed page is cross-checked
  (`mrz_visual_conflict`). Missing / invalid MRZ → review.
- **National ID / residence permit:** read and compared, TD1/TD2 MRZ
  validated when present. Without a verified MRZ they end in review unless
  `IDENTITY_DOCUMENT_AUTO_VERIFY_WITHOUT_MRZ=true` — not enabled because
  per-country extraction has not been tested (e.g. Saudi ID / Iqama).
- **Document number:** exact comparison after normalization (case, spaces,
  hyphens, `<`, Arabic-Indic digits). OCR look-alikes (O/0, I/1, S/5, B/8…)
  only downgrade a mismatch to review, never accept it.
- **Date of birth:** exact date equality. **Nationality** (optional): a
  difference is review, not rejection (dual nationals).
- **Low provider confidence** (< 0.80) on a field not proven by MRZ check
  digits → review.
- **Upload cap:** after `IDENTITY_DOCUMENT_MAX_UPLOADS_PER_ATTEMPT` (5) OCR
  runs, a failing document goes to a human instead of another paid call.
- **Duplicate upload:** identical bytes + identical details (keyed HMAC
  fingerprint) return the stored result without a second OCR call.

### Name matching (`NameMatcher`)

Normalization: NFKC, Arabic-Indic digits → ASCII; Arabic harakat/tatweel
removed, أ/إ/آ/ٱ→ا, ى→ي, ة→ه, ؤ→و, ئ→ي; Latin diacritics → ASCII; apostrophes
dropped, other punctuation / hyphens / MRZ `<` → space; `AL`/`EL`/`ال` joined
to the next token; `BIN`/`BINT`/`IBN`/`بن`/`بنت` dropped. Adjacent tokens merge
when their concatenation is a token on the other side (ABDUL RAHMAN ↔
ABDULRAHMAN). Tokens are paired (distinct) by Jaro-Winkler.

- **strong** — identical compact form, or ≥ 2 tokens, every typed token
  pairs at **≥ 0.94** and the pairs cover the first given name **and** the
  surname (middle names may be omitted).
- **strong (Egyptian national ID)** — the card's name is a lineage chain
  (own / father / grandfather / …), so ≥ 3 typed tokens that are, in order,
  the leading tokens of the printed name (the usual "triple name", last card
  token omitted) are also strong.
- **weak → review** — every typed token (≥ 2) is printed on the card but the
  anchors aren't covered (e.g. first + father name only, or out of order), or
  ≥ half of typed tokens pair at **≥ 0.88** and the surname does. A name made
  only of tokens that are on the card is never a hard mismatch.
- **mismatch** — anything else (e.g. a family / father name that isn't on the
  card).
- **Arabic vs Latin** — never transliterated/guessed: `unverifiable_script` →
  review. The form asks for the Latin spelling on passports.

The name is one of three independent fields; no decision rests on a single
fuzzy comparison.

### Stored data (minimum)

No column for any document number, name, DOB, MRZ or OCR text. The attempt
stores `document_check_status`, `document_check` (reason codes, per-field
outcome codes, name score, document kind, issuing country, MRZ validity),
`document_check_provider`, `document_fingerprint` (keyed HMAC),
`document_uploads`, `document_checked_at`, `provider_artifact_ref` (only while
a provider-side deletion is pending). The typed details live only in request
memory (`IdentityClaim`, redacted from dumps, unserializable).

### Security

- Files **encrypted at rest** (`Crypt`, APP_KEY; `*.enc`), private disk only,
  server-generated names, path guard against traversal; no read route.
- Content validation: magic bytes + full image decode (≤ 10 000 px), PDFs
  with JavaScript / launch / embedded files rejected — not just the extension.
- A rejected document is deleted immediately; the provider copy is deleted
  right after extraction (`Delete Analyze Result`), retried hourly by
  `identity:purge-ocr-artifacts` if that fails; interrupted checks (> 60 min
  `processing`) have their document deleted. No temporary OCR file is written
  (the document is sent from memory).
- Retention unchanged: images purged 30 days after the stay ends, capped at
  30 even if configured higher.
- The Azure key is only ever sent to the configured endpoint host (a foreign
  `Operation-Location` is refused), no redirects followed.
- Logs: one line per check — attempt id, provider, provider status,
  outcome status, reason codes, duration. Never a value, MRZ, text or image.
- Ownership: every guest endpoint is 404 for another guest's reservation;
  rate limit `identity-verification.submit`.

### API

`POST /guest/reservations/{id}/identity/documents` — multipart `document`
(jpg/png/pdf) + `document_type` + **`document_number`** (required),
**`date_of_birth`** (required, `Y-m-d`, Arabic-Indic digits accepted),
`full_name` (optional, defaults to the profile name), `nationality`
(optional ISO-3). Staff `POST /identity-verification/{id}/documents` accepts
the same fields optionally (missing → review). Every identity resource now
carries:

```json
"document_check": {
  "status": "mismatch", "reasons": ["claim_mismatch"],
  "fields": {"expiry": "valid", "number": "mismatch", "birth": "match", "name": "strong"},
  "document_kind": "passport", "can_continue": false,
  "requires_new_document": true, "uploads_remaining": 4, "checked_at": "…"
}
```

A selfie while the check blocks it → 422.

### Flutter

New `IdentityDetailsForm` (Intro → details → capture), `IdentityDocumentClaim`
(redacted `toString`, Western-digit ISO date on the wire), `DocumentCheck`
entity, upload progress (Dio `onSendProgress` → `uploadProgress`) then a
"Reading your ID" state once the bytes are sent, and actionable screens:
mismatch (names the fields; *Edit my details* re-uploads the kept photo),
unclear (retake), expired / unsupported (use another document), each with
*Contact reception*. The details form is not on the v2 Figma board — built
from design-system primitives.

### Environment

`IDENTITY_DOCUMENT_PROVIDER=azure_document_intelligence`,
`AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT`, `AZURE_DOCUMENT_INTELLIGENCE_KEY`,
optional `AZURE_DOCUMENT_INTELLIGENCE_API_VERSION` (2024-11-30),
`AZURE_DOCUMENT_INTELLIGENCE_TIMEOUT` (30), `IDENTITY_DOCUMENT_MIN_CONFIDENCE`
(0.80), `IDENTITY_DOCUMENT_AUTO_VERIFY_WITHOUT_MRZ` (false),
`IDENTITY_DOCUMENT_MAX_UPLOADS_PER_ATTEMPT` (5). Scheduler must run
(`identity:purge-ocr-artifacts` hourly, `identity:purge-expired-images` daily).

### Limitations

- The **face match is still the dummy provider**: a verified document plus
  any selfie can auto-approve once thresholds are set. A real face-match /
  liveness provider is required before auto-approval is enabled in production.
- No document authenticity / tamper detection (Azure reads, it doesn't
  authenticate) — MRZ check digits catch typos and naive edits only.
- Arabic-script names on a Latin-only passport always go to review.
- National IDs without an MRZ are never auto-verified by default.
- Staff cannot view the document image (no read route); manual review relies
  on the in-person check.
- The live Azure test (`AzureDocumentIntelligenceLiveTest`) needs credentials
  and a synthetic sample — not run in CI.

## Regional documents: Egypt / Saudi (2026-09-27)

Full design, model setup and dataset guide:
[`identity-custom-ocr-models.md`](identity-custom-ocr-models.md).

- **Types** (guest selects explicitly): `egyptian_national_id`,
  `saudi_national_id`, `saudi_iqama`, `passport`.
  - The legacy `national_id` / `residence_permit` / none map to `other_id`,
    the previous generic prebuilt route.
- **Routing:** `DocumentProviderRouter` sends each type to its Azure model
  (`AZURE_DI_*_MODEL`).
  - Custom models have no default. A missing one gives NEEDS_REVIEW
    (`provider_not_configured`) plus an error log.
  - There is never a dummy fallback or an automatic pass.
- **Auto-verify:** custom types have `auto_verify=false` until their model is
  evaluated, so they always end in manual review. Passports are unchanged.
- **API**
  - Upload: `front_image` (or the legacy `document`) plus `back_image`.
    - `back_image` is **required** for Egypt, **optional** for Saudi and
      **prohibited** for passports.
  - `document_type` must be one of the values above.
  - `country` is optional, ISO-3, and must match the type.
  - `document_number` is structure-checked per type (422).
  - `date_of_birth` is not required for Egypt: it is derived from the national
    number.
  - `document_check` gains `document_type` and `back_image` (bool). Staff
    responses also carry `provider`; guest responses never do.
  - New: `GET /guest/identity/document-types` returns the types, sides and
    whether the check is automatic. No provider or model is exposed.
  - New: `GET /identity-verification/document-types` (staff with
    `identity-verification.view`) returns the per-type provider, model id,
    configured flag and manual-review flag. It never includes a key.
- **Storage:** new `document_back_path` column, encrypted and purged exactly
  like the front. `provider_artifact_ref` now holds comma-joined
  `{model}/{resultId}` references.
- **Flutter**
  - Type chips (Egyptian ID / Saudi ID / Iqama / Passport) from the catalog,
    falling back to built-in defaults if it can't load.
  - Explains front-only / front+back / back optional. No DOB field for Egypt.
    Per-type number checks. Arabic name hint.
  - A back-capture step, with Skip when the back is optional.
  - "Document accepted" and "Manual review required" screens before the
    selfie.
  - A failure screen for 401/403/422/5xx: 422 goes back to the details form.
- **Dashboard:** the reservation Identity panel shows the document check:
  type, status, reasons, field results, provider and back image, plus an
  authenticity disclaimer.

## Scope

* Upload an ID document, capture a selfie, submit for the automated match.
* Represent the full Laravel `IdentityVerificationSession` status vocabulary and
  the safe subset of `IdentityVerificationResource` fields.
* Deterministic dummy behaviour alongside the real guest-facing identity API.
* A logging-safe, bytes-free abstraction for document/selfie capture.
* `IdentityVerificationEligibility` (`domain/entities/identity_verification_eligibility.dart`)
  gates the flow on the reservation's status (must be `DEPOSIT_HELD`) — the
  same defensive pattern `CheckInEligibility`/`CheckoutPage` use — so a stale
  or direct deep link before the deposit is held, or after verification is
  already done, never reaches the capture flow.

Out of scope (staff only): `POST .../review` (the manual approve/reject
decision).

## Identity state machine

`lib/features/identity_verification/domain/entities/identity_verification_status.dart`
mirrors `App\Domain\IdentityVerification\Models\IdentityVerificationSession` and
`IdentityVerificationStateMachine` **exactly**:

```
NOT_STARTED → DOCUMENT_UPLOADED → SELFIE_CAPTURED → MATCHING_IN_PROGRESS
MATCHING_IN_PROGRESS → AUTO_APPROVED | PENDING_MANUAL_REVIEW | RETRY_ALLOWED
RETRY_ALLOWED        → DOCUMENT_UPLOADED (new attempt)
PENDING_MANUAL_REVIEW→ STAFF_APPROVED | STAFF_REJECTED
STAFF_REJECTED       → DOCUMENT_UPLOADED (new attempt)
```

`AUTO_APPROVED` / `STAFF_APPROVED` are terminal. `STAFF_REJECTED` is **not**
terminal — it has a retry edge. Derived predicates on the enum:
`isApproved` (positive list: auto + staff), `isTerminal`, `needsDocument`,
`needsSelfie`, `isProcessing`, `isManualReview`, `allowsRetry`.

A **retry is not a separate call**: from `RETRY_ALLOWED` / `STAFF_REJECTED` the
guest re-enters `submitDocument` (the approved `… → DOCUMENT_UPLOADED` edges),
then `submitSelfie` again.

## UI flow

Matches the `10 · Identity verification` board's per-state screens exactly —
the page is a single [IdentityVerificationEligibility]-gated flow that renders
one of these states at a time (no separate routes per state; only the flow
page and the result page are routed):

```
Reservation Detail (must be DEPOSIT_HELD — IdentityVerificationEligibility)
      ▼
Intro ("Start verification")
      ▼
Capture document (live card-shaped viewfinder) → Review document ("Continue" / "Retake")
      │  submitDocument
      ▼
Capture selfie (camera-frame placeholder, submits on capture)
      │  submitSelfie
      ▼
Uploading (transient — while the submit call is in flight; "Cancel" leaves the
           screen, the family-scoped controller keeps running)
      ▼
   resolves:
     AUTO_APPROVED / STAFF_APPROVED  → hand off to Result screen (verified,
                                        CTA: "Digital check-in")
     PENDING_MANUAL_REVIEW           → hand off to Result screen (waiting)
     RETRY_ALLOWED (latestOutcome
       == documentUnclear)           → "Photo isn't clear" screen
                                        (Retry / Contact reception)
     RETRY_ALLOWED (latestOutcome
       == faceNotMatched)            → "Couldn't match your face" screen
                                        (Retry / Request manual review)
     STAFF_REJECTED (canRetry)       → Rejected screen (Retry / Contact reception)
     STAFF_REJECTED (!canRetry)      → Rejected screen (Contact reception only)
     network/timeout Failure while
       submitting                    → "Couldn't upload" screen (Retry upload /
                                        Continue later)
      ▼
"Contact reception" (reachable from any failure screen's secondary action) —
      "Back to reservation" / "View verification status" (returns to the flow)
      ▼
Verification Result (IdentityVerificationResultPage)
      │  "Digital check-in" (approved) / retry / check again / "Back to reservation"
      ▼
Reservation Detail
```

Routes (auth-guarded): `/reservation/:reservationId/identity`,
`/reservation/:reservationId/identity/result`.

Widgets: `IdentityCaptureFrame` (the camera-viewfinder shell shared by the
document and selfie capture screens), `IdentityInfoScreen` (the shared
title-bar + tinted-banner + CTA shell used by every static state screen —
Intro, Uploading, Processing, Rejected, the Failed_* screens and Contact
Reception), `VerificationResultView`, `IdentityStatusPill`.

## State management

* `identityVerificationControllerProvider` — a **`NotifierProvider.family`
  keyed by reservation id**, so a session for reservation A can never be
  overwritten by a late result addressed to reservation B (structural
  isolation).
* State (`IdentityVerificationState`): `phase` ∈
  `loading / ready / submittingDocument / submittingSelfie / failed`, plus the
  authoritative `IdentityVerificationSession` and an optional `Failure`.
* Within one reservation: a monotonic `_token` drops stale results from a
  superseded action; `state.isBusy` blocks duplicate submits.
* `refresh()` re-reads status (used while awaiting a manual review, or to
  recover a load failure).
* The controller never transitions the session — it only reflects what the
  repository returns.

### Idempotency

`SubmitSelfieRequest.idempotencyKey` = `idv-selfie:<reservationId>` (stable,
no time/random) — the `Idempotency-Key` header for the future API. The dummy
source relies on the **state-machine guard** (a selfie only resolves from
`DOCUMENT_UPLOADED` / `SELFIE_CAPTURED`) plus the controller's `isBusy` guard,
so a repeat submit from a resolved state is a no-op and never runs a second
match or bumps the attempt count.

## Data layer

```
IdentityVerificationRepository
 └── IdentityVerificationDataSource
       ├── DummyIdentityVerificationDataSource   (DummyDataSource)
       └── ApiIdentityVerificationDataSource     (RemoteDataSource — stubbed)
```

* `IdentityVerificationSessionModel.fromJson` mirrors
  `IdentityVerificationResource` — **only** `reservation_id`, `status`,
  `attempts`, `latest_outcome` (coarsened to `IdentityMatchOutcome`),
  `decided_at`. `latest_score`, `provider`, storage paths, attempt metadata and
  the `latest_decision` internals are **not** mapped onto the entity.
* `IdentityMatchOutcome.fromWire` parses the backend's verbatim provider-match
  vocabulary (`high_match` / `medium_match` / `low_match` / `error` — see
  `App\Domain\IdentityVerification\Provider\MatchOutcome`): `error` →
  [documentUnclear] (the provider couldn't read the document at all),
  `low_match` → [faceNotMatched] (read fine, selfie didn't match closely
  enough), `high_match`/`medium_match` → [match].
* `IdentityDocumentPayload.toFields` mirrors the `document_type` field of
  `SubmitIdentityDocumentRequest` (`max:40`, `/^[A-Za-z0-9 _-]+$/`).
* `IdentityVerificationRepositoryImpl` maps every data-layer error to `Failure`.

### Document / selfie capture abstraction

`CapturedImage` (`identity_document.dart`) carries a non-sensitive `label`,
`sizeBytes` and `mimeType`, plus the capture's content reference — never
printed (`toString()` is metadata only):

* **iOS / Android** — `filePath` only. `DeviceIdentityCamera`
  (`data/device/live_identity_camera.dart`, `camera` package) shows the live
  feed **inside the capture frame** — a landscape frame in the ID-1 card
  ratio (85.6 × 54 mm) with corner guides for the front / back, the portrait
  face oval for the selfie — with capture tips under it (whole card inside,
  good light without glare, hold steady). The rear lens is used for the
  document, the front for the selfie; front and back share one camera session
  and it is released on review / in the background. If the live camera can't
  open (not a denial) the shutter falls back to `image_picker`'s system camera
  (`ImagePickerIdentityCamera`, **camera only, no gallery**); a denied
  permission shows `IDENTITY_CameraDenied`. The photo is the full sensor frame
  (not cropped to the guide). It stays in an on-device temp file; no bytes are
  held in domain/state, and the upload streams it with `MultipartFile.fromFile`.
* **Staying in the booking flow (QA 2026-10-08).** The system camera is a
  separate Android activity, and Android may kill the app's process behind
  it. The app then cold-starts and used to land on home, so the guest left the
  booking after payment. Two guards:
  * While the live viewfinder is mounted but still (re)opening, for example
    after the permission prompt or a trip to the background, the shutter
    **waits**. It no longer hands off to the system camera; that fallback is
    only for a live camera that failed to open.
  * Around every system-camera capture, `PendingIdentityCapture`
    (reservation, target, front/back, document type; no image or ID data) is
    saved in `AppPreferences`. On a cold start the router sends an
    authenticated guest from the splash to that reservation's identity step,
    not home. The page clears the marker and recovers the photo with
    `ImagePicker.retrieveLostData` (`IdentityCamera.recoverLostCapture`), then
    continues to review (document) or submits it (selfie). A lost back-side
    shot restarts at the front, because the front was only in memory.
* **Web** — `bytes` only. Browsers have no reliable camera source (desktop
  Chrome opens a file chooser either way) and no file system, so the guest
  **picks an image file** (`ImageSource.gallery`), which is read with
  `XFile.readAsBytes()` into `CapturedImage.bytes`, previewed with
  `Image.memory`, and uploaded with `MultipartFile.fromBytes`.

`CapturedImage.hasContent` is true when either is set; `CapturedImage.dummy`
has neither. The API contract (multipart field names, headers) is identical
on every platform.

### API contract status — **integrated for status; submit needs a real capture**

`ApiIdentityVerificationDataSource` is real:

* `GET /guest/reservations/{reservation}/identity` (`fetchStatus`) — fully wired.
* `POST .../identity/documents` and `.../identity/selfie` — wired to the real
  guest-authenticated endpoints (`GuestIdentityVerificationController`, reusing
  `IdentityVerificationService`/`IdentityVerificationResource` unchanged from
  the staff surface at `POST /identity-verification/{reservation}/...`), but
  throw `NotImplementedInPhaseException` when a `CapturedImage` has no content
  (neither `filePath` nor web `bytes` — i.e. the dummy placeholder).
* `.../review` (manual approve/reject) has no guest equivalent by design —
  staff-only, and already implemented on the dashboard
  (`app/components/workspace/IdentityPanel.vue`).

## Dummy datasource behaviour

Deterministic scenario chosen from the reservation id
(`DummyIdentityVerificationDataSource.scenarioFor`):

| `scenarioFor(id) % 5` | scenario                   | attempt 1 selfie                       | attempt 2 selfie          |
|-----------------------|-----------------------------|-----------------------------------------|---------------------------|
| 0                     | `autoApprove`               | `AUTO_APPROVED`                         | —                         |
| 1                     | `manualReview`              | `PENDING_MANUAL_REVIEW`                 | `PENDING_MANUAL_REVIEW`   |
| 2                     | `retryThenApprove`          | `RETRY_ALLOWED` (`faceNotMatched`)      | `AUTO_APPROVED`           |
| 3                     | `retryUnclearThenApprove`   | `RETRY_ALLOWED` (`documentUnclear`)     | `AUTO_APPROVED`           |
| 4                     | `rejectThenReview`          | `STAFF_REJECTED`                        | `PENDING_MANUAL_REVIEW`   |

The session walks the full state machine
(`NOT_STARTED → DOCUMENT_UPLOADED → SELFIE_CAPTURED → …`). No `Random`, no
`DateTime.now()` for branching (`clock` injected for `decided_at` only).
`failWith` is a test seam for infrastructure errors.

## Security

* No image bytes in logs, and none in domain/state on iOS/Android
  (`CapturedImage.filePath` only). The web keeps the picked image as
  `CapturedImage.bytes` for the current flow only — never persisted or printed.
* No `latest_score`, provider name, storage path or attempt metadata on the
  entity (`identity_models_test.dart` asserts they don't appear in
  `toString()`).
* `NotImplementedInPhaseException` messages carry no sensitive data.
* Guest-facing errors go through `Failure.localizedMessage` — no provider or
  backend detail rendered. Rejection copy points the guest to the front desk,
  never to a reason string.

## Tests

`test/features/identity_verification/` — domain (status mapping, session
getters, request invariants, `CapturedImage` safety), models, dummy + API
datasources (all four scenarios, state-machine walk, no-op on repeat,
`failWith`), repository mapping, controller (load, document, selfie, approved,
manual review, retry, rejected, duplicate action, cross-reservation isolation,
failure + recovery), routing (registration + auth guard), and a widget flow
(document → selfie → processing → verified → reservation; manual review;
retry + recovery; rejection; Arabic RTL).

## Known limitations

* On the web the shutter opens a file chooser (no live viewfinder), so a guest
  can upload any image file; the "camera only" rule holds on mobile only.
* The live photo is not cropped to the card guide — the OCR reads the full
  frame.
* On the web, go_router's imperative `pushNamed` doesn't update the URL, so a
  browser refresh mid-flow lands back on the last declarative route.
* Manual-review resolution (`STAFF_APPROVED` / `STAFF_REJECTED` from
  `PENDING_MANUAL_REVIEW`) is staff-driven from the dashboard's Identity
  workspace panel; the app only re-polls via "Check again".
* "Request manual review" (from the face-not-matched failure screen) and
  "Contact reception" both route to the same in-app Contact Reception screen —
  there is no dedicated "force manual review" backend action, so both are
  framed as "ask the front desk," which already can resolve either case.
* The reservation stays at whatever status the backend/dummy source reports;
  the app reflects verification status independently and never changes the
  reservation status itself.
