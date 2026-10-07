import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../health/data/api_health_data_source.dart';
import '../health/data/dummy_health_data_source.dart';
import '../health/data/health_data_source.dart';
import '../health/data/health_repository_impl.dart';
import '../health/domain/health_repository.dart';
import '../localization/content_language_provider.dart';
import '../network/api_client.dart';
import '../network/session_events.dart';
import '../security/in_memory_token_store.dart';
import '../security/token_store.dart';

/// Application configuration. Overridden in `bootstrap()` with the value built
/// from `--dart-define`s; the throwing default guarantees it is never used
/// unconfigured.
final appConfigProvider = Provider<AppConfig>(
  (Ref ref) => throw StateError('appConfigProvider must be overridden in bootstrap()'),
);

/// Access-token storage. In-memory by default (tests); `bootstrap()` overrides
/// it with the persistent `SecureTokenStore` for the real app.
final tokenStoreProvider = Provider<TokenStore>((Ref ref) => InMemoryTokenStore());

/// Shared HTTP client. Built once from config + token store.
final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    // Read per request (not watched) so a language switch never rebuilds the
    // client — and with it every repository and in-flight controller.
    languageCode: () => ref.read(contentLanguageProvider),
    sessionEvents: ref.watch(sessionEventsProvider),
  );
});

/// "The backend rejected our token" events from [ApiClient] — the auth
/// feature listens and ends the session.
final sessionEventsProvider = Provider<SessionEvents>((Ref ref) {
  final SessionEvents events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

/// Selects the health data source by configuration — the UI never sees this
/// choice (mobile/docs/README.md — "Development Strategy").
final healthDataSourceProvider = Provider<HealthDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyHealthDataSource()
      : ApiHealthDataSource(ref.watch(apiClientProvider));
});

final healthRepositoryProvider = Provider<HealthRepository>(
  (Ref ref) => HealthRepositoryImpl(ref.watch(healthDataSourceProvider)),
);
