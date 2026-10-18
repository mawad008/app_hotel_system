import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/dummy_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/data/repositories/stay_services_repository_impl.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order_status.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/service_request_controller.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/stay_services_providers.dart';

import 'stay_services_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 12);

ProviderContainer _container({DummyStayServicesDataSource? source}) {
  final ds = source ?? DummyStayServicesDataSource(clock: () => _now);
  final c = ProviderContainer(overrides: <Override>[
    stayServicesRepositoryProvider
        .overrideWithValue(StayServicesRepositoryImpl(ds)),
  ]);
  addTearDown(c.dispose);
  c.listen(serviceRequestControllerProvider, (_, _) {});
  return c;
}

void main() {
  group('ServiceRequestController', () {
    test('idle → submitting → done carrying the created order', () async {
      final c = _container();
      expect(c.read(serviceRequestControllerProvider), isA<ServiceRequestIdle>());
      await c
          .read(serviceRequestControllerProvider.notifier)
          .submit(fakeServiceRequest());
      final state = c.read(serviceRequestControllerProvider);
      expect(state, isA<ServiceRequestDone>());
      expect(state.orderOrNull!.status, ServiceOrderStatus.requested);
      expect(state.orderOrNull!.reference, startsWith('SR-'));
    });

    test('a second submit of the same request is ignored (no double order)',
        () async {
      final c = _container();
      final n = c.read(serviceRequestControllerProvider.notifier);
      await n.submit(fakeServiceRequest());
      final first = c.read(serviceRequestControllerProvider).orderOrNull;
      await n.submit(fakeServiceRequest());
      final second = c.read(serviceRequestControllerProvider).orderOrNull;
      expect(identical(first, second), isTrue);
    });

    test('a submit while one is in flight is a no-op', () async {
      final c = _container();
      final n = c.read(serviceRequestControllerProvider.notifier);
      final f = n.submit(fakeServiceRequest());
      await n.submit(fakeServiceRequest());
      await f;
      expect(
          c.read(serviceRequestControllerProvider), isA<ServiceRequestDone>());
    });

    test('failure is surfaced and a retry succeeds', () async {
      final ds = DummyStayServicesDataSource(clock: () => _now)
        ..failWith = const NetworkException();
      final c = _container(source: ds);
      final n = c.read(serviceRequestControllerProvider.notifier);
      await n.submit(fakeServiceRequest());
      expect(c.read(serviceRequestControllerProvider),
          isA<ServiceRequestFailed>());
      ds.failWith = null;
      await n.submit(fakeServiceRequest());
      expect(
          c.read(serviceRequestControllerProvider), isA<ServiceRequestDone>());
    });

    test('a newer request supersedes an in-flight older one', () async {
      final c = _container();
      final n = c.read(serviceRequestControllerProvider.notifier);
      final older = n.submit(fakeServiceRequest(quantity: 1));
      final newer = n.submit(fakeServiceRequest(quantity: 2));
      await Future.wait(<Future<void>>[older, newer]);
      final state = c.read(serviceRequestControllerProvider);
      expect((state as ServiceRequestDone).request.quantity, 2);
    });
  });

  group('CancelOrderController (per-order family)', () {
    test('cancels a still-requested order', () async {
      final rid = reservationIdWithCancellableOrder();
      final c = _container();
      final order = await c
          .read(stayServicesRepositoryProvider)
          .requestService(fakeServiceRequest(reservationId: rid));
      final key = (reservationId: rid, orderId: order.id);
      c.listen(cancelOrderControllerProvider(key), (_, _) {});

      await c.read(cancelOrderControllerProvider(key).notifier).cancel();
      final state = c.read(cancelOrderControllerProvider(key));
      expect(state, isA<CancelOrderDone>());
      expect((state as CancelOrderDone).order.status,
          ServiceOrderStatus.cancelled);
    });

    test('a rejected cancel (already actioned) surfaces a conflict failure',
        () async {
      final rid = reservationIdWithConfirmedOrder();
      final c = _container();
      final order = await c
          .read(stayServicesRepositoryProvider)
          .requestService(fakeServiceRequest(reservationId: rid));
      final key = (reservationId: rid, orderId: order.id);
      c.listen(cancelOrderControllerProvider(key), (_, _) {});

      await c.read(cancelOrderControllerProvider(key).notifier).cancel();
      expect(c.read(cancelOrderControllerProvider(key)),
          isA<CancelOrderFailed>());
    });

    test('two orders never share cancel state', () async {
      final rid = reservationIdWithCancellableOrder();
      final c = _container();
      final o1 = await c
          .read(stayServicesRepositoryProvider)
          .requestService(fakeServiceRequest(reservationId: rid, quantity: 1));
      final o2 = await c
          .read(stayServicesRepositoryProvider)
          .requestService(fakeServiceRequest(reservationId: rid, quantity: 2));
      final k1 = (reservationId: rid, orderId: o1.id);
      final k2 = (reservationId: rid, orderId: o2.id);
      c.listen(cancelOrderControllerProvider(k1), (_, _) {});
      c.listen(cancelOrderControllerProvider(k2), (_, _) {});
      expect(c.read(cancelOrderControllerProvider(k1)), isA<CancelOrderIdle>());
      expect(c.read(cancelOrderControllerProvider(k2)), isA<CancelOrderIdle>());
    });
  });
}
