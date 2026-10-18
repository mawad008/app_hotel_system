# Guest App — Design System: Token & Component Reference

**Source:** `mobile/Design/Hotel Design System.fig` (Figma file *"Hotel System"*,
v1.0 · RTL mobile · Guest App). This is the **canonical token library** — a
dedicated design-system file, separate from the screen-flow file
`Design/hotel_guest_app.fig`.

This document is a faithful extraction of that file: every variable value, text
style, elevation, and component variant axis, exactly as authored in Figma. It is
the **spec**. `design-system.md` describes what the Flutter theme currently
*implements* against it; where the two disagree, this file wins and the theme is
the thing to fix.

> Extracted 2026-09-09 by decoding the `.fig` kiwi payload directly. If the Figma
> file changes, re-extract rather than hand-editing values here.
>
> **v2 library update (2026-09-24).** The redesigned screens file
> `Design/hotel_guest_app.fig` (exported 2026-09-23) links a newer version of
> this library. Its `Primitives` / `Color` / `Typography` values were
> re-extracted from that file's linked variables and are reflected in §2, §3,
> §6 and §9 below. Summary of the change — **the brown "oud" brand became a
> neutral black/white palette**:
>
> | token (Light) | v1 | v2 |
> |---|---|---|
> | `color/bg/canvas` | `stone/25` `#FCFAF7` | `stone/0` `#FFFFFF` |
> | `color/bg/primary` | `oud/700` `#513425` | `ink/950` `#0E0C0A` |
> | `color/bg/primary-pressed` | `oud/800` `#3A251A` | `ink/900` `#171412` |
> | `color/bg/inverse` | `oud/900` `#241610` | `ink/900` `#171412` |
> | `color/text/primary` | `stone/900` `#1D1A16` | `stone/950` `#110F0C` |
> | `color/text/accent` | `oud/700` `#513425` | `ink/700` `#38312B` |
> | `color/accent/warm-bg` | `gold/50` `#F6EFDD` | `gold/25` `#FAF7F0` |
> | `color/border/sub icon` | — | `stone/600` `#5A544A` (Dark `stone/400`) *(new)* |
> | `font/family/arabic` | Tajawal | **thmanyah sans** |
>
> **Dark mode is unchanged** (still `oud`-led). `primary-hover` (`oud/600`),
> `primary-subtle` (`oud/50`), `border/focus` (`oud/500`) and
> `border/accent-subtle` (`oud/100`) still alias brown in v2 — mirrored verbatim,
> flagged to the designer as likely leftovers. Primitives removed in v2:
> `stone/25`, `gold/50`, `oud/800`. The standalone `Hotel Design System.fig` in
> `Design/` is still v1 — this section supersedes it where they differ.

---

## 0. File contents at a glance

| | |
|---|---|
| Pages (canvases) | 43 |
| Variable collections | 6 (`Primitives`, `Color`, `Spacing`, `Radius`, `Typography`, `Content`) |
| Variables | ~248 |
| Text styles | 40 (`text/ar/*`, `text/en/*`, `text/num/*`) |
| Elevation styles | 4 (`elevation/1‑4`) |
| Components (DS, excl. icon library) | ~35 sets across the `COMPONENTS` / `UTILITIES` pages |
| Icon library | Hicon set, `Linear` / `Outline` / `Bold` weights (~1500 symbols) |

**Component pages:** Input · Button · Status Pill · Logo Placeholder · Data Card ·
Tab Bar · Action Sheet · App Bar · Search Field · Filter Chip · Stepper ·
Icon Button · Section Header · Property Chip · Listing Card · Rating Row · Toast ·
Card · Rating Badge · Thumbnail Row · Scrim · Empty State · List Row · Price ·
Page Footer · OTP Input · Phone Field · Toggle · List Item · Available Room Card.

**Foundations pages:** Color · Typography · Spacing & Radius · Elevation ·
Getting Started · Changelog · Icons.

> ⚠️ **App identity mismatch.** The `Content` collection names the app
> **`نُزُل` / `Nuzul`**, tagline **`إقامة بلا أوراق` / "A paperless stay"**.
> The cover page says *"Hotel System"*; the product is now **Stdy Hotels**
> (logo: `Design/brand/stdy-hotels-logo.svg`), which is what `l10n` uses.
> Likewise the `Getting Started` prose is **stale** (mentions `petrol`/`sand`
> ramps, "56 primitives") — the collections below are authoritative; the ramp was
> renamed `petrol → oud` (old CSS `codeSyntax` still reads `var(--petrol-500)`).

---

## 1. Token architecture

Five token collections plus a content collection. **Components bind only to the
semantic `Color` collection — never to `Primitives`**, which are scope-hidden
(`scopes = []`) so they cannot be picked by accident.

| Collection | Modes | Scope | Role |
|---|---|---|---|
| `Primitives` | `Value` | none (hidden) | Raw colour ramps |
| `Color` | `Light` / `Dark` | all fills/strokes | Semantic colour — every token aliases a primitive in **both** modes |
| `Spacing` | `Value` | `GAP`, `WIDTH_HEIGHT` | 8pt grid |
| `Radius` | `Value` | `CORNER_RADIUS` | corner radii |
| `Typography` | `Value` | — | size + line-height numerics + font family/weight names, bound into the text styles |
| `Content` | `العربية` / `English` | text | bilingual sample/label copy used inside components |

---

## 2. Primitives — raw ramps (`Primitives`, 1 mode)

### `oud` — warm brown (v1 brand primary; v2 keeps it for subtle/focus/hover only)
| step | hex | | step | hex |
|---|---|---|---|---|
| `oud/50`  | `#F8F1EC` | | `oud/500` | `#855A42` |
| `oud/100` | `#EDDCD0` | | `oud/600` | `#6B4632` |
| `oud/200` | `#DBBCA6` | | `oud/700` | `#513425` |
| `oud/300` | `#C2977A` | | ~~`oud/800`~~ | ~~`#3A251A`~~ *(removed v2)* |
| `oud/400` | `#A5765A` | | `oud/900` | `#241610` |

### `gold` — accent
| step | hex | | step | hex |
|---|---|---|---|---|
| `gold/25`  | `#FAF7F0` | | `gold/400` | `#BF933C` |
| ~~`gold/50`~~ | ~~`#F6EFDD`~~ *(removed v2)* | | `gold/500` | `#A17A2D` |
| `gold/100` | `#EEE0C0` | | `gold/600` | `#836324` |
| `gold/200` | `#E2CB98` | | `gold/700` | `#654C1C` |
| `gold/300` | `#D2AE65` | | `gold/800` | `#493715` |
| | | | `gold/900` | `#2C210C` |

### `stone` — neutral (light ground)
| step | hex | | step | hex |
|---|---|---|---|---|
| `stone/0`   | `#FFFFFF` | | `stone/300` | `#CEC8BC` |
| ~~`stone/25`~~ | ~~`#FCFAF7`~~ *(removed v2)* | | `stone/400` | `#A49D8F` |
| `stone/50`  | `#F7F4EF` | | `stone/500` | `#736C5F` |
| `stone/100` | `#EFEBE4` | | `stone/600` | `#5A544A` |
| `stone/200` | `#E5E0D7` | | `stone/700` | `#443F37` |
| | | | `stone/800` | `#2E2A24` |
| | | | `stone/900` | `#1D1A16` |
| | | | `stone/950` | `#110F0C` |

### `ink` — near-black (v2 primary action + inverse; dark-mode ground)
| step | hex | | step | hex |
|---|---|---|---|---|
| `ink/50`  | `#F2EFE9` | | `ink/700` | `#38312B` |
| `ink/100` | `#E9E5DF` | | `ink/800` | `#241F1B` |
| `ink/300` | `#CAC4BB` | | `ink/900` | `#171412` |
| | | | `ink/950` | `#0E0C0A` |

### State hues (`50` tint · `200` border · `500` solid · `600` fg-dark · `900` dark-bg)
| hue | 50 | 200 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|
| `green` (success) | `#EAF3EF` | `#A9CFBD` | `#2F7D62` | `#256349` | — | — | `#14261C` |
| `amber` (warning) | `#F9F1E4` | `#E4CDA3` | `#C58A32` | `#8A5F1E` | — | — | `#2A2113` |
| `red` (error/destructive) | `#FAEBEB` | `#E8B9B9` | `#C65454` | `#A33A3A` | `#8A3131` | `#6E2727` | `#2B1713` |
| `blue` (info) | `#EAF1F5` | `#B3CBD8` | `#397A9B` | `#2C6079` | — | — | `#14212D` |

---

## 3. Semantic colour (`Color`, Light / Dark)

Bind components to these. Every value resolves to a primitive above. Values are
**v2** (changed-in-v2 cells marked ✱).

### Background
| token | Light | Dark |
|---|---|---|
| `color/bg/canvas` | ✱ `#FFFFFF` | `#0E0C0A` |
| `color/bg/surface` | `#FFFFFF` | `#1D1A16` |
| `color/bg/surface-raised` | `#FFFFFF` | `#2E2A24` |
| `color/bg/subtle` | `#EFEBE4` | `#2E2A24` |
| `color/bg/primary` | ✱ `#0E0C0A` | `#C2977A` |
| `color/bg/primary-hover` | `#6B4632` | `#DBBCA6` |
| `color/bg/primary-pressed` | ✱ `#171412` | `#A5765A` |
| `color/bg/primary-subtle` | `#F8F1EC` | `#241610` |
| `color/bg/disabled` | `#E5E0D7` | `#443F37` |
| `color/bg/inverse` | ✱ `#171412` | `#241610` |
| `color/bg/destructive` | `#A33A3A` | `#C65454` |
| `color/bg/destructive-hover` | `#8A3131` | `#A33A3A` |
| `color/bg/destructive-pressed` | `#6E2727` | `#8A3131` |

### Text
| token | Light | Dark |
|---|---|---|
| `color/text/primary` | ✱ `#110F0C` | `#F7F4EF` |
| `color/text/secondary` | `#736C5F` | `#A49D8F` |
| `color/text/label` | `#443F37` | `#CEC8BC` |
| `color/text/placeholder` | `#736C5F` | `#A49D8F` |
| `color/text/on-primary` | `#FFFFFF` | `#241610` |
| `color/text/on-inverse` | `#FFFFFF` | `#FFFFFF` |
| `color/text/accent` | ✱ `#38312B` | `#C2977A` |
| `color/text/disabled` | `#A49D8F` | `#5A544A` |

### Border
| token | Light | Dark |
|---|---|---|
| `color/border/default` | `#E5E0D7` | `#443F37` |
| `color/border/strong` | `#CEC8BC` | `#5A544A` |
| `color/border/focus` | `#855A42` | `#C2977A` |
| `color/border/accent-subtle` | `#EDDCD0` | `#513425` |
| `color/border/on-inverse` | `#FFFFFF` | `#FFFFFF` |
| `color/border/sub icon` ✱ *(new)* | `#5A544A` | `#A49D8F` |

### State (`fg` on tinted bg, `bg` tint, `border`)
| token | Light | Dark |
|---|---|---|
| `color/state/success/{fg,bg,border}` | `#256349` · `#EAF3EF` · `#A9CFBD` | `#A9CFBD` · `#14261C` · `#2F7D62` |
| `color/state/warning/{fg,bg,border}` | `#8A5F1E` · `#F9F1E4` · `#E4CDA3` | `#E4CDA3` · `#2A2113` · `#C58A32` |
| `color/state/error/{fg,bg,border}` | `#A33A3A` · `#FAEBEB` · `#E8B9B9` | `#E8B9B9` · `#2B1713` · `#C65454` |
| `color/state/info/{fg,bg,border}` | `#2C6079` · `#EAF1F5` · `#B3CBD8` | `#B3CBD8` · `#14212D` · `#397A9B` |

### Warm accent (prices, ratings, logo)
| token | Light | Dark |
|---|---|---|
| `color/accent/warm` | `#BF933C` | `#D2AE65` |
| `color/accent/warm-fg` | `#836324` | `#D2AE65` |
| `color/accent/warm-bg` | ✱ `#FAF7F0` | `#2C210C` |
| `color/accent/warm-border` | `#E2CB98` | `#654C1C` |

> Dark mode is **fully specified here** — unlike the old flow file. When the app
> builds a real dark theme, use these values verbatim.

---

## 4. Spacing (`Spacing`, 1 mode) — 8pt grid

| token | px | | token | px |
|---|---|---|---|---|
| `space/1` | 4  | | `space/6`  | 24 |
| `space/2` | 8  | | `space/7`  | 32 |
| `space/3` | 12 | | `space/8`  | 40 |
| `space/4` | 16 | | `space/9`  | 48 |
| `space/5` | 20 | | `space/10` | 64 |

Base unit 8. The 4px half-step (`space/1`) exists **only** for icon-to-label gaps
and dense chips — nothing else sits off the grid.

---

## 5. Radius (`Radius`, 1 mode)

| token | px | use |
|---|---|---|
| `radius/xs`   | 4   | inner clips, nested chips |
| `radius/sm`   | 8   | small controls |
| `radius/md`   | 14  | inputs, buttons |
| `radius/lg`   | 20  | cards |
| `radius/xl`   | 24  | large cards / hero |
| `radius/2xl`  | 32  | bottom sheets |
| `radius/full` | 999 | pills, avatars |

---

## 6. Typography

### 6.1 Families & weights (`Typography` collection)
| token | value |
|---|---|
| `font/family/arabic` | **thmanyah sans** (v2; v1 = Tajawal) — ✅ app ships **Tajawal only** (decision 2026-09-26), see §12 |
| `font/family/latin` | **Inter** |
| `font/family/mono` | **Google Sans Code** (numeric styles) |
| `font/weight/regular` | `Regular` |
| `font/weight/medium` | `Medium` |
| `font/weight/semibold` | `Semi Bold` (Latin only — Tajawal has none) |
| `font/weight/bold` | `Bold` |
| `font/weight/extrabold` | `ExtraBold` |

> The theme currently bundles Tajawal (correct) but the Latin family here is
> **Inter**, not the "Google Sans Flex" mentioned in stale board copy. Latin copy
> in this app is minimal (wordmark, codes) so the practical gap is small, but
> `app_typography.dart` should treat Inter as the Latin fallback.

### 6.2 Size + line-height numerics (`Typography` collection)
Line-height differs by script — Arabic needs extra leading to clear diacritics.

| step | size | AR line (`/line`) | EN line (`/line-en`) |
|---|---|---|---|
| `display-xl` | 44 | 56 | — |
| `display-lg` | 32 | 44 | 40 |
| `display`    | 28 | 40 | 36 |
| `title-lg`   | 24 | 36 | 32 |
| `title`      | 20 | 32 | 28 |
| `headline`   | 18 | 28 | 26 |
| `body-lg`    | 17 | 28 | 26 |
| `body`       | 15 | 26 | 24 |
| `body-sm`    | 14 | 24 | 22 |
| `label`      | 13 | 20 | 18 |
| `caption`    | 12 | 18 | 16 |

### 6.3 Text styles (40 total) — `letter-spacing: 0` on every one

**`text/ar/*`** (Tajawal): `display-xl` 44/56 ExtraBold · `display-lg` 32/44
ExtraBold · `display` 28/40 ExtraBold · `title-lg` 24/36 Bold · `title` 20/32 Bold
· `headline` 18/28 Bold · `body-lg` 17/28 Regular · `body` 15/26 Regular ·
`body-sm` 14/24 Regular · `label` 13/20 Medium · `caption` 12/18 Regular.

**`text/en/*`** (Inter): `display-lg` 32/40 Bold · `display` 28/36 Bold ·
`title-lg` 24/32 Semi Bold · `title` 20/28 Semi Bold · `headline` 18/26 Semi Bold
· `body-lg` 17/26 Regular · `body` 15/24 Regular · `body-sm` 14/22 Regular ·
`label` 13/18 Medium · `caption` 12/16 Regular.

**`*-strong` / `*-regular` overrides:** `text/{ar,en}/body-strong` 15/24,
`body-sm-strong` 14/22, `label-strong` 13/18 (AR → Bold, EN → Semi Bold);
`label-regular` 13/18 for de-emphasised labels.

**`text/num/*`** (Google Sans Code, tabular — room numbers, deposit amounts,
points, codes): `display` 64/68 Bold · `xl` 30/36 Bold · `lg` 24/30 Medium ·
`md` 17/24 Medium · `sm` 15/22 Medium · `xs` 12/16 Medium.

### 6.4 Arabic rules the system enforces
1. **No letter-spacing, ever.** Arabic is cursive; tracking breaks the joins.
   Every `text/ar/*` ships at 0.
2. **No uppercase, small-caps, or italic.** Arabic has no case and no true
   italic — build eyebrows from weight + colour. (Tracked uppercase eyebrows are
   legitimate in `text/en/*` only.)
3. **Numerals are a product decision.** Western `0-9` is the default here because
   prices sit beside Latin currency and card data. Never mix within a screen.
4. **Body minimum is 15px, not 14** — Arabic letterforms carry more detail per em.
5. Weight ladders diverge deliberately: Arabic climbs
   ExtraBold / Bold / Medium / Regular; Latin climbs Bold / Semi Bold / Medium /
   Regular (Tajawal has no Semi Bold, so 600 collapses into Bold for Arabic).

---

## 7. Elevation (`elevation/1‑4`)

Shadow colour is near-black **`#101517`** (from `ink`), never a grey blur. In a
minimal UI a 1px border does most of the separating — elevation is reserved for
things that genuinely float.

| style | offset (x,y) | blur | spread | opacity | use |
|---|---|---|---|---|---|
| `elevation/1` | 0, 1  | 2  | 0  | 4%  | resting card (paired with a 1px border) |
| `elevation/2` | 0, 2  | 4  | 0  | 4%  | tab bar, header — sticky surfaces |
| `elevation/3` | 0, 4  | 8  | −2 | 5%  | FAB, popover, digital-key hero |
| `elevation/4` | 0, **−4** | 24 | −4 | 12% | bottom sheet — **casts upward** |

---

## 8. RTL mirroring

Authored in logical properties — one stylesheet serves both directions.

| element | behaviour | note |
|---|---|---|
| Layout axis | **MIRRORS** | `margin-inline-start`, never `margin-left` |
| Back / forward icons | **MIRRORS** | direction of travel reverses |
| Progress, steppers | **MIRRORS** | fills right-to-left in RTL |
| Clock, media controls | **FIXED** | play is universally rightward |
| Numerals, prices, codes | **FIXED** | stay LTR inside an RTL line |
| Card / phone / email inputs | **FIXED** | force `dir=ltr` — prevents digit reordering |
| Primary action | **THUMB ZONE** | bottom bar, kept central and reachable |

---

## 9. Components — variant axes

Exactly as authored. `State` axes follow the interaction set
`Default · Hover · Pressed · Focused · Disabled` plus component-specific extras.

| Component | Variant axes |
|---|---|
| **Button** | `Variant` {Primary, Secondary, Tertiary, Destructive} × `Size` {Small, Medium, Large} × `State` {Default, Hover, Pressed, Focused, Disabled, **Loading**} |
| **Icon Button** | `Style` {Surface, Dark} × `State` {Default, Hover, Pressed, Focused, Disabled, **Selected**} |
| **Input** | `State` {Default, Active, Filled, Disabled, Error, Success} |
| **Phone Field** | `State` {Default, Active, Filled, Disabled, Error, Success} |
| **OTP Input** | `State` {Empty, Active, Filled, Error, Success} |
| **Search Field** | single |
| **Toggle** | `State` {Off, On, Disabled} |
| **Stepper** | single (circular −/+ around a bordered value) |
| **Filter Chip** | `State` {Default, Selected} |
| **Property Chip** | single |
| **Status Pill** | `Tone` {Success, Warning, Error, Info} |
| **Rating Badge** | `Size` {Compact, WithCount} |
| **Rating Row** | single |
| **Price** | `Size` {Small, Medium, Large} + `Saudi Riyal Symbol` vector (`SAR`) |
| **Card** | `Style` {Elevated, Outlined, Subtle, Inverse} |
| **Data Card** | default + `[deprecated]` |
| **Listing Card** | `Layout` {Stacked, Overlay} |
| **Available Room Card** | `State` {Default, Limited, Selected, Unavailable} |
| **List Item** | `Trailing` {None, Chevron, Toggle, Value} |
| **List Row** | `Style` {Default, Muted, Total} |
| **Section Header** | single |
| **Thumbnail Row** | single |
| **Tab Bar** | `Active` {Home, Bookings, Services, Account} |
| **App Bar** | App Bar + Status Bar + Home Indicator sub-parts |
| **Page Footer** | `Actions` {None, One, Two} × `Platform` {iOS, Android} |
| **Action Sheet** | `Type` {Confirm, Destructive} |
| **Toast** | `Tone` {Success, Error, Info} |
| **Empty State** | single |
| **Scrim** | single |
| **Logo Placeholder** | `Size` {Splash, Lockup, Compact, Avatar} |

**v2 component deltas** (from the screens file's linked components; colour-only
changes that follow §3 automatically are omitted):

| Component | v2 change |
|---|---|
| **Button** (all variants) | label weight Bold → **Medium**; Medium/Small label 15 → **14**, Large stays 16. Secondary/Tertiary label → `text/accent` (`#38312B`); Secondary = no fill + 1.5px `border/accent-subtle` |
| **Page Footer** | primary action Large 56 → **Medium 48**; footer 116 → 108 |
| **Action Sheet** | actions 56 → **40** (Small) |
| **App Bar** | fill → `bg/canvas` (white); title 18 Bold → **18 Medium** |
| **Tab Bar** | labels 11 → **12**; selected Bold `oud/700` → **Medium `text/primary`**; unselected Regular `text/secondary` |
| **Status Pill** | label 11.5 Medium → **12 Regular** |
| **Empty State** | icon tile `stone/100` → **white + soft shadow** (2px @4% + 3px @6%, `#101517`); title Bold → **Medium** |
| **Rating Row** | track `stone/100` → `stone/200`; fill → `ink/950` |
| **Rating Badge** | fill → `gold/25` |
| **Property Chip** | fill `stone/100` → **white** |
| **Search Field** | 52 → 47 high; placeholder 15 → 12; icons 20 → 18 |
| **Card · Inverse** | `oud/900` → `ink/900` |
| **Logo Placeholder · Splash** | mark `oud/700` → `ink/700` |
| New | `Hotel card`, `Room` {Vertical, Horizontal}, `Image Placeholder` ratios; `Data Card` removed |

The **Saudi Riyal mark** is a vector source (no font carries the glyph — it can
never be typed); every `Price` instance references it. Matches the app's existing
`RiyalMark` / `MoneyText`.

---

## 10. `Content` collection — bilingual strings (`العربية` / `English`)

Used inside component instances; a candidate seed for `l10n` ARB keys. Selected:

| key | العربية | English |
|---|---|---|
| `content/app/name` | نُزُل | Nuzul |
| `content/app/tagline` | إقامة بلا أوراق | A paperless stay |
| `content/onboard/head` | احجز، تحقّق، وادخل غرفتك من هاتفك | Book, verify and enter your room from your phone |
| `content/onboard/sub` | دون طوابير ودون استقبال | No queues. No front desk. |
| `content/nav/{home,bookings,services,account}` | الرئيسية / حجوزاتي / الخدمات / حسابي | Home / Bookings / Services / Account |
| `content/action/{continue,book,search,reset,back,pay,checkout,verify,capture,retry}` | متابعة / احجز الآن / بحث / إعادة تعيين / رجوع / ادفع الآن / إتمام المغادرة / تحقق من الهوية / التقط الصورة / إعادة المحاولة | Continue / Book now / Search / Reset / Back / Pay now / Check out / Verify identity / Take photo / Try again |
| `content/action/{viewAll,readMore,contact,extend,getStarted}` | عرض الكل / اقرأ المزيد / تواصل مع الاستقبال / تمديد الإقامة / ابدأ الآن | View all / Read more / Contact reception / Extend stay / Let's start |
| `content/status/{available,pending,confirmed,processing,verified,inReview,checkedIn}` | متاحة / قيد الانتظار / مؤكد / جارٍ المعالجة / تم التحقق / قيد المراجعة / تم تسجيل الدخول | Available / Pending / Confirmed / Processing / Verified / Under review / Checked in |
| `content/pay/holdNotice` | يُحجز مبلغ التأمين دون خصمه حتى تسجيل الدخول | The deposit is held, not charged, until check-in |
| `content/pay/secureNote` | لا يتم حفظ بيانات بطاقتك | Your card details are never stored |
| `content/verify/step1` | صوّر بطاقتك الشخصية أو جواز سفرك | Photograph your ID or passport |
| `content/verify/step2` | التقط صورة حية من الكاميرا | Take a live photo with the camera |
| `content/verify/liveOnly` | الكاميرا فقط — لا يمكن الرفع من المعرض | Camera only — gallery uploads are not accepted |
| `content/verify/privacy` | تُحفظ صورك بشكل آمن وتُحذف بعد انتهاء إقامتك | Your photos are stored securely and deleted after your stay |
| `content/key/{title,room,code,expiry}` | تم تسجيل دخولك / رقم الغرفة / رمز الدخول / ينتهي بانتهاء إقامتك | You're checked in / Room number / Entry code / Expires when your stay ends |
| `content/checkout/settled` | تمت التسوية وأُصدرت فاتورتك | Settled — your invoice has been issued |
| `content/unit/{currency,perNight}` | ﷼ / لكل ليلة | ﷼ / per night |

Sample data: hotels `فندق الواحة` / `فندق المرسى` / `فندق النخيل`
(Oasis / Marina / Palms), cities `المدينة الأولى` / `المدينة الثانية`,
room `غرفة مزدوجة ديلوكس` / "Deluxe double room".

---

## 11. Figma plugin API notes (for anyone scripting this file)

The `Getting Started` page records seven behaviours that cost the author a full
day. Relevant only if you automate this `.fig`:

1. Never set `.visible` on an instance child — it **destroys** the node
   permanently. Use a BOOLEAN component property instead.
2. Section children use **section-relative** coordinates (`child.x = 72`, not
   `section.x + 72`).
3. `swapComponent` renames the node and invalidates your reference — re-query by
   index immediately after.
4. Match component property keys by prefix **and** type (`key.split("#")[0]`).
5. `componentPropertyDefinitions` can't be read on a variant — only on a set or
   non-variant component.
6. Consecutive `setProperties` calls discard each other — build one object, call
   once.
7. Match nodes by structure, not by name.

---

## 12. Mapping to the Flutter theme

Implemented in the **Phase 11C** alignment pass (2026-09-09) and re-aligned to
the v2 library in **Phase A** (2026-09-24) — see `design-system.md` for the
as-built detail.

| Figma | Flutter (`mobile/lib/core/theme/`) | Status |
|---|---|---|
| `Primitives` ramps | `AppPrimitives` in `app_colors.dart` | ✅ verbatim from §2 |
| `Color` semantic (Light/Dark) | `AppColorTokens` ThemeExtension (`context.colors.*`) + `ColorScheme` | ✅ verbatim from §3, both modes; `AppColors`/`AppSemanticColors` remain as value-correct shims pending a cleanup PR |
| `Spacing` | `app_spacing.dart` `space1..space10` (+ `xxs..xxxl` aliases) | ✅ from §4 |
| `Radius` | `app_radius.dart` | ✅ from §5 (`card`→20, `sheet`→32; `input` kept = `md` 14) |
| `Typography` sizes/lines | `app_typography.dart` `TextTheme` + `bodyStrong`/`labelStrong`/`brand`/`num*` accessors | ✅ from §6.2/§6.3 — Arabic line-heights, `letterSpacing: 0` throughout, `num*` mono ramp in Tajawal tabular figures |
| `elevation/1‑4` | `app_shadows.dart` `elevation1..elevation4` (+ `card`/`raised` aliases) | ✅ exact from §7 (`#101517`, alpha-encoded opacity) |
| Components §9 | `core/widgets/*` | ✅ Button `Loading`/`Size` (`ButtonSpinner`, `AppButtonSize`), Icon Button `Style`×`Selected` (`AppIconButton`), Card `{elevated,outlined,subtle,inverse}` (`AppCardStyle`), `SectionHeader`, `AppListRow`, `switchTheme`. ⬜ **Deferred:** Available Room Card `Limited` (needs a domain `isLimited`/`remainingCount` field + dummy source + API contract), plus the list in `design-system.md` → *Deferred components* |
| `Content` §10 | `l10n` ARB files | ✅ mostly pre-existing; one new key `reservationStatusConfirmed` ("مؤكد"); mapping table in `design-system.md` |

**v2 Phase A (2026-09-24) — done:** v2 `Color` Light values + `border/sub icon`
in `AppColorTokens`; removed `stone/25`/`gold/50`/`oud/800` primitives; legacy
`AppColors` shims repointed (`brown700`→`ink/950`, `paper`→`stone/0`,
`ink900`→`stone/950`); button labels (`AppTypography.button`/`buttonLarge`,
standing height 48), secondary outline, app-bar title, tab-bar labels, status
pill, empty-state tile (`AppShadows.tile`).

**v2 pending:**
- ✅ **Tajawal only** (decision 2026-09-26) — thmanyah sans in the Figma is an accepted deviation, not a pending swap.
  Swap = `AppTypography.fontFamily` + the `pubspec.yaml` font block.
- ✅ Phase B (2026-09-24): splash, language sheet, onboarding — see
  `mobile-entry-language-selection.md`. Brand mark now drawn from the decoded
  v2 vectors (`BrandLogo`/`BrandMark`).
- ✅ Phase C (2026-09-24): Home (`HOME_Default` + `HOME_if One hotel`) and the
  4-tab bar — see `mobile-discover-book.md` / `design-system.md`.
- ✅ Phase D (2026-09-24): Hotel / Room detail *Premium* — see
  `mobile-discover-book.md`. New raw primitive `AppPrimitives.mist` (#F6F6F6).
- ⏳ Screen-specific v2 redesigns (Phase E+):
  booking summary + loyalty field, digital key,
  profile, bookings list. Action Sheet 40px buttons and final Rating Row
  sizing land with their screens.
- ✅ Search Field v2 dimensions: 47px height, 12px placeholder, 18px icons
  (`features/discovery/presentation/widgets/hotel_search_field.dart`).
- ⏳ Rendered PNG boards in `Design/` are still v1 — re-export from Figma.

**Remaining (follow-up PR):** migrate the ~14 scattered single `AppColors.*`
reads + the entry-page gradient + 4 `BorderRadius.circular(n)` literals in
feature code to `context.colors` / `AppRadius`, then delete the `AppColors` /
`AppSemanticColors` / `AppTypography.semiBold` shims.
