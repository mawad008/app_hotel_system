# Mobile — Entry splash & language selection (`01 · Entry`)

The first-run entry sequence (**v2 Figma**, Phase B — 2026-09-24):

```
splash (AuthSplashPage)  →  language sheet over the splash (LanguageSelectionPage)
                         →  onboarding (EntryWelcomePage)  →  discover …
```

This follows the v2 prototype links in `Design/hotel_guest_app.fig`:
`ENTRY_Splash` opens the language `sheet` as a **centred modal overlay**
(AFTER_TIMEOUT 1.6s, default Center position, black @25% background); both language
buttons navigate to `ENTRY_Onboarding`; its CTA goes to `HOME_Default`. The v1
standalone `ENTRY_Language` screen no longer exists in the Figma.

> **Deferred auth** (`mobile-deferred-auth.md`): onboarding's CTA opens
> `/discover`, not sign-in. Browsing is public; the phone/OTP/profile surface is
> reached on demand from the "confirm" step of a booking (or the discover
> app-bar sign-in action).

## Screens

| Route | Widget | v2 frame | Notes |
|---|---|---|---|
| `/` | `AuthSplashPage` | `ENTRY_Splash` (board 14) | White field; 120px two-tone brand mark, 5px gap, `Hotel System` wordmark (`title-lg` 24/36 Bold) — centred. No tagline, no spinner. Plays a 1.4s one-shot entrance (`BrandLogo.entrance`): the mark starts at rest (matching the native launch screen), breathes 1→1.05→1, two gold ripples radiate and a sheen sweeps it, then the wordmark fades/rises in; skipped under reduce-motion, not played on the language backdrop. Held for `splashMinDurationProvider` (**1.6s** — the Figma `ENTRY_Splash` AFTER_TIMEOUT) while the stored session restores (`AuthState.unknown`). |
| `/welcome/language` | `LanguageSelectionPage` | language `sheet` (board 14) | The **same splash composition** under a black @25% scrim with the sheet centred on it as a modal (see below). |
| `/welcome` | `EntryWelcomePage` | `ENTRY_Onboarding` (board 01) | Full-bleed photo + one glass card (see below). |

Splash and language share `EntrySplashBackdrop`
(`presentation/widgets/entry_splash_backdrop.dart`), so the brand lock-up never
moves when the sheet slides in. The splash, sheet and onboarding exist only in
light in the Figma, so each subtree is pinned to `AppTheme.light` (fixed look in
dark mode too).

### Brand logo

There is **no bundled logo** (removed 2026-10-18). `BrandLogo`
(`core/widgets/brand_logo.dart`) shows the logo uploaded on the dashboard
(`/guest/app-content`); with no logo uploaded, or if it fails to load, only the
app name shows (dashboard app name, else `brandWordmark`):

* **Splash** — logo (120) + 5px + app name; no logo → the app name alone.
* **Onboarding** — logo in the white avatar ring over the glass card; no logo →
  no ring, the app name heads the card instead.

`ManagedBrandLogo` / the onboarding card draw nothing until the content is known
(`brandingKnownProvider`: fresh, cached or the settled fallback), so the name
never flips to the logo in front of the guest.

### Native launch screen (before Flutter's first frame)

A plain white field on every platform — the native launch screen can't show the
dashboard logo, so it shows none: `launch_background.xml` (Android < 12), an
empty transparent `splash_icon.xml` (Android 12+ SplashScreen API, so it doesn't
fall back to the launcher icon), and an image-less `LaunchScreen.storyboard`
(iOS). Web is blank until Flutter boots.

## Language sheet

* A **centred modal**: black @25% scrim over the splash (Figma
  `overlayBackgroundAppearance`), white card centred on it, 8px in from the
  screen edges (377 of 393) — it covers the splash lock-up, as in the
  prototype. Nothing behind it is interactive; only a language choice moves on.
* Card: radius 37, the soft `AppShadows.tile`, 16px padding; 20px rhythm between:
  header (the exact Figma `lan 1` globe-and-bubbles glyph, 33px —
  `LanguageGlyph`, decoded from the `.fig` vector network — + `اختر لغة التطبيق`,
  20 Medium / 32),
  a 0.5px `border/default` hairline, and two outlined buttons 16px apart —
  `العربية` / `English`, each named in its own script.
* **Tapping a language applies it, confirms it and continues to onboarding** in
  one step (`LanguageSelectionController.markSelected()` → `/welcome`). There is
  no "continue" button and no "default" marker any more.
* Arabic is still the default: `LocaleController.build()` returns
  `SupportedLocales.arabic`, and the page re-commits Arabic in `initState` if the
  locale is `null`, so the sheet renders Arabic-first. Tests that assert English
  override the locale controller to device-driven (`authOverrides`);
  `pumpApp(locale: arabic)` forces RTL where needed.
* Enters exactly like the prototype overlay: `ENTRY_Splash` → AFTER_TIMEOUT
  1.6s → OVERLAY `sheet`, **DISSOLVE 220ms ease-out-cubic** — scrim and card
  fade in together (no slide).

## Onboarding

* Full-bleed photo `assets/images/entry_onboarding.jpg` (the v2 frame fill,
  Figma image `3964702c…`; replaces v1 `entry_hero.jpg`), via
  `AppImages.entryHero`.
* One floating card 16px from the sides and bottom (bottom tracks larger system
  insets so a 3-button nav bar never covers the CTA):
  * a 70px white avatar ring (2px `stone/300` @50%, tile shadow) holding the 50px
    brand mark, **overlapping the card's top edge by 44px**;
  * the **glass** card — radius 37, white @20% over a backdrop blur (Figma
    `GLASS` 21 → sigma 10.5), padding 50 top / 16 sides+bottom;
  * centred white headline (`display` 28/40) and sub-line (`body-lg` 17/28),
    8px apart; 17px (8 + 1px spacer + 8) to the CTA;
  * `ابدأ الآن` — `PrimaryButton`, `Size=Small` (40).
* Copy: `استكشف فنادقنا واحجز إقامتك من مكانك` /
  `ببساطة اختر غرفتك المفضلة في وقتك المفضل`.

## Dashboard-managed content

The logo, app name (splash wordmark), onboarding photo, headline, sub-line and
button label are edited in the dashboard (**Administration → Guest app**,
`/guest-app`, permission `app-content.manage`) and read anonymously by the app
from `GET /api/v1/guest/app-content`. The Figma assets and ARB strings above are
the **bundled defaults**, used for any field that isn't configured.

* Backend: `App\Domain\AppContent` — one app-wide row (`guest_app_contents`);
  text is stored as `{"en","ar"}` maps. The resource returns **both** locales,
  because the entry screens are shown before and while the guest picks a
  language. Images live on the hotel-media public disk under `guest-app/{slot}/`
  (slots `logo`, `onboarding_image`, `app_icon`). Staff editor: `GET|PATCH /app-content`,
  `POST /app-content/images` (`slot` + `image`), `DELETE /app-content/images/{slot}`.
* Mobile: `lib/features/app_content/` (dummy/api data sources → repository →
  `appContentProvider`). The provider is fetched once per launch and **never
  fails**: an error or a response slower than 3s (`appContentTimeout`)
  resolves to `AppContent.empty`, which means the bundled defaults. The dummy
  source returns empty content, like a backend where nothing is configured yet.
* A locale missing in the dashboard falls back to the bundled string **in the
  same language**. The app never shows the other language instead.
* No flicker: `ManagedBrandLogo` lays out the lock-up transparently until the
  content resolves, then fades it in. The splash precaches the onboarding
  photo as soon as the content arrives. Onboarding shows a dark ground while
  loading, never the bundled photo first. An uploaded image that fails to load
  falls back to the app name (logo) or the bundled photo.

### App-wide branding controls (2026-10-10)

The same dashboard page also manages the app's basic branding, read through
`brandingProvider` (fresh content once loaded → the **cached** last response
meanwhile → bundled defaults):

| Dashboard field | Where the app uses it |
| --- | --- |
| App name | `MaterialApp` title (task switcher / browser tab), router error page, splash wordmark |
| App icon (`app_icon` slot, square ≥192px) | Web favicon + apple-touch icon at runtime (`core/platform/web_app_icon.dart`). **Android/iOS launcher icons are build-time assets and do not change.** |
| Brand colour (`primary_color`, `#RRGGBB`) | `AppTheme.lightBranded`: primary fill, hover/pressed, focus ring, readable on-primary label — whole app incl. the onboarding CTA |
| Support phone / WhatsApp / email / website | `PROFILE_Support` "تواصل معنا" card (`SupportContactsCard`); unset ones hidden |
| Terms / privacy URLs | Under the sign-in terms line (`LegalLinksRow`) and on `PROFILE_Privacy` |

* The raw `GET /guest/app-content` response is persisted
  (`AppPreferences.appContentCache`), so a relaunch — or an offline launch —
  shows the hotel's name, colour and icon from the first frame.
* Contacts/links open through `ExternalLauncher` (`dial`, `whatsapp` → wa.me,
  `email` → mailto, `openUrl` — http/https only); a failure shows a snackbar.

## Pending / known deviations

* ✅ **Tajawal only** (decision 2026-09-26) — the v2 frames name thmanyah sans
  (headline Black, wordmark Bold, sheet title Medium); the app deliberately
  ships Tajawal, Black maps to Tajawal ExtraBold. Tajawal is wider, so the onboarding
  sub-line wraps to two lines (one in the Figma) and the card is ~28px taller.
* ⏳ **English onboarding copy** is our translation — the Figma binds the Arabic
  to a library `Content` variable whose English value isn't in the file.
  The Figma headline named the sample hotel `فندق الواحة`; replaced
  (QA 2026-10-08) with platform-wide copy because the app lists many hotels.
* Language buttons are 48 tall (Figma overrides a Small button to 49); the
  onboarding CTA paints at 40 but keeps Material's 48px tap target, adding 4px
  above/below it.

## Routing

`languageSelectedProvider`
(`lib/features/authentication/presentation/state/language_selection_controller.dart`)
is a `bool` — `false` until the guest picks a language. While `false` the router
sends every unauthenticated location to `/welcome/language` first; once `true`
the entry flow applies (`splash → onboarding → discover`, then browsing is
public — see `mobile-deferred-auth.md`). `AppRoutes.language` is part of
`AppRoutes.authSurface`, so an authenticated guest never sees it.

**Language + onboarding are first-run only.** Tapping the onboarding CTA sets
`onboardingCompletedProvider` (same file), persisted through `AppPreferences`
(`lib/core/storage/app_preferences.dart`, shared_preferences, loaded in
`bootstrap()` before the first frame). On every later launch both flags start
`true`, and a signed-out guest goes `splash → discover` (a signed-in one to the
app home, as before); `/welcome` and `/welcome/language` redirect to discover.
The chosen locale is persisted too (`LocaleController`), so skipping the
language screen keeps the guest's language. Tests use `InMemoryAppPreferences`
by default and bypass the language screen via
`authOverrides(languageChosen: …)` / `pumpApp(languageChosen: …)`.
