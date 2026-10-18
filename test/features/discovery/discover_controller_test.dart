import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/config/app_environment.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/core/presentation/ui_state.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/dummy_discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/discover_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/discovery_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';

/// The guest's reservations can't be read (offline, server down).
class _UnreachableReservations implements ReservationRepository {
  @override
  Future<List<Reservation>> list() async => throw const Failure(FailureKind.network);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('resolves to a success view with the greeting name and featured hotels',
      () async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(bootSession: completeSession()),
    );
    addTearDown(c.dispose);
    c.listen(discoverControllerProvider, (_, _) {});

    DiscoverView? view;
    for (int i = 0; i < 50; i++) {
      view = c.read(discoverControllerProvider).value;
      if (view?.greetingName != null) break;
      await Future<void>.delayed(Duration.zero);
    }

    expect(view, isNotNull);
    expect(view!.featuredHotels, isNotEmpty);
    expect(view.greetingName, 'Test'); // "Test Guest" → first name

    expect(
      discoverUiState(c.read(discoverControllerProvider)),
      isA<UiSuccess<DiscoverView>>(),
    );
  });

  test('featured hotels come through the repository', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(),
    );
    addTearDown(c.dispose);

    final hotels =
        await c.read(discoveryRepositoryProvider).featuredHotels();
    expect(hotels.first.id, 'oasis');
  });

  test('an unreadable upcoming stay leaves Home up, just without the card',
      () async {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        // Real-API mode, where Home reads the guest's own reservations.
        ...authOverrides(
          bootSession: completeSession(),
          config: const AppConfig(
            environment: AppEnvironment.development,
            apiBaseUrl: 'http://localhost',
            apiVersion: 'v1',
            useDummyData: false,
          ),
        ),
        discoveryDataSourceProvider
            .overrideWithValue(const DummyDiscoveryDataSource()),
        reservationRepositoryProvider
            .overrideWithValue(_UnreachableReservations()),
      ],
    );
    addTearDown(c.dispose);
    c.listen(discoverControllerProvider, (_, _) {});

    // Wait for the signed-in load (the greeting), when reservations are read.
    AsyncValue<DiscoverView> state = c.read(discoverControllerProvider);
    for (int i = 0; i < 100; i++) {
      if (state.hasError || state.value?.greetingName != null) break;
      await Future<void>.delayed(Duration.zero);
      state = c.read(discoverControllerProvider);
    }

    expect(state.hasError, isFalse, reason: '${state.error}');
    expect(state.value?.greetingName, 'Test');
    expect(state.value?.featuredHotels, isNotEmpty);
    expect(state.value?.upcomingStay, isNull);
  });
}
