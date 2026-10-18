import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;

import 'app_environment.dart';

/// Immutable runtime configuration.
///
/// Values come from `--dart-define`s at build time (mobile/docs/coding_rules.md
/// §10). Nothing here is secret: only the API host and feature flags.
/// Tokens/credentials live in the storage layer at runtime, never in config.
/// The one host in source is [productionBaseUrl], the default when no
/// `API_BASE_URL` is passed.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.useDummyData,
    this.singleHotelGroup = false,
  });

  /// The hosted Laravel API — the same value as `config/production.json`,
  /// which a test keeps in step — used whenever `API_BASE_URL` isn't passed,
  /// in every build mode.
  ///
  /// So a store build can never point at a developer's machine: an iOS
  /// archive made in Xcode after `flutter pub get` (which resets the defines)
  /// once reached App Review calling `127.0.0.1` and showing "you appear to be
  /// offline" on launch. Not `hotel.webstdy.com` — that host is the Nuxt web
  /// frontend (its `/api/*` returns the SPA HTML / 405). HTTPS: plain `http`
  /// 301-redirects, which drops POST bodies and is blocked by the Android/iOS
  /// cleartext policy.
  static const String productionBaseUrl = 'https://admin.hotel.webstdy.com';

  /// Reads configuration from compile-time defines:
  ///
  /// ```
  /// flutter run \
  ///   --dart-define=APP_ENV=staging \
  ///   --dart-define=API_BASE_URL=https://staging.example.com \
  ///   --dart-define=USE_DUMMY_DATA=false
  /// ```
  ///
  /// Store builds pass `--dart-define-from-file=config/production.json`; see
  /// [AppConfig.resolve] for what applies when a define is missing.
  factory AppConfig.fromEnvironment() => AppConfig.resolve(
    release: kReleaseMode,
    appEnv: const String.fromEnvironment('APP_ENV'),
    // Combined with `/api/v1` by [apiRoot]. A local Laravel can still be
    // targeted with e.g.:
    //   --dart-define=API_BASE_URL=http://10.0.2.2:8000   (Android emulator)
    //   --dart-define=API_BASE_URL=http://<your-Mac-LAN-IP>:8000
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
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
    useDummyData: const bool.fromEnvironment('USE_DUMMY_DATA'),
    // Demo/QA flag: render the single-hotel Home variant (`اكتشف {hotel}`
    // + `استكشف الغرف`). The real group size comes from the backend
    // catalogue; this just lets the variant be walked with dummy data.
    singleHotelGroup: const bool.fromEnvironment('SINGLE_HOTEL'),
  );

  /// [AppConfig.fromEnvironment]'s rules, with the defines passed in so tests
  /// can run both build modes. A define that was passed always wins. Without
  /// one the API is [productionBaseUrl], and the environment is `production`
  /// in a release build, `development` otherwise.
  @visibleForTesting
  factory AppConfig.resolve({
    required bool release,
    String appEnv = '',
    String apiBaseUrl = '',
    bool useDummyData = false,
    bool singleHotelGroup = false,
  }) {
    final String env = appEnv.isNotEmpty
        ? appEnv
        : (release ? 'production' : 'development');
    final String baseUrl = apiBaseUrl.isNotEmpty
        ? apiBaseUrl
        : productionBaseUrl;
    return AppConfig(
      environment: AppEnvironment.fromName(env),
      apiBaseUrl: baseUrl,
      apiVersion: 'v1',
      useDummyData: useDummyData,
      singleHotelGroup: singleHotelGroup,
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
}
