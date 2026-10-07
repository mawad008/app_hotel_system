# Hotel Guest App --- Architecture

## 1. Architecture Goals

The Flutter application SHALL be:

-   API-first
-   feature-oriented
-   testable
-   localization-ready
-   RTL/LTR capable
-   independent of a specific data source
-   safe for sensitive identity/payment flows
-   prepared for incremental backend integration

Laravel remains the system of record.

## 2. Recommended Structure

``` text
mobile/
├── lib/
│   ├── app/
│   │   ├── router/
│   │   ├── bootstrap/
│   │   └── app.dart
│   ├── core/
│   │   ├── network/
│   │   ├── storage/
│   │   ├── localization/
│   │   ├── theme/
│   │   ├── errors/
│   │   ├── security/
│   │   └── widgets/
│   └── features/
│       ├── authentication/
│       ├── discovery/
│       ├── availability/
│       ├── reservations/
│       ├── payments/
│       ├── identity_verification/
│       ├── digital_access/
│       ├── stay_services/
│       ├── checkout/
│       ├── loyalty/
│       ├── reviews/
│       ├── bookings/
│       ├── notifications/
│       └── profile/
└── test/
```

## 3. Feature Layers

Each feature should follow:

``` text
presentation
    ↓
domain
    ↓
data
```

A practical feature can contain:

``` text
feature/
├── data/
│   ├── datasources/
│   │   ├── dummy_*.dart
│   │   └── api_*.dart
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    └── state/
```

## 4. Repository Rule

The UI depends on repository interfaces.

``` dart
abstract class ReservationRepository {
  Future<Reservation> create(CreateReservationRequest request);
  Future<Reservation> getById(int id);
}
```

Implementations can use dummy or API data sources without changing the
UI contract.

## 5. API Layer

The API client should centralize:

-   base URL
-   `/api/v1`
-   authentication headers
-   the content language header (`X-Locale`, from `contentLanguageProvider`)
-   serialization
-   timeout
-   request IDs where available
-   standard error parsing
-   401/403/404/409/422/429/5xx handling

Do not create ad-hoc HTTP calls inside screens.

## 6. Business Logic Boundary

Flutter may handle presentation logic such as:

-   loading state
-   form state
-   navigation
-   formatting
-   local validation for user experience

Laravel MUST remain authoritative for:

-   room availability
-   reservation validity
-   price
-   payment state
-   identity verification state
-   digital access authorization
-   checkout amounts
-   loyalty ledger/rules
-   review eligibility
-   permissions

## 7. State Management

Use the project's selected state-management approach consistently. Do
not introduce multiple competing state-management frameworks without an
approved architectural reason.

Prefer small, feature-local states over a giant global state.

## 8. Sensitive Data

Identity documents, selfies, payment secrets, tokens and provider
secrets MUST NOT be logged.

The guest's access token is persisted only through `SecureTokenStore`
(`flutter_secure_storage`: Keychain / Keystore / WebCrypto-encrypted web
storage) so a session survives closing the app. On a cold start it is
re-validated against `GET /guest/auth/me`; a rejected token is cleared.
The session ends only on sign-out, a backend `401`, or that failed check.

Identity files are private backend resources. The mobile app should
receive only the access mechanism/API response required by the approved
backend workflow.

## 9. Localization

Arabic and English are first-class requirements.

All user-facing strings must be localizable. Layouts must support RTL
and LTR. Do not hard-code direction assumptions into reusable
components.

Server content (hotel/room names, taglines, highlights, facilities…) is
localized by Laravel to ONE language per request from the `X-Locale`
header, which `LocaleInterceptor` sends on every call from
`contentLanguageProvider` (the chosen app locale, Arabic by default).
Providers that hold server content `ref.watch(contentLanguageProvider)`
(or re-run on `ref.listen`) so a language switch refetches instead of
leaving the previous language on screen.

## 10. Navigation

Navigation should represent user journeys and backend state.

Examples:

``` text
Booking → Payment → Verification → Confirmation
```

and

``` text
Confirmed Stay → Check-in → Digital Access → In Stay
```

The app must handle deep links only where an approved feature requires
them.
