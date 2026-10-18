import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/dummy_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout_status.dart';
import 'package:hotel_guest_app/features/checkout/presentation/state/checkout_controller.dart';
import 'package:hotel_guest_app/features/checkout/presentation/state/checkout_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import 'checkout_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 11);

class _ReservationRepo implements ReservationRepository {
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation();
  @override
  Future<Reservation> getById(String id) async => fakeReservation(id: id);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}

ProviderContainer _container({DummyCheckoutDataSource? source}) {
  final ds = source ?? DummyCheckoutDataSource(clock: () => _now);
  final c = ProviderContainer(overrides: <Override>[
    checkoutRepositoryProvider
        .overrideWithValue(CheckoutRepositoryImpl(ds)),
    reservationRepositoryProvider.overrideWithValue(_ReservationRepo()),
  ]);
  addTearDown(c.dispose);
  c.listen(checkoutControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('idle → submitting → done with a completed outcome + invoice', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final c = _container();
    expect(c.read(checkoutControllerProvider), isA<CheckoutIdle>());

    await c.read(checkoutControllerProvider.notifier).submit(id);

    final state = c.read(checkoutControllerProvider);
    expect(state, isA<CheckoutDone>());
    expect(state.resultOrNull!.outcome, CheckoutOutcome.completed);
    expect(state.resultOrNull!.invoice, isNotNull);
  });

  test('a second submit of a completed checkout is ignored', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final c = _container();
    final n = c.read(checkoutControllerProvider.notifier);
    await n.submit(id);
    final first = c.read(checkoutControllerProvider).resultOrNull;
    await n.submit(id);
    final second = c.read(checkoutControllerProvider).resultOrNull;
    expect(identical(first, second), isTrue);
  });

  test('a submit while one is in flight is a no-op', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final c = _container();
    final n = c.read(checkoutControllerProvider.notifier);
    final f = n.submit(id);
    await n.submit(id);
    await f;
    expect(c.read(checkoutControllerProvider), isA<CheckoutDone>());
  });

  test('a settlement failure is a retryable done, then a retry completes',
      () async {
    final id =
        reservationIdForSettlement(DummySettlementScenario.failsThenSettles);
    final c = _container();
    final n = c.read(checkoutControllerProvider.notifier);

    await n.submit(id);
    var state = c.read(checkoutControllerProvider);
    expect(state, isA<CheckoutDone>());
    expect(state.resultOrNull!.outcome, CheckoutOutcome.settlementFailed);

    await n.submit(id); // retry — stable key, re-attempts
    state = c.read(checkoutControllerProvider);
    expect(state.resultOrNull!.outcome, CheckoutOutcome.completed);
  });

  test('a pending settlement is surfaced without claiming completion',
      () async {
    final id = reservationIdForSettlement(DummySettlementScenario.staysPending);
    final c = _container();
    await c.read(checkoutControllerProvider.notifier).submit(id);
    final state = c.read(checkoutControllerProvider);
    expect(state.resultOrNull!.outcome, CheckoutOutcome.settlementPending);
    expect(state.resultOrNull!.checkout.status,
        CheckoutStatus.awaitingSettlement);
  });

  test('an infrastructure failure is surfaced and a retry recovers', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final ds = DummyCheckoutDataSource(clock: () => _now)
      ..failWith = const NetworkException();
    final c = _container(source: ds);
    final n = c.read(checkoutControllerProvider.notifier);

    await n.submit(id);
    expect(c.read(checkoutControllerProvider), isA<CheckoutFailed>());

    ds.failWith = null;
    await n.submit(id);
    expect(c.read(checkoutControllerProvider), isA<CheckoutDone>());
  });

  test('the idempotency key is stable across submits', () {
    const a = CheckoutRequest(reservationId: 'r1');
    const b = CheckoutRequest(reservationId: 'r1');
    expect(a.idempotencyKey, b.idempotencyKey);
  });

  test('a newer reservation supersedes an in-flight older one', () async {
    final a = reservationIdForSettlement(DummySettlementScenario.settles);
    final c = _container();
    final n = c.read(checkoutControllerProvider.notifier);
    final older = n.submit(a);
    final newer = n.submit('$a-b');
    await Future.wait(<Future<void>>[older, newer]);
    final state = c.read(checkoutControllerProvider);
    expect((state as CheckoutDone).request.reservationId, '$a-b');
  });

  test('reset returns to idle', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final c = _container();
    final n = c.read(checkoutControllerProvider.notifier);
    await n.submit(id);
    n.reset();
    expect(c.read(checkoutControllerProvider), isA<CheckoutIdle>());
  });
}
