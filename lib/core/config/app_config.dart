import 'app_environment.dart';

/// Immutable runtime configuration.
///
/// Values come from `--dart-define`s at build time so no environment detail or
/// secret is baked into source (mobile/docs/coding_rules.md §10). Nothing here is
/// secret: only the API host and feature flags. Tokens/credentials live in the
/// storage layer at runtime, never in config.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.useDummyData,
    this.singleHotelGroup = false,
  });

  /// Reads configuration from compile-time defines, with development defaults:
  ///
  /// ```
  /// flutter run \
  ///   --dart-define=APP_ENV=staging \
  ///   --dart-define=API_BASE_URL=https://staging.example.com \
  ///   --dart-define=USE_DUMMY_DATA=false
  /// ```
  factory AppConfig.fromEnvironment() {
    const String env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    // No override → the hosted backend ([defaultBaseUrl]) on every platform.
    // A local Laravel can still be targeted with e.g.:
    //   --dart-define=API_BASE_URL=http://10.0.2.2:8000
    // The value is combined with `/api/v1` by [apiRoot].
    const String overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final String baseUrl = overrideBaseUrl.isEmpty ? defaultBaseUrl : overrideBaseUrl;
    // Real integration: --dart-define=USE_DUMMY_DATA=false. As of the final
    // mobile↔backend integration pass, every feature's `Api*DataSource` is a
    // real implementation against the guest API (auth, discovery,
    // reservations, payment reads, identity status, check-in/access, service
    // catalogue/orders, folio/checkout/invoice, loyalty reads/redeem,
    // reviews). Documented, narrower gaps remain and throw
    // `NotImplementedInPhaseException` rather than guessing: payment `hold`
    // is backend-blocked pending an approved deposit-amount rule; loyalty
    // has no guest-triggerable `earn`;
    // stay-services has no guest cancel; discovery has no "featured hotels"
    // or "upcoming stay" concept server-side (see
    // md/integration-contract-matrix.md).
    const bool useDummy = bool.fromEnvironment('USE_DUMMY_DATA', defaultValue: false);
    // Demo/QA flag: render the single-hotel Home variant (`اكتشف {hotel}` +
    // `استكشف الغرف`). The real group size comes from the backend catalogue;
    // this just lets the variant be walked with dummy data.
    const bool singleHotel =
        bool.fromEnvironment('SINGLE_HOTEL', defaultValue: false);

    return AppConfig(
      environment: AppEnvironment.fromName(env),
      apiBaseUrl: baseUrl,
      apiVersion: 'v1',
      useDummyData: useDummy,
      singleHotelGroup: singleHotel,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String apiVersion;
  final bool useDummyData;

  /// When `true` the group operates one hotel — the Home screen shows the
  /// single-hotel layout (`docs/mobile-discover-book.md`).
  final bool singleHotelGroup;

  /// Fully-qualified API root, e.g. `https://api.example.com/api/v1`
  /// (mobile/docs/architecture.md §5).
  String get apiRoot => '$apiBaseUrl/api/$apiVersion';

  bool get isProduction => environment == AppEnvironment.production;

  /// Hosted Laravel API used when `API_BASE_URL` isn't overridden via
  /// `--dart-define`. Not `hotel.webstdy.com` — that host is the Nuxt web
  /// frontend (its `/api/*` returns the SPA HTML / 405), and it calls this
  /// same `admin.` host itself. HTTPS: plain `http` 301-redirects, which would
  /// drop POST bodies and is blocked by Android/iOS cleartext policy.
  static const String defaultBaseUrl = 'https://admin.hotel.webstdy.com';
}
