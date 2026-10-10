# Mobile Phase 5 — Payment

Guest-app payment flow that follows reservation creation (Mobile Phase 4). It
requests a **refundable deposit hold** on a reservation and reflects the
authoritative backend payment lifecycle — it never collapses payment to a
boolean "paid".

## Scope

* Request a deposit hold for a `PENDING` reservation and show its outcome.
* Represent the full Laravel `Payment` status vocabulary and the safe subset of
  `PaymentResource` fields.
* Deterministic dummy behaviour alongside the real guest-facing payment API.
* A device-local payment-method choice (`PaymentMethodChoice`: Apple Pay /
  saved card / add a new card) and a display-only new-card form — neither ever
  reaches the backend; the approved hold contract carries no card data at all
  (the guest endpoint derives the deposit amount itself and needs nothing else
  from the client).

Out of scope (backend / staff / webhook driven, not a guest action): capture,
final settlement, refunds, real provider/card-vault integration.

## Payment lifecycle

`lib/features/payment/domain/entities/payment_status.dart` mirrors
`App\Domain\Payment\Models\Payment` **exactly**:

```
NOT_STARTED → HOLD_REQUESTED → HOLD_ACTIVE → CAPTURE_REQUESTED → CAPTURED
            → FINAL_SETTLEMENT_REQUESTED → SETTLED
also: HOLD_FAILED, CAPTURE_FAILED, SETTLEMENT_FAILED, CANCELLED, EXPIRED,
      REFUND_REQUESTED, REFUNDED, REFUND_FAILED
```

The app only ever drives `NOT_STARTED → HOLD_REQUESTED → HOLD_ACTIVE`
(`POST /reservations/{id}/payment/hold`). `PaymentStatus` also carries the
derived predicates the UI needs: `isSecured`, `isTerminal`, `canRequestHold`,
`isPending`, `isFailed`. Laravel stays authoritative for the status and the
amount; the app never transitions a payment or the reservation.

`PaymentOutcome` (`payment_result.dart`) is the safe classification the result
screen renders: `held / pending / failed / cancelled / expired / other`,
mirroring the branches of `PaymentController::hold`.

## UI flow

Matches the `03 · Pay & Verify` board:

```
Reservation Detail
      │  "Continue to payment"
      ▼
Payment Review   (PaymentReviewPage)   — reference, hotel, dates, amount,
      │  "Pay now"                       current payment status, hold explainer
      ▼
Payment Method   (PaymentMethodPage)   — Apple Pay / saved card •••• 4242 /
      │  "Continue"                       add a new card (device-local choice)
      ├─ Apple Pay / saved card ──────────────┐
      ▼ (new card)                            │
Payment Card Details (PaymentCardDetailsPage) │  — deposit amount, card number +
      │  "Confirm payment"                    │    cardholder name (display-only,
      ▼                                       │    never sent/stored), note
      └───────────────────────────────────────┘
      ▼
Payment Processing (PaymentProcessingPage) — clear processing state, no cancel,
      │                                       never claims success
      ▼
Payment Result   (PaymentResultPage)   — authoritative outcome + status pill;
      │  held: "Verify identity" (primary) + "Back to reservation" (secondary)
      │  failed: "Try again" (primary) + "Back to reservation" (secondary)
      ▼
Reservation Detail / Identity Verification
```

The method/card-details screens are a presentation-layer detour only — every
path (Apple Pay, saved card, or a new card) ends by submitting the exact same
`PaymentHoldRequest` the review screen always built; nothing about the hold
contract changes based on the chosen method.

Routes (`AppRoutes`, all auth-guarded, all under `/reservation/:reservationId`):
`payment`, `payment/method`, `payment/card`, `payment/processing`, `payment/result`.

Reusable widgets: `PaymentSummaryCard`, `PaymentStatusPill`.

### Cost breakdown (QA 2026-10-08)

`PaymentSummaryCard` (review + result screens) shows reference / hotel / room /
dates / status, then a **cost breakdown**, each line separate:

| Line | Source |
|---|---|
| Room rate / night | `room_type.base_price` (hidden if absent) |
| Nights | `check_in` → `check_out` |
| Stay subtotal | `price_snapshot` |
| Taxes | `hotel.prices_include_taxes`: `true` → "Included", `false` → 0, absent → hidden |
| Service fee | `service_fee_amount` (0 when none) |
| Booking total | subtotal + service fee (= the resource's `total_amount`) |
| Deposit (held now, refundable) | placed hold amount, else `hotel.deposit_amount` |

The platform has **no tax amount** — only the per-hotel "rates include taxes"
flag — so no tax figure is invented. The flag is the hotel's *current* value,
not snapshotted on the booking. Only the deposit is requested on this screen.

## State management

* `paymentControllerProvider` — a `Notifier<PaymentActionState>` (app-scoped so
  the review → processing → result pages share one action state). Sealed states:
  `PaymentActionIdle / Submitting(request) / Done(request, result) / Failed(request, failure)`.
* Guarantees: duplicate-submit is a no-op while submitting or after a
  *successful* `Done`; retry is allowed from `Failed` and from a `Done` with a
  retryable outcome; an async result is dropped if a newer `PaymentHoldRequest`
  superseded it (`_superseded`), so an old result never overwrites a newer
  payment's state.
* `currentPaymentProvider(reservationId)` — `FutureProvider.autoDispose.family`;
  returns the current `Payment`, filling a synthetic `Payment.none` with the
  authoritative reservation amount when no hold exists yet.

### Idempotency

`PaymentHoldRequest.idempotencyKey` = `pay:<reservationId>:<amount>:<currency>` —
stable across rebuilds, no time/random component. Used as the `Idempotency-Key`
header (future API) and for local dedupe. The dummy source caches only
non-failed results by key, so a genuine retry after `HOLD_FAILED` re-attempts
while a duplicate submit of a successful hold returns the same record.

## Data layer

```
PaymentRepository
 └── PaymentDataSource
       ├── DummyPaymentDataSource   (DummyDataSource)
       └── ApiPaymentDataSource     (RemoteDataSource — stubbed)
```

* `PaymentModel.fromJson` mirrors `PaymentResource` (`id`, `reservation_id`,
  `hotel_id`, `status`, `amount` decimal-string, `currency`, `hold_expires_at`,
  timestamps). `PaymentHoldPayload.toJson` mirrors `StorePaymentHoldRequest`
  (`amount`, `currency` — never the idempotency key).
* `PaymentRepositoryImpl` maps every data-layer error to `Failure` via
  `ErrorMapper`.

### API contract status — **integrated**

`ApiPaymentDataSource` is real and fully wired, no stub left:

* `GET /guest/reservations/{reservation}/payment` (`GuestPaymentController::show`,
  `GuestPaymentResource`) — returns the current payment, or `{data: null}` when
  none exists yet.
* `POST /guest/reservations/{reservation}/payment/hold`
  (`GuestPaymentController::hold`) — the guest supplies **no amount**; the
  backend derives the deposit from `config('guest_booking.deposit')` (a
  percentage of the reservation's price snapshot) and refuses with a 422
  (`deposit_amount_rule_undefined`) only if that config is ever unset. A
  separate staff/dashboard-scoped endpoint
  (`POST /api/v1/reservations/{reservation}/payment/hold`, `PaymentPolicy`)
  takes an explicit `amount`/`currency` for staff-initiated holds.
* There is still **no approved mechanism** for real card/provider capture —
  the payment-method and card-details screens are local-only UI; a real
  provider integration would go through the provider's own SDK/redirect, never
  an API body field.

## Dummy datasource behaviour

Deterministic scenario chosen from the reservation id
(`DummyPaymentDataSource.scenarioFor`):

| `scenarioFor(id) % 3` | scenario            | first hold      | retry           |
|-----------------------|---------------------|-----------------|-----------------|
| 0                     | `failsThenSucceeds` | `HOLD_FAILED`   | `HOLD_ACTIVE`   |
| 1                     | `staysPending`      | `HOLD_REQUESTED`| `HOLD_REQUESTED`|
| 2                     | `succeeds`          | `HOLD_ACTIVE`   | —               |

No `Random`, no `DateTime.now()` for branching (a `clock` is injected for
`created_at` only). `failWith` is a test seam for infrastructure errors.

## Security

* `PaymentHoldRequest` / `Payment` carry **only** reservation id, amount,
  currency, status, timestamps. No card number, CVV, PIN, provider secret or
  raw credential exists anywhere in the feature.
* `NotImplementedInPhaseException` messages contain no sensitive data.
* Failures shown to the guest go through `Failure.localizedMessage` — no
  provider or backend implementation detail is ever rendered.

## Tests

`test/features/payment/` — domain, models, dummy + API datasources, repository
mapping, controller (idle/loading/success/failure/retry/duplicate/stable
key/stale/supersession), routing (registration + auth guard), and a widget flow
(review → pay → processing → result → reservation; pending; failure + retry;
Arabic RTL; double-tap safety).

## Known limitations

* No real payment provider / card vault — Apple Pay and the "saved card" are
  both device-local placeholders, and the new-card form never sends or stores
  what it collects.
* The reservation status is whatever the backend/dummy source reports; the
  app reflects payment status independently and never changes reservation
  status itself.
