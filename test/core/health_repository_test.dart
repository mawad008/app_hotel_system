import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/config/app_environment.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/core/health/data/api_health_data_source.dart';
import 'package:hotel_guest_app/core/health/data/dummy_health_data_source.dart';
import 'package:hotel_guest_app/core/health/data/health_repository_impl.dart';
import 'package:hotel_guest_app/core/health/domain/backend_health.dart';
import 'package:hotel_guest_app/core/health/domain/health_repository.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/security/token_store.dart';

import '../support/test_config.dart';

void main() {
  group('HealthRepositoryImpl + dummy data source', () {
    test('returns ok without any UI or HTTP coupling', () async {
      final HealthRepository repo =
          HealthRepositoryImpl(DummyHealthDataSource());
      final BackendHealth health = await repo.check();
      expect(health.status, HealthStatus.ok);
    });

    test('propagates degraded / down states from the source', () async {
      final repo = HealthRepositoryImpl(
        DummyHealthDataSource(nextStatus: HealthStatus.degraded),
      );
      expect((await repo.check()).status, HealthStatus.degraded);
    });

    test('maps a thrown exception to a Failure', () async {
      final repo = HealthRepositoryImpl(
        DummyHealthDataSource(error: const NetworkException()),
      );
      await expectLater(
        repo.check(),
        throwsA(isA<Failure>().having((Failure f) => f.kind, 'kind', FailureKind.network)),
      );
    });
  });

  test('API data source is a documented Phase 0 stub', () async {
    final ApiClient client = ApiClient(config: testConfig, tokenStore: _NoTokens());
    await expectLater(
      ApiHealthDataSource(client).fetchStatus(),
      throwsA(isA<NotImplementedInPhaseException>()),
    );
  });

  test('DI selects the dummy source when config.useDummyData is true', () {
    final container = ProviderContainer(
      overrides: <Override>[appConfigProvider.overrideWithValue(testConfig)],
    );
    addTearDown(container.dispose);
    expect(
      container.read(healthDataSourceProvider),
      isA<DummyHealthDataSource>(),
    );
  });

  test('DI selects the API source when config.useDummyData is false', () {
    const AppConfig apiConfig = AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://staging.example.com',
      apiVersion: 'v1',
      useDummyData: false,
    );
    final container = ProviderContainer(
      overrides: <Override>[appConfigProvider.overrideWithValue(apiConfig)],
    );
    addTearDown(container.dispose);
    expect(
      container.read(healthDataSourceProvider),
      isA<ApiHealthDataSource>(),
    );
  });
}

class _NoTokens implements TokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> writeAccessToken(String token) async {}
  @override
  Future<String?> readProfileSnapshot() async => null;
  @override
  Future<void> writeProfileSnapshot(String snapshot) async {}
}
