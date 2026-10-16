import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_state.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/dummy_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/data/models/reservation_models.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/create_reservation_controller.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/test_config.dart';
import 'reservation_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 9, 41);

/// Records the `Idempotency-Key` each create would send.
class _KeyRecordingSource extends DummyReservationDataSource {
  _KeyRecordingSource() : super(clock: () => _now);

  final List<String> keys = <String>[];

  @override
  Future<ReservationModel> create(CreateReservationRequest request) {
    keys.add(request.serverIdempotencyKey);
    return super.create(request);
  }
}

ProviderContainer _container({DummyReservationDataSource? source}) {
  final DummyReservationDataSource ds =
      source ?? DummyReservationDataSource(clock: () => _now);
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(testConfig),
      clockProvider.overrideWithValue(() => _now),
      reservationRepositoryProvider.overrideWithValue(
        ReservationRepositoryImpl(ds),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(createReservationControllerProvider, (_, _) {});
  return container;
}

void main() {
  test('idle → submitting → done, carrying the created reservation', () async {
    final ProviderContainer c = _container();
    expect(c.read(createReservationControllerProvider),
        isA<CreateReservationIdle>());

    await c
        .read(createReservationControllerProvider.notifier)
        .submit(fakeRequest());

    final state = c.read(createReservationControllerProvider);
    expect(state, isA<CreateReservationDone>());
    expect(state.reservationOrNull, isNotNull);
    expect(state.reservationOrNull!.reference, startsWith('RSV-'));
  });

  test('a second submit of the same request after success is ignored',
      () async {
    final ProviderContainer c = _container();
    final notifier = c.read(createReservationControllerProvider.notifier);

    await notifier.submit(fakeRequest());
    final first = c.read(createReservationControllerProvider).reservationOrNull;

    await notifier.submit(fakeRequest());
    final second = c.read(createReservationControllerProvider).reservationOrNull;

    expect(identical(first, second), isTrue);
  });

  test('a submit while one is in flight is a no-op', () async {
    final ProviderContainer c = _container();
    final notifier = c.read(createReservationControllerProvider.notifier);

    final Future<void> inFlight = notifier.submit(fakeRequest());
    // Second call before the first resolves.
    await notifier.submit(fakeRequest());
    await inFlight;

    expect(c.read(createReservationControllerProvider),
        isA<CreateReservationDone>());
  });

  test('failure is surfaced and a retry succeeds', () async {
    final DummyReservationDataSource ds =
        DummyReservationDataSource(clock: () => _now)
          ..failWith = const NetworkException();
    final ProviderContainer c = _container(source: ds);
    final notifier = c.read(createReservationControllerProvider.notifier);

    await notifier.submit(fakeRequest());
    expect(c.read(createReservationControllerProvider),
        isA<CreateReservationFailed>());

    ds.failWith = null;
    await notifier.submit(fakeRequest()); // retry — allowed from a failed state
    expect(c.read(createReservationControllerProvider),
        isA<CreateReservationDone>());
  });

  test('a newer request supersedes an in-flight older one', () async {
    final ProviderContainer c = _container();
    final notifier = c.read(createReservationControllerProvider.notifier);

    final Future<void> older = notifier.submit(fakeRequest());
    // Force a different request while the first is in flight.
    final Future<void> newer =
        notifier.submit(fakeRequest(guestReference: '+966500000000'));
    await Future.wait(<Future<void>>[older, newer]);

    final state = c.read(createReservationControllerProvider);
    expect(state, isA<CreateReservationDone>());
    expect(
      (state as CreateReservationDone).request.guestReference,
      '+966500000000',
    );
  });

  test('reset returns to idle', () async {
    final ProviderContainer c = _container();
    final notifier = c.read(createReservationControllerProvider.notifier);
    await notifier.submit(fakeRequest());
    notifier.reset();
    expect(c.read(createReservationControllerProvider),
        isA<CreateReservationIdle>());
  });

  test('a retry of the same booking after a failure reuses the attempt key',
      () async {
    final _KeyRecordingSource ds = _KeyRecordingSource()
      ..failWith = const NetworkException();
    final ProviderContainer c = _container(source: ds);
    final notifier = c.read(createReservationControllerProvider.notifier);

    await notifier.submit(fakeRequest());
    notifier.reset();
    ds.failWith = null;
    await notifier.submit(fakeRequest());

    expect(ds.keys, hasLength(2));
    expect(ds.keys[0], ds.keys[1]);
    expect(ds.keys[0], matches(RegExp(r'^rsv-[0-9a-f]{32}$')));
  });

  test('booking the same criteria again after a success is a new attempt',
      () async {
    final _KeyRecordingSource ds = _KeyRecordingSource();
    final ProviderContainer c = _container(source: ds);
    final notifier = c.read(createReservationControllerProvider.notifier);

    await notifier.submit(fakeRequest());
    notifier.reset();
    await notifier.submit(fakeRequest());

    expect(ds.keys, hasLength(2));
    expect(ds.keys[0], isNot(ds.keys[1]));
  });

  test('different criteria get a different attempt key', () async {
    final _KeyRecordingSource ds = _KeyRecordingSource()
      ..failWith = const NetworkException();
    final ProviderContainer c = _container(source: ds);
    final notifier = c.read(createReservationControllerProvider.notifier);

    await notifier.submit(fakeRequest());
    await notifier.submit(fakeRequest(guestReference: '+966500000000'));

    expect(ds.keys[0], isNot(ds.keys[1]));
  });

  test('signing out forgets a created booking, so the next guest on this '
      'phone can never reopen it', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(testConfig),
        clockProvider.overrideWithValue(() => _now),
        reservationRepositoryProvider.overrideWithValue(
          ReservationRepositoryImpl(
            DummyReservationDataSource(clock: () => _now),
          ),
        ),
        authRepositoryProvider.overrideWithValue(
          TestAuthRepository(bootSession: completeSession()),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(c.dispose);
    c.listen(createReservationControllerProvider, (_, _) {});
    c.listen(authControllerProvider, (_, _) {});
    for (int i = 0; i < 50 && c.read(authControllerProvider) is! Authenticated; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(c.read(authControllerProvider), isA<Authenticated>());

    await c
        .read(createReservationControllerProvider.notifier)
        .submit(fakeRequest());
    expect(
      c.read(createReservationControllerProvider),
      isA<CreateReservationDone>(),
    );

    await c.read(authControllerProvider.notifier).signOut();
    expect(
      c.read(createReservationControllerProvider),
      isA<CreateReservationIdle>(),
    );
  });

  test('forget() drops the remembered booking only when it is the one '
      'cancelled', () async {
    final ProviderContainer c = _container();
    final notifier = c.read(createReservationControllerProvider.notifier);
    await notifier.submit(fakeRequest());
    final String id =
        c.read(createReservationControllerProvider).reservationOrNull!.id;

    notifier.forget('some-other-booking');
    expect(
      c.read(createReservationControllerProvider),
      isA<CreateReservationDone>(),
    );

    notifier.forget(id);
    expect(
      c.read(createReservationControllerProvider),
      isA<CreateReservationIdle>(),
    );
  });
}
