import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/dummy_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_result.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';
import 'package:hotel_guest_app/features/payment/presentation/state/payment_controller.dart';
import 'package:hotel_guest_app/features/payment/presentation/state/payment_providers.dart';

import 'payment_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 9, 41);

ProviderContainer _container({DummyPaymentDataSource? source}) {
  final ds = source ?? DummyPaymentDataSource(clock: () => _now);
  final c = ProviderContainer(overrides: <Override>[
    paymentRepositoryProvider.overrideWithValue(PaymentRepositoryImpl(ds)),
  ]);
  addTearDown(c.dispose);
  c.listen(paymentControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('idle → submitting → done carrying the resolved result', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = _container();
    expect(c.read(paymentControllerProvider), isA<PaymentActionIdle>());

    await c
        .read(paymentControllerProvider.notifier)
        .submit(fakeHoldRequest(reservationId: id));

    final state = c.read(paymentControllerProvider);
    expect(state, isA<PaymentActionDone>());
    expect(state.resultOrNull!.outcome, PaymentOutcome.held);
    expect(state.resultOrNull!.status, PaymentStatus.holdActive);
  });

  test('a second submit of a successful request is ignored', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = _container();
    final n = c.read(paymentControllerProvider.notifier);

    await n.submit(fakeHoldRequest(reservationId: id));
    final first = c.read(paymentControllerProvider).resultOrNull;
    await n.submit(fakeHoldRequest(reservationId: id));
    final second = c.read(paymentControllerProvider).resultOrNull;

    expect(identical(first, second), isTrue);
  });

  test('a submit while one is in flight is a no-op', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = _container();
    final n = c.read(paymentControllerProvider.notifier);

    final f = n.submit(fakeHoldRequest(reservationId: id));
    await n.submit(fakeHoldRequest(reservationId: id));
    await f;

    expect(c.read(paymentControllerProvider), isA<PaymentActionDone>());
  });

  test('an infrastructure failure is surfaced and a retry succeeds', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final ds = DummyPaymentDataSource(clock: () => _now)
      ..failWith = const NetworkException();
    final c = _container(source: ds);
    final n = c.read(paymentControllerProvider.notifier);

    await n.submit(fakeHoldRequest(reservationId: id));
    expect(c.read(paymentControllerProvider), isA<PaymentActionFailed>());

    ds.failWith = null;
    await n.submit(fakeHoldRequest(reservationId: id));
    expect(c.read(paymentControllerProvider), isA<PaymentActionDone>());
  });

  test('a business decline (HOLD_FAILED) is a retryable done, then recovers',
      () async {
    final id = reservationIdForScenario(DummyHoldScenario.failsThenSucceeds);
    final c = _container();
    final n = c.read(paymentControllerProvider.notifier);

    await n.submit(fakeHoldRequest(reservationId: id));
    var state = c.read(paymentControllerProvider);
    expect(state, isA<PaymentActionDone>());
    expect(state.resultOrNull!.outcome, PaymentOutcome.failed);

    // A retry of the same request is allowed because the outcome was not a
    // success.
    await n.submit(fakeHoldRequest(reservationId: id));
    state = c.read(paymentControllerProvider);
    expect(state.resultOrNull!.outcome, PaymentOutcome.held);
  });

  test('the request-scoped idempotency key is stable across submits', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = _container();
    final n = c.read(paymentControllerProvider.notifier);
    await n.submit(fakeHoldRequest(reservationId: id));
    final r1 = (c.read(paymentControllerProvider) as PaymentActionDone).request;
    await n.submit(fakeHoldRequest(reservationId: id));
    expect(r1.idempotencyKey,
        fakeHoldRequest(reservationId: id).idempotencyKey);
  });

  test('a newer request supersedes an in-flight older one', () async {
    final a = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = _container();
    final n = c.read(paymentControllerProvider.notifier);

    final older = n.submit(fakeHoldRequest(reservationId: a, amount: 100));
    final newer = n.submit(fakeHoldRequest(reservationId: a, amount: 200));
    await Future.wait(<Future<void>>[older, newer]);

    final state = c.read(paymentControllerProvider);
    expect(state, isA<PaymentActionDone>());
    expect((state as PaymentActionDone).request.amount.amount, 200);
  });

  test('reset returns to idle', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = _container();
    final n = c.read(paymentControllerProvider.notifier);
    await n.submit(fakeHoldRequest(reservationId: id));
    n.reset();
    expect(c.read(paymentControllerProvider), isA<PaymentActionIdle>());
  });
}
