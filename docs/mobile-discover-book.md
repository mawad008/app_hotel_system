# Mobile — Discover & Book (`02 · Discover & Book`)

Reproduces the `~/Documents/Discover & Book/` mockups (`HOME_Default`,
`HOME_if One hotel`, `SEARCH_Results_Default`, `HOTEL_Detail`, `BOOKING_Summary`)
plus an alignment pass on the intermediate screens against Figma boards `16`
(stay dates & available rooms) and `08` (room selection).

Design intent (caption): *"Browse the group, pick a room, review before paying.
Room locks the moment a booking starts (§9)."*

## Flow

```
/discover ──tap hotel──▶ /discover/hotel/:id ──احجز الآن──▶ /discover/hotel/:id/dates
        (Home)              (Hotel detail)                     (calendar, board 16)
                                                                     │ عرض الغرف المتاحة
                                                                     ▼
   /discover/hotel/:id/rooms ──عرض التفاصيل──▶ /discover/hotel/:id/rooms/:roomTypeId
     (available rooms, board 16)                  (room detail, board 08)
                                                        │ اختيار هذه الغرفة
                                                        ▼
                              /discover/hotel/:id/review  ──المتابعة للدفع──▶ /reservation/:id/payment
                                (BOOKING_Summary)          (guest → sign-in → back here first)
```

All of the above is browsable **without an account**; auth is requested only at
the booking-summary CTA (`docs/mobile-deferred-auth.md`).

## Screens

### Home — `discover_page.dart` + `discover_controller.dart` (v2, Phase C)

Rebuilt frame-by-frame on the v2 Figma `HOME_Default` / `HOME_if One hotel`
(2026-09-24). Data, controller and routes are unchanged.

**`HOME_Default` (hotel group)**
- White header (no Material app bar): status-bar safe area, then 8px down the
  greeting row — `أهلاً بك` (or `أهلاً {name}`) 20 Bold/32 at the start, and at
  the end two 44px `Icon Button / Surface` circles (white, 0.5px hairline, 20px
  glyph), 8px apart: **search** (opens the search screen) and **notifications**
  (Iconsax `notification_1`; still disabled — no notifications route yet). 16px
  below. Gutters 24.
- The v2 Figma leaves the 2nd circle's icon as the component's placeholder
  `Close`; it is **search** by product decision (v2 dropped Home's search field).
- No search field, no sort chips, **no guest sign-in action** (product
  decision): guests sign in at booking confirm (`mobile-deferred-auth.md`).
- `إقامتك القادمة` — signed-in guests with `DiscoverView.upcomingStay` only:
  compact `SectionHeader` (16 Medium) + `UpcomingStayCard`, laid out on the v2
  `Frame 38` stay card (radius 14, 0.5px hairline, 76×72 thumbnail radius 8,
  room 14 Medium, `hotel — city` 14 Regular `text/accent`, hairline, 35px
  `stone/600` button `عرض الحجز` → reservation detail). ⏳ `Frame 38`'s
  check-in/out date row is omitted: `UpcomingStay` has no dates (nor a photo —
  the thumbnail is the honest placeholder). `Frame 38` itself is the *current*
  stay with "تمديد الاقامة"; for an upcoming stay the button opens the booking.
- `اكتشف فنادق المجموعة` — compact `SectionHeader` (16 Medium, no "عرض الكل");
  the whole header opens search (Figma prototype link). 8px below, a vertical
  list of `HomeHotelCard`s 16px apart.
- `HomeHotelCard` (v2 `Hotel card`): full-bleed photo, radius 16, tile shadow,
  aspect 345:229; black 0→42% gradient over the bottom 130px; name 18 Medium +
  pin/city 14 Regular in white, beside a 32px white circle with a forward arrow
  (Figma Bold `Up 1` turned forward → Iconsax `arrow_left`/`arrow_right` by
  direction); a translucent rating pill (white @55%, gold score + star) pinned
  top-left in both directions. `HotelSummaryCard` is unchanged (search results).
- Responsive: cards keep the Figma aspect ratio; at ≥ 640 content width they
  pair up two per row.

**`HOME_if One hotel`** (`AppConfig.singleHotelGroup`,
`--dart-define=SINGLE_HOTEL=true`)
- Header: `أهلاً بك` 24 Bold/36 + `اكتشف {hotel}` 14 Regular (2px apart) and the
  notifications circle only; gutters 16, 20px rhythm.
- Read-only `HotelSearchField` → search; the next-stay card (18 Bold header);
  `استكشف الغرف` (18 Bold + `عرض الكل` → hotel detail), then a **horizontal
  rail** of 345-wide `RoomSummaryCard(showStayTotal: false)`, 12px apart. The v1
  hotel identity tile above the rooms is gone (not in the frame).

**Bottom tab bar** — see `design-system.md` → *Bottom navigation*.

### Search — `hotel_search_page.dart`
- App-bar title `فنادق المجموعة`; the `AppBottomNav` is shown (Home tab → `/discover`).
- Sort lives only in the chip bar (the app-bar sort sheet was removed).
- `HotelSummaryCard(row)`: name, city with a pin, "from" price, `متاحة` pill,
  image trailing. No rating pill (not in the mockup).

### Hotel detail — `hotel_detail_page.dart` (v2 `HOTEL_Detail_Premium`, Phase D)

Rebuilt on the v2 Premium frame (2026-09-24): a column of cards 24px apart on
white, 16px gutters, over a sticky bar. Shared pieces live in
`widgets/detail_premium.dart` (`DetailHeroCard`, `HotelHeroCopy`,
`DetailSectionHeading`, `DetailCard`, `DetailInfoRow`, `DetailRatingRow`,
`DetailFacilityPill`, `DetailTileGrid`, `DetailBottomBar`). Data contracts are
unchanged.

**Old implementation → Figma → now**

| Figma section | v1 page | Data | v2 page |
|---|---|---|---|
| Hero (rounded 361×371, radius 28, dark gradient, frosted back, name / location / reviews / rating, `1/N`) | full-bleed hero + thumbnail strip + name/price sheet + `RatingPill` | `galleryUrls`/`coverUrl`, name, city, `country`, `rating`, `reviewCount` | `DetailHeroCard` + `HotelHeroCopy`. Swipe + tap-to-full-screen kept; the thumbnail strip is replaced by the Figma counter. |
| Quick-info card (check-in, check-out, rooms, suitable for) | *(the "info row" existed only in tests — `hotel_detail_info_row_test` had been failing)* | `details.checkInTime` / `checkOutTime` (`check_in_time` / `check_out_time`, "HH:MM"), `details.roomsCount` (`rooms_count`, physical rooms), `details.suitableFor` (`suitable_for`) | The four Figma rows, each only when on file; times shown as `3:00 مساءً` (`formatHotelTime`). A hotel with none of them falls back to its other real facts (room types, search party, country, star classification) so the card is never empty. |
| Why choose (heading, subtitle, 6 feature cards) | description paragraph | `description`, `details.highlights` (`highlights[{icon,title,subtitle}]`) | Heading + the hotel's own description + a horizontal row of 152×136 highlight cards (`gold/25`, `#F1E7D3` hairline, white icon tile, title 14 Medium, subtitle 12, 1 line). Icons from the operator's key via `AppIcons.forDetailKey` (unknown → generic). |
| Services & facilities (2-col pills) | amenity chips | `facilities` (open catalog, backend labels and dashboard-selected icon keys) | `DetailFacilityPill` grid renders the selected facility icon key while preserving the Figma tile size and gold tint; unknown keys fall back to a neutral marker. |
| Available rooms (room card) | 3 spec chips from `entryRoom` | `entryRoom` (+ `view`, from `room_types.view_i18n`) | Room card: photo, name, "ابتداءً من" price, bed / view / area / guests chips (each only when on file), `عرض الغرف المتاحة` → stay dates (same flow as the sticky CTA). |
| Reviews (overall badge + count, rating rows) | 3 hardcoded category bars (dummy-only) | `review_summary` (live, **dynamic per-hotel categories**, including dashboard icon keys) | Overall badge + count + one `Rating Row` per rated category, any number, in the backend's order; each configured category icon is shown in the Figma gold accent, and the section stays hidden while nothing is rated. The old dummy `HotelReviewScores` (fixed cleanliness / communication / location) was removed — see `mobile-phase-10-loyalty-reviews.md` → *Dynamic review categories*. |
| — | real per-service ratings | `ServiceCatalogue` | **Removed** (2026-09-26) — the Hotel Detail page no longer shows a "Hotel services" section; services stay in the in-stay services flow. |
| Location (mini-map + distances) | — | `details.location` (`location{note, latitude, longitude, nearby_places[{icon,name,travel_minutes}]}`) | Heading + the note; a card with the mini-map **only when the hotel has coordinates** — a live `flutter_map` OpenStreetMap view (same tiles as the dashboard's Leaflet picker) centred on the dashboard-set coordinates with the Figma's white pin; non-interactive in the card, tap opens `HotelMapPage` (full-screen, pan/zoom) — and the nearby places (`mist` 42px rows, "مطار جدة 25 دقيقة"). Section hidden when nothing is on file. ⏳ "open in Maps" (external app) — needs `url_launcher`; production traffic should move off the public OSM tile servers (usage policy). |
| Sticky bar ("ابتداءً من" + price / night, `احجز الآن`) | full-width CTA | `nightlyRateFrom`, `isAvailable` | `DetailBottomBar`; CTA disabled when unavailable; same booking reset + route. |

All of the Hotel Detail content above is **operator-managed** from the
dashboard hotel form (section "Guest app — hotel detail": check-in/out,
suitable for, highlights, location note, coordinates, nearby places) and the
room-type form (bed type, view, area, breakfast, refundable). Nothing is
seeded or faked — a hotel shows these rows once staff fill them in.

Hero controls (Figma `hero-actions`, 32px frosted circles): back (Lucide
`arrow-right`, RTL) at the start; share (Lucide `share-2`) and favourite
(Hicon `Heart 3`, `red/600`, filled when on) at the end. Share opens the
platform share sheet (`share_plus`; Web Share API on web) with name, location
and a map link, falling back to the clipboard + a snackbar. Favourites are
session-only (`favoriteHotelsProvider`) — the backend has no guest wishlist
endpoint yet.

Icons: the section glyphs are Lucide at weight 300 in `gold/400`
(`AppIcons.forDetailKey` / `forFacility`; facilities without an operator icon
fall back to the Figma glyph for their catalog key).
`HeroPhotoStrip`, `PropertyChip` and `RatingPill` were only used here and in
room detail, and were removed.

### Booking summary — `room_selection_review_page.dart` (`تفاصيل الحجز`)
- Room card (thumb, name, `📍 hotel`, nightly price, `متاحة`).
- Dates card + `تعديل` → the calendar.
- **Inline** `بالغون` / `أطفال` steppers bound to `guestPartyControllerProvider`,
  capped at the chosen room type's `max_occupancy`
  (`RoomSelection.maxAdultsWith` / `maxChildrenWith`). At the cap the + stays
  dimmed-but-tappable and shows `الحد الأقصى لهذه الغرفة هو N بالغين`
  (`roomMaxAdultsReached`) / `… N ضيوف` (`roomMaxGuestsReached`), plus a
  caption under the steppers, so the party can never outgrow the room and
  silently drop the selection.
- `PriceBreakdownCard`: `قيمة الإقامة` (nightly × nights) + `رسوم الخدمة` +
  `الإجمالي`.
- CTA (signed in) `المتابعة للدفع` → creates the `PENDING` reservation and
  `pushReplacement`s straight to `/reservation/:id/payment`.
  CTA (guest) `سجّل الدخول لتأكيد الحجز` → sign-in, then back here.

**Service fee**: the hotel's real booking service fee (`رسوم الخدمة`),
switched on/off from the dashboard hotel form — a fixed amount per booking or a
percentage of the stay (`service_fee` on the guest hotel resource →
`HotelServiceFee.feeFor`, same arithmetic as `Hotel::serviceFeeFor`). No fee →
no row. Laravel snapshots the real amount on the reservation at booking.

**Selection re-pricing**: `RoomSelectionController._revalidate` now keeps the
selection when a party change still fits the room type (updates
`selection.party` in place); it drops the selection only on a date change or a
party that no longer fits. This is what lets the inline steppers work.

### Intermediate — boards 16 & 08
- `stay_dates_page.dart`: the guest-party row was removed (party is edited on the
  rooms screen / booking summary); the scrolling `StayRangeCalendar` +
  `عرض الغرف المتاحة` CTA stay.
- `available_rooms_page.dart` — **v2 `ROOMS_Available`** (2026-09-26): app bar
  "الغرف المتاحة" with the ✕ at the end (no back arrow); one scrolling column
  (12 top / 24 sides / 32 bottom, 16 between blocks): the `stay summary` card
  (white, 20 radius, 0.5px `stone/200` outline, 14 between rows — hotel 18
  Bold + "تعديل التواريخ"; arrival / departure as `٦ سبتمبر` 18 Bold under 13
  Medium labels; "ليلتان · ٢ ضيوف (بالغان)" + "تعديل"), the `filter & sort`
  pills (40 tall, white, soft shadow, 14 Medium, no icons, filter first), the
  `rooms label` ("الغرف المتاحة" 18 Bold + "٨ غرف متاحة"), then the room
  cards. The filter sheet applies cancellation, breakfast and Wi-Fi filters to
  the returned room list; the list keeps the API's availability and prices
  intact.
- `room_summary_card.dart` — Figma `Available Room Card`: 20 radius, two-layer
  shadow, 16 padding, 12 between rows; 88×88 photo (radius 20) + name 15.5
  Bold / description ≤ 2 lines / capacity · bed / amenities (13 Regular);
  "متاحة" + "إلغاء مجاني" 20px badges with the filled shield-tick; hairline;
  nightly price (17 Bold + drawn riyal mark, "/ الليلة" below), the component's
  `price total` slot (14 Medium + riyal mark, "الإجمالي لليلتين"), and the
  40px outlined "عرض التفاصيل". Colours: `RoomCardPalette` — the v2 palette
  (the Figma component is still bound to the legacy teal library; see
  `design-system.md` → Palette audit), theme tokens in dark mode.
- `room_detail_page.dart` — **v2 `ROOM_Detail_Premium`**, fully
  dashboard-driven (2026-09-26): rounded hero (`DetailHeroCard`, 361×358,
  centred `1/N`, share + favourite); room-info card (name 18 Bold + nightly
  rate, the optional **room badge** `tag` — e.g. "غرفة مميزة" — and 2-up spec
  tiles guests · area / view · bed + custom specs); "تفاصيل حجزك" (guests ·
  dates · nights tiles, nightly-rate row, **"الضرائب والرسوم · شاملة"** when
  the hotel's `prices_include_taxes` is on, the hotel's real **service fee**
  ("رسوم الخدمة", amount) when it charges one, the stay total (fee included),
  and the green **"السعر النهائي"** note only when taxes are included and there
  is no fee); "السعر يشمل" (breakfast flag + the
  room's operator-written `inclusions` + free-cancellation flag, warm
  tick-circles); "مرافق الغرفة" (the room's **catalog `facilities`** — label +
  operator icon from the facility catalog, 3 per row); "عن الغرفة"; "السياسات"
  (cancellation from the server's free-cancellation hours + the hotel's
  **check-in / check-out** times, noon shown as "ظهرًا"). Cards 16px apart.
  Bottom bar: "السعر الحالي" + nights · guests + stay total over the select /
  deselect CTAs. Every section hides when it has no data — nothing is invented.
  Editors: dashboard room-type form (badge, "the rate includes", facilities) and
  hotel form ("Price display" + "Service fee": on/off, fixed per booking or %
  of the stay). The fee is snapshotted on the reservation
  (`service_fee_amount`), billed as its own `service_fee` folio line at
  checkout, shown on the booking summary and included in the booking cards'
  total (`Reservation.totalToPay`). Tests: `room_detail_page_test.dart`,
  backend `RoomDetailContentTest`.

## Data additions

- `Hotel.details` (`HotelGuestDetails`: check-in/out, suitable for, rooms
  count, highlights, `HotelLocation` with nearby places — API only, parsed by
  `HotelModel.parseGuestDetails`; empty in dummy mode), `RoomTypeSummary.view`
  (`LocalizedText?`).
- `RoomTypeSummary.areaSqm` (`int?`), `Hotel.reviewSummary`
  (`HotelReviewSummary?` — live, dynamic categories; replaced the dummy-only
  `HotelReviewScores`), `Hotel.entryRoom` (`RoomTypeSummary?`),
  `UpcomingStay` entity.
- `DiscoveryRepository.groupHotelCount()` / `hotelRooms(id)` / `upcomingStay()`
  (dummy implemented; `ApiDiscoveryDataSource` stubs them like the rest).
- `AppConfig.singleHotelGroup` (`SINGLE_HOTEL` define).
- `RoomSelection.copyWith({party})` + `RoomSelection.fits(party)`.

## Tests

`test/features/discovery/`: `discover_home_test.dart` (upcoming-stay visibility,
single-hotel variant), `booking_summary_test.dart` (price breakdown, inline
stepper keeps a fitting selection), `hotel_detail_review_summary_test.dart`
(one row per dynamic category for 2 / 5 / 8 categories, unrated hidden,
section hidden with no summary/ratings, `review_summary` parsing),
plus the updated `discovery_pages_test`, `discovery_selection_test`,
`discovery_rtl_test`, `guest_browse_test`.
`test/features/reservation/`: `reservation_flow_test` / `_rtl` / `_theme` now
assert the booking-summary → payment path.
