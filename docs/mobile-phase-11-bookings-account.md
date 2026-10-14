# Mobile Phase 11 — Bookings, Account & Services

Builds the three bottom-nav tabs that were placeholders through Phase 0–10
(`docs/design-system.md` §"Bottom navigation"): حجوزاتي (Bookings), حسابي
(Account), الخدمات (Services — the current-stay hub). All four tabs now route
for real; `navComingSoon` is retired.

## Figma boards

- `Bookings & Account/BOOKINGS_List_Current.png` / `BOOKINGS_List_Past.png`
- `Bookings & Account/BOOKING_Detail_{PendingPayment,VerificationRequired,ReadyToCheckIn,CurrentlyStaying,Cancelled,Completed}.png`
- `Bookings & Account/PROFILE_Home.png`
- `Check in & Stay/STAY_Home.png`, `CHECKIN_DigitalKey.png`

## Bookings (`lib/features/bookings/`)

One page, three pills (`BookingsFilter`: current/upcoming/past — a
presentation-only classification of `ReservationStatus`, `domain/bookings_filter.dart`):

- **الحالية** — "إقامة جارية" (checked_in/in_stay) + "حجوزات قادمة"
  (pending/deposit_held/verified, future).
- **القادمة** — the upcoming section alone.
- **السابقة** — swaps the header (title + back-style arrow that resets the
  filter) and lists checked_out/invoiced/cancelled grouped by year.

`ReservationRepository` gained `list()` / `cancel()` / `extend()`; the guest
API source now eager-loads (and the resource returns) `hotel.cover_url`,
`room_type.base_price` and `room.room_number` (see
`../../md/extend-stay-implementation.md` §6) — needed for the list thumbnail,
the Account loyalty card's real "per night" figure, and the room number shown
once checked in.

Detail (`reservation_detail_page.dart`, reused in place — it already served
this purpose): a `BookingSummaryCard`, a `BookingTimelineCard` (3-row stepper,
one branch per Figma state — `_Timeline` in that file), a static
`CancellationPolicyCard` (the MVP has no cancellation-fee rule, so "no fee" is
accurate, not invented), and per-status actions (`_Actions`) — continue
payment / verify identity / digital check-in / current-stay+access-code /
book-again / view invoice, plus cancel where the backend still allows it. The
completed branch also keeps the Phase 10 loyalty + review entry points
(Figma's two buttons only cover invoice/book-again; dropping loyalty/review
would have been a regression, not a redesign).

**Refresh after a change.** Every successful reservation mutation calls
`refreshGuestReservations(ref.invalidate, reservationId: …)`
(`presentation/state/bookings_providers.dart`). That covers create, cancel,
payment hold, identity approval, check-in, extend, checkout and loyalty redeem.
It invalidates `bookingsListProvider` (so STAY_Home's current stay and the
Account stats recompute), the notifications feed/bell, and that reservation's
detail. Don't rely on `autoDispose` here: a root tab page can stay mounted
under a pushed flow, and `go` back to it reuses the page, so the list would
otherwise keep the pre-action snapshot (a new booking missing from حجوزاتي
until a restart). New mutations must call it too.

## Account (`lib/features/profile/`)

`AccountSummary` (`presentation/state/account_summary.dart`) composes,
without any new backend concept:

- guest profile — `authControllerProvider`.
- loyalty + "per night" — one **anchor reservation** (most recent with a
  known nightly rate) feeds both `LoyaltyRepository.account(LoyaltyContext.forReservation(anchor))`
  and `anchor.nightlyRate`.
- "نزيل موثوق" — true iff any reservation is `verified` or a later status
  (identity-approved is a precondition of `VERIFIED`, Phase 0 §8).
- "إقامات سابقة" — count of `checked_out`/`invoiced` reservations; opens
  Bookings pre-set to "السابقة".
- "تفضيلاتي" — the most-frequent room-type name across history; display-only.
- "الخصوصية وبياناتي" / "المساعدة والدعم" — no destination screens exist in
  any supplied design; wired to the existing `navComingSoon` snackbar.

Sign-out moved here from `DiscoverPage`'s app bar (as design-system.md's own
note anticipated).

## Services / current-stay hub (`lib/features/stay_home/`)

`STAY_Home.png` is a real board, not a placeholder. `StayHomePage` shows the
guest's current stay (`checked_in`/`in_stay`; an honest empty state
otherwise), the room/hotel card, a 2×2 quick-action grid, and the live folio
outstanding total (`folioProvider`). Quick actions resolve against the
**real** hotel service catalogue (`GuestServiceCatalogController`, matched by
English-name keyword — `findServiceByKeyword`) rather than a hardcoded id:
"تنظيف الغرفة" / "الإبلاغ عن مشكلة" open the matching catalogue service;
"خدمة الغرف" opens the catalogue; "تمديد الإقامة" opens `ExtendStayPage`.

### Extend Stay (mobile side)

`ExtendStayPage` — Figma only designed the hub, not a dedicated extend-stay
board, so this follows the app's standard single-screen review-and-confirm
shape: date picker → `ReservationRepository.extend()` → the authoritative
result (new checkout date + incremental amount) or the mapped `Failure`. See
`../../md/extend-stay-implementation.md` for the backend workflow this calls
(`POST /guest/reservations/{id}/extend`).

## Digital Access

`CHECKIN_DigitalKey.png` already matched Phase 7's `DigitalAccessPage` /
`AccessCredentialCard` closely; the one real gap was the room number, which
came only from `AccessGrant.roomNumber` (dummy-only — the API source leaves
it `null`, a documented gap). It now prefers the authoritative
`Reservation.roomNumber`, falling back to the grant's own field.

## Not built

- No `StatefulShellRoute` migration — each tab stays a plain top-level
  `GoRoute` with its own `AppBottomNav`, matching the app's existing router
  shape; revisit only if tab-state preservation becomes a real requirement.

> The "الخدمات" tab's "الإبلاغ عن مشكلة" quick action originally opened the
> matching **service** ("Maintenance") rather than a dedicated flow, since only
> the `STAY_Home` board was supplied this phase. A later addendum built the
> dedicated `13 · Report a problem` flow and repointed the tile — see
> `mobile-report-a-problem.md`.
