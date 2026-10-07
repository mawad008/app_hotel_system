# Guest App (`mobile/`) — Claude guidance

Flutter Guest App. **Before starting any task in `mobile/`, read the design & phase
docs first** — they are the source of truth for what each screen/flow must do and
how it must look.

## `mobile/docs/` — SRS, engineering guides, phase specs & design system

All Guest App documentation now lives here (moved out of the repo-root
`md/mobile/`). Consult the relevant file before implementing or changing a
feature.

### Foundational / cross-cutting (read once, re-check often)

- `docs/README.md` — product scope, source-of-truth hierarchy, the
  UI → state → repository → data-source rule, backend-first rule, mobile roadmap.
- `docs/architecture.md` — API-first, feature-oriented architecture; layers,
  Laravel-mirrored enums/state machines (§6), security (§8), theming (§9).
- `docs/coding_rules.md` — coding standards: think-before-coding, no `http`/`Dio`
  in features (§6), dummy/api parity (§7), failures & localized errors (§9),
  secrets (§10).
- `docs/feature_guide.md` — the per-feature implementation checklist (Steps 1–6).
- `docs/testing_guide.md` — testing pyramid, unit/widget/integration/E2E scope.
- `docs/ci_cd_guide.md` — pipeline checks, build configuration.
- `docs/release_guide.md` — store release: toolchain, signing, production
  build commands, Play / App Store checklist, how the login session persists.
- `docs/new_app_checklist.md` — foundation / project-setup checklist.
- `docs/design-system-tokens.md` — the **canonical token library**: every
  variable value, text style, elevation, and component variant axis extracted
  verbatim from `Design/Hotel Design System.fig`. The spec.
- `docs/design-system.md` — typography, colour, spacing, shared widgets, theme
  tokens as currently **implemented** in Flutter. The Figma is the visual source
  of truth; Material is an implementation primitive only.
- `docs/srs/Hotel-Guest-App-SRS.docx` — the full software requirements spec.

### `docs/guides/` — focused decision notes

- `guides/rate_limiting.md` — behave correctly on HTTP 429 (Laravel enforces).
- `guides/sms_auto_fetch.md` — OTP auto-fetch (convenience, not a security bypass).
- `guides/maestro_e2e_testing.md` — Maestro E2E for critical guest journeys.
- `guides/chat_implementation.md` — chat is NOT an approved MVP requirement.
- `guides/device_search_indexing.md` — device search indexing is a future item.

### Phase specs

- `docs/mobile-entry-language-selection.md` — entry splash → language screen → welcome (`01 · Entry`)
- `docs/mobile-deferred-auth.md` — browse without an account; sign in at the booking "confirm" step (`09 · Authentication`)
- `docs/mobile-discover-book.md` — Home / search / hotel detail / booking summary + intermediate screens (`02 · Discover & Book`, boards 16 & 08)
- `docs/mobile-phase-5-payment.md` — deposit-hold payment flow
- `docs/mobile-phase-6-identity-verification.md` — document → selfie → result
- `docs/identity-custom-ocr-models.md` — Egypt / Saudi ID OCR routes, custom-model labeling contract, dataset + Azure deployment guide
- `docs/mobile-phase-7-checkin-digital-access.md` — check-in + room key
- `docs/mobile-phase-8-stay-services.md` — service catalogue + orders
- `docs/mobile-phase-9-checkout-invoice.md` — checkout + invoice
- `docs/mobile-phase-10-loyalty-reviews.md` — loyalty points + reviews
- `docs/mobile-phase-11-bookings-account.md` — bookings list/detail, account home, the current-stay services hub + Extend Stay (`11 · Bookings & Account`, `04 · Check in & Stay`)
- `docs/mobile-report-a-problem.md` — dedicated in-stay problem-report flow: category → urgency/notes → submitted → track (`13 · Report a problem`)
- `docs/mobile-v2-integration-pass.md` — v2 end-to-end integration pass: new guest endpoints, dashboard actions, live E2E test, open business decisions
- `docs/figma-v2-prototype-routing-map.txt` — the designer's prototype routing map (navigation spec for every screen)

When a new phase/feature is built, add its doc here and link it above.

## `mobile/Design/` — visual source of truth

- `Design/Hotel Design System.fig` — the dedicated **design-system file**: token
  collections (Primitives, Color Light/Dark, Spacing, Radius, Typography,
  Content), text styles, elevations, and ~35 components. Fully extracted into
  `docs/design-system-tokens.md` — read that rather than opening the `.fig`.
- `Design/hotel_guest_app.fig` — the screen-flow Figma file. **Primary visual
  source of truth for layouts.** Where a Material default differs visibly from the
  Figma, customise the component. Replaced with the **v2 redesign** (exported
  2026-09-23: neutral black/white palette, thmanyah sans) — v2 deltas are
  summarised at the top of `docs/design-system-tokens.md`.
- `Design/NN · <name>.png` — rendered boards (**still v1 / brown** — stale for
  colour and for the redesigned screens until re-exported), one per flow (Entry, Discover &
  Book, Pay & Verify, Check in & Stay, Depart & Invoice, Bookings & Account,
  Error & Empty States, Room selection, Authentication, Identity verification,
  Services & requests, Notifications & profile, Report a problem, Loyalty &
  completion, Search/filters/sort, Stay dates & available rooms). Open the board
  for the flow you're working on before building UI.
- `Design/assets/` — images extracted from the Figma package (`manifest.json`
  maps hashed filenames).

## Working rules

- Match the Figma board for the screen — layout, spacing, weights, the "oud"
  brown palette, Iconsax icons, Tajawal font.
- Follow the dummy/api data-source pattern already established across features.
- Keep phase docs updated when behaviour changes.
