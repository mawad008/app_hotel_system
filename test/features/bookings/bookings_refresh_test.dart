import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/bookings/presentation/state/bookings_providers.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/dummy_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/create_reservation_controller.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_detail_provider.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/test_config.dart';
import '../reservation/reservation_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 9, 41);

ProviderContainer _container() {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(testConfig),
      clockProvider.overrideWithValue(() => _now),
      reservationRepositoryProvider.overrideWithValue(
        ReservationRepositoryImpl(DummyReservationDataSource(clock: () => _now)),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(createReservationControllerProvider, (_, _) {});
  return container;
}

void main() {
  // The Bookings tab can stay mounted underneath the booking flow, which
  // keeps its autoDispose list alive — the listener below stands in for it.
  test('a completed booking shows on an already-loaded Bookings list', () async {
    final ProviderContainer c = _container();
    c.listen(bookingsListProvider, (_, _) {});
    final int before = (await c.read(bookingsListProvider.future)).length;

    await c.read(createReservationControllerProvider.notifier).submit(fakeRequest());
    final Reservation created =
        c.read(createReservationControllerProvider).reservationOrNull!;

    final List<Reservation> list = await c.read(bookingsListProvider.future);
    expect(list, hasLength(before + 1));
    expect(list.map((Reservation r) => r.id), contains(created.id));
  });

  test('refreshGuestReservations refetches the list and the given detail', () async {
    final ProviderContainer c = _container();
    c.listen(bookingsListProvider, (_, _) {});

    await c.read(createReservationControllerProvider.notifier).submit(fakeRequest());
    final String id = c.read(createReservationControllerProvider).reservationOrNull!.id;
    c.listen(reservationDetailProvider(id), (_, _) {});
    expect((await c.read(reservationDetailProvider(id).future)).status,
        ReservationStatus.pending);

    await c.read(reservationRepositoryProvider).cancel(id);
    refreshGuestReservations(c.invalidate, reservationId: id);

    expect((await c.read(reservationDetailProvider(id).future)).status,
        ReservationStatus.cancelled);
    final List<Reservation> list = await c.read(bookingsListProvider.future);
    expect(list.firstWhere((Reservation r) => r.id == id).status,
        ReservationStatus.cancelled);
  });
}
