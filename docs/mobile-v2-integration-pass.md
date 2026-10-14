# Guest App ↔ Backend ↔ Dashboard integration pass (v2, 2026-09-26)

End-to-end completion pass against Figma v2 and the real API. The designer's
prototype routing map is saved next to this file
(`figma-v2-prototype-routing-map.txt`) and is the navigation spec.

## What now works end to end (verified live)

`test/_e2e/live_journey_test.dart` is the 30-step live journey (opt-in:
`LIVE_API=1`, backend on :8000, MySQL `hotel_platform`, seeded staff users,
`--dart-define=SCRATCH=<dir with id.jpg + selfie.jpg>`). It drives the app's
real API data sources and checks every milestone three ways — app, database
(`mysql`), dashboard staff API:

1–6 dashboard config (check-in time, deposit 25%, check-in mode, a
non-refundable rate, loyalty on, a 246.50 rate) → 7 app hotel shows it →
8 OTP sign-in → 9 availability at 246.50 SAR → 10–12 booking priced by the
server (493.00, SAR snapshot) → 13–15 deposit 123.25 held → confirmed
(`deposit_held`) → 16 no stay/key yet → 17 real ID + selfie files, staff
approves → 19 room assignment refused for `reservations.manage` alone, for
out-of-scope reception (404) and for the guest → 18 owner assigns (assigned-by
+ audit) → 20–22 self check-in → `in_stay` + active key → 23–25 service order,
staff confirms, app sees it → 26 checkout + invoice → 27 points credited once
on completion (replay does not double) → redemption capped at the stay and
restored on free cancellation → non-refundable booking cannot be cancelled
(policy snapshot) → 28 default delete-after-checkout, files still on disk in
the window, deleted from disk by `identity:purge-expired-images` after it →
29 notifications / favourite / history → 30 logout deletes the token row.

Teardown restores every configuration it changed and deletes the journey's
guest, reservations, dependent rows and identity files.

## Approved launch rules (2026-09-26) — where they live

| Rule | Implementation |
|---|---|
| Currency SAR, configurable, snapshotted | `PAYMENT_CURRENCY`; `reservations.currency`, `payment_transactions.currency` |
| Loyalty off at launch, all zero, configurable | `loyalty_rules` (migration), dashboard loyalty rule; app `LoyaltyProgram` |
| Points only after a completed stay, once | `AccrueLoyaltyOnStayCompletion` listener; no guest earn action |
| Redemption: stay only, capped at the stay total | only the points covering the stay are debited; `loyalty_redemption` folio credit |
| Cancellation restores points | credit voided + `reverse` ledger row |
| Free cancellation 24h after booking or until check-in; non-refundable = none | `ReservationCancellationService`, snapshot `is_refundable` / `free_cancellation_until` |
| Identity: delete after checkout by default, optional keep, 30-day hotel max | `guests.identity_retention`, `IdentityImageRetentionService` (capped at 30), daily purge |
| Payment confirms; the stay starts at check-in; hotel picks self/reception/both | `hotels.check_in_mode`, `DigitalAccessService` |
| Room assignment: dedicated permission, conflicts, audit | `reservations.assign-room`, `room_assigned_by_user_id`, `reservation.room_assigned` |
| Deposit: required on create, optional on PATCH, 0–100, no fixed % | `Store/UpdateHotelRequest`, `Hotel::depositFor()`; `hotel.deposit_amount` on the guest reservation |
| Tajawal only | `pubspec.yaml` fonts |

## Backend

| Change | Why |
|---|---|
| `price_snapshot` = `base_price × nights` at creation | was one night; folio/deposit/extend all treat it as the stay total |
| `PATCH /hotels/{id}` accepted (was PUT only) | partial dashboard/staff updates |
| Guest notification feed `GET /guest/notifications` (+ `meta.unread_count`), `PATCH …/{id}/read`, `POST …/read-all` | the app's bell + `NOTIFICATIONS_List`; recipient-scoped |
| Guest service-order cancel `POST …/service-orders/{id}/cancel` | Figma cancel flow; state machine decides, voids the folio charge |
| Favourites `GET/PUT/DELETE /guest/favorites/hotels/{hotel}` (`guest_favorite_hotels`) | persisted heart |
| Favourite rooms `GET/PUT/DELETE /guest/favorites/rooms/{roomType}` (`guest_favorite_room_types`) | persisted Room Detail heart |
| Room assignment `GET /reservations/{id}/assignable-rooms`, `POST /reservations/{id}/room` | app bookings are room-less; front desk assigns → key shows the room |
| `hotels.reception_phone` (form + guest APIs) | "تواصل مع الاستقبال" dials the hotel |
| Guest `preferences` + `data_deletion_requested_at`, `PATCH /guest/preferences`, `POST /guest/privacy/deletion-request` | `PROFILE_Preferences` / `PROFILE_Privacy`; opt-out stops email/SMS |
| FAQ on app content (`faq`) | `PROFILE_Support` FAQ, dashboard-managed |
| Lifecycle loyalty accrual listener | points earned automatically on stay completion (idempotent) |
| `identity:purge-expired-images` (daily) | the "deleted after departure" promise; no-op until retention days are set |

## Dashboard

Hotel form: deposit %, reception phone. Reservation detail: assign room.
Guest profile: preferences + deletion-request banner. Guest app page: FAQ
editor. (Existing type error in `roles/index.vue` fixed.)

## Mobile

Logout revokes the server token + confirmation screen · real camera capture
(`image_picker`, dark v2 capture screens, camera-denied state) · notifications
feature + Home bell badge · profile sub-screens (details, preferences,
privacy, support, FAQ, cancellation policy, logout) · persisted favourites ·
contact-reception screen · Figma cancel confirmation · stay hub → checkout ·
checkout eligibility mirrors the backend (`in_stay`) · room select → booking
summary (the v2 rooms list has no Continue bar; `BOOKING_GuestDetails` is
covered by the deferred sign-in/profile step) · money keeps halalas ·
v2 `InfoBanner` / list rows / bookings list / stay hub / digital key.

## Figma v2 visual pass (2026-09-26)

Rendered each required screen at 393×852 @2x (real Tajawal/Iconsax/Lucide
fonts, Arabic) and compared it with the Figma frame. Fixed: 24px page gutter
(every v2 frame), banner-shell screens (content-hugging banner, ✕ close),
`Message` glyphs (Lucide info / circle-alert), `Section Header` 20/13, footer
padding stacked on the home-indicator inset, booking-detail timeline (8px
dots, no connectors, 14/12 text, riyal amounts), data cards (thumbnail first,
`dates · nights`, price … pill), booking-summary dates/stepper/total, payment
method list card, card-details deposit + hold notice, account/extend numerals.

Deliberate differences: the shield glyph Figma leaves in every button's icon
slot (a component placeholder) is not copied; the key card keeps the PIN; the
completed-stay detail keeps its extra actions; numerals follow the approved
rule where individual frames disagree.

## Production-readiness audit fixes (2026-09-26)

Behaviour changed by the full-system audit (details and the open issue list
are in the audit report):

| Change | Where |
|---|---|
| A 401 on any authenticated call ends the session (`انتهت الجلسة`) instead of leaving every screen failing | `core/network/session_events.dart`, `SessionInterceptor`, `AuthController.build` |
| Cancelled-booking timeline no longer promises a deposit refund / zero fee on a non-refundable rate | `reservation_detail_page.dart`, `bookingDepositNotRefunded` |
| Bookings "past" year header uses Arabic-Indic digits in Arabic | `bookings_list_page.dart` |
| Backend: the room key is revoked when the stay is checked out / invoiced / cancelled, and Extend Stay moves the key's expiry to the new check-out day | `RevokeAccessWhenStayEnds`, `DigitalAccessService::syncExpiryToStay` |
| Backend: deactivating a staff user or changing their password ends their sessions; inactive users' tokens stop authenticating | `UserService::update`, Sanctum token check |
| Backend: staff login is throttled (`LOGIN_RATE_LIMIT`, 5/min per email+IP); OTP requests are capped per IP across numbers (`OTP_REQUEST_IP_RATE_LIMIT`, 20/min) | `routes/api.php`, `AppServiceProvider` |
| Backend: `OTP_FIXED_CODE` is ignored outside `local`/`testing` (a prod `.env` copied from the example can't accept `123456`) | `config/otp.php` |
| Backend: the revenue report sums collected settlement/capture transactions, not the deposit-hold amount | `EloquentPaymentRepository::sumCapturedForHotelByCurrency` |
| Phone sign-in widget tests type the Saudi domestic form `05XXXXXXXX` required since the phone-field change | `test/features/authentication/*`, `guest_browse_test.dart` |
