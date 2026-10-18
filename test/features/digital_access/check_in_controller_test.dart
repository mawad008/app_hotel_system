import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/dummy_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/data/repositories/digital_access_repository_impl.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/check_in.dart';
import 'package:hotel_guest_app/features/digital_access/presentation/state/check_in_controller.dart';
import 'package:hotel_guest_app/features/digital_access/presentation/state/digital_access_providers.dart';

import 'digital_access_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 14);

ProviderContainer _container({DummyDigitalAccessDataSource? source}) {
  final ds = source ?? DummyDigitalAccessDataSource(clock: () => _now);
  final c = ProviderContainer(overrides: <Override>[
    digitalAccessRepositoryProvider
        .overrideWithValue(DigitalAccessRepositoryImpl(ds)),
  ]);
  addTearDown(c.dispose);
  c.listen(checkInControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('idle → submitting → done carrying the resolved grant', () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final c = _container();
    expect(c.read(checkInControllerProvider), isA<CheckInIdle>());

    await c
        .read(checkInControllerProvider.notifier)
        .submit(CheckInRequest(reservationId: id));

    final state = c.read(checkInControllerProvider);
    expect(state, isA<CheckInDone>());
    expect(state.resultOrNull!.outcome, CheckInOutcome.checkedIn);
  });

  test('a second submit of a successful check-in is ignored', () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final c = _container();
    final n = c.read(checkInControllerProvider.notifier);
    await n.submit(CheckInRequest(reservationId: id));
    final first = c.read(checkInControllerProvider).resultOrNull;
    await n.submit(CheckInRequest(reservationId: id));
    final second = c.read(checkInControllerProvider).resultOrNull;
    expect(identical(first, second), isTrue);
  });

  test('a submit while one is in flight is a no-op', () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final c = _container();
    final n = c.read(checkInControllerProvider.notifier);
    final f = n.submit(CheckInRequest(reservationId: id));
    await n.submit(CheckInRequest(reservationId: id));
    await f;
    expect(c.read(checkInControllerProvider), isA<CheckInDone>());
  });

  test('an issue failure is a retryable done, and a retry then succeeds',
      () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.failsThenActive);
    final c = _container();
    final n = c.read(checkInControllerProvider.notifier);

    await n.submit(CheckInRequest(reservationId: id));
    var state = c.read(checkInControllerProvider);
    expect(state, isA<CheckInDone>());
    expect(state.resultOrNull!.outcome, CheckInOutcome.issueFailed);

    await n.submit(CheckInRequest(reservationId: id)); // retry — same request
    state = c.read(checkInControllerProvider);
    expect(state.resultOrNull!.outcome, CheckInOutcome.checkedIn);
  });

  test('an infrastructure failure is surfaced and a retry recovers', () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final ds = DummyDigitalAccessDataSource(clock: () => _now)
      ..failWith = const NetworkException();
    final c = _container(source: ds);
    final n = c.read(checkInControllerProvider.notifier);

    await n.submit(CheckInRequest(reservationId: id));
    expect(c.read(checkInControllerProvider), isA<CheckInFailed>());

    ds.failWith = null;
    await n.submit(CheckInRequest(reservationId: id));
    expect(c.read(checkInControllerProvider), isA<CheckInDone>());
  });

  test('a newer request supersedes an in-flight older one', () async {
    final a = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final c = _container();
    final n = c.read(checkInControllerProvider.notifier);

    final older = n.submit(CheckInRequest(reservationId: a));
    final newer = n.submit(CheckInRequest(reservationId: '$a-b'));
    await Future.wait(<Future<void>>[older, newer]);

    final state = c.read(checkInControllerProvider);
    expect(state, isA<CheckInDone>());
    expect((state as CheckInDone).request.reservationId, '$a-b');
  });

  test('reset returns to idle', () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final c = _container();
    final n = c.read(checkInControllerProvider.notifier);
    await n.submit(CheckInRequest(reservationId: id));
    n.reset();
    expect(c.read(checkInControllerProvider), isA<CheckInIdle>());
  });
}
