import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/dummy_service_review_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/data/repositories/service_review_repository_impl.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/hotel_service.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order_status.dart';
import 'package:hotel_guest_app/features/stay_services/domain/repositories/stay_services_repository.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/service_review_providers.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/stay_services_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

final DateTime _now = DateTime(2026, 9, 12, 10);

/// The first order id (`SO0`, `SO1`, …) mapping to [scenario] — mirrors
/// `reviewScenarioId` in the reviews feature's own test support.
String _scenarioOrderId(DummyServiceReviewScenario scenario) {
  for (int i = 0; i < 4000; i++) {
    final String id = 'SO$i';
    if (DummyServiceReviewDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no order id found for $scenario');
}

ServiceOrder _fulfilledOrder(String id) => ServiceOrder(
      id: id,
      reservationId: 'res-1',
      serviceId: 'svc-1',
      serviceName: const LocalizedText(ar: 'خدمة الغرف', en: 'Room Service'),
      quantity: 1,
      unitPrice: const Money(amount: 40),
      totalAmount: const Money(amount: 40),
      status: ServiceOrderStatus.fulfilled,
      requestedAt: _now.subtract(const Duration(hours: 2)),
      confirmedAt: _now.subtract(const Duration(hours: 1, minutes: 30)),
      fulfilledAt: _now.subtract(const Duration(minutes: 30)),
    );

class _FakeStayServicesRepository implements StayServicesRepository {
  _FakeStayServicesRepository(this.order);
  final ServiceOrder order;

  @override
  Future<ServiceCatalogue> catalogue(String hotelId) async => ServiceCatalogue.empty;

  @override
  Future<List<ServiceOrder>> ordersFor(String reservationId) async => <ServiceOrder>[order];

  @override
  Future<ServiceOrder> orderById(String reservationId, String orderId) async => order;

  @override
  Future<ServiceOrder> requestService(CreateServiceRequest request) async {
    throw UnimplementedError('not used in this test');
  }

  @override
  Future<ServiceOrder> cancelOrder(String reservationId, String orderId) async {
    throw UnimplementedError('not used in this test');
  }
}

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<ProviderContainer> _openServiceReview(
  WidgetTester tester,
  String orderId, {
  Locale? locale,
}) async {
  final ds = DummyServiceReviewDataSource(clock: () => _now);
  final ProviderContainer c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      serviceReviewDataSourceProvider.overrideWithValue(ds),
      serviceReviewRepositoryProvider
          .overrideWithValue(ServiceReviewRepositoryImpl(ds)),
      stayServicesRepositoryProvider
          .overrideWithValue(_FakeStayServicesRepository(_fulfilledOrder(orderId))),
    ],
  );
  c.read(appRouterProvider).go('/reservation/res-1/service-orders/$orderId/review');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('rate → submit → processing → "thanks" result (pending)',
      (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final String orderId =
        _scenarioOrderId(DummyServiceReviewScenario.noReviewThenPending);
    await _openServiceReview(tester, orderId);

    expect(find.text(en.serviceReviewFormPrompt), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(en.reviewStarsLabel(5)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.reviewSubmitCta));
    await tester.pumpAndSettle();

    expect(find.text(en.reviewSubmittedTitle), findsOneWidget);
    expect(find.text(en.reviewPendingModerationBody), findsOneWidget);
  });

  testWidgets('an already-reviewed order shows the existing review read-only',
      (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final String orderId =
        _scenarioOrderId(DummyServiceReviewScenario.alreadyReviewedPending);
    await _openServiceReview(tester, orderId);

    expect(find.text(en.reviewAlreadyTitle), findsOneWidget);
    expect(find.text(en.reviewYourRatingLabel), findsOneWidget);
  });

  testWidgets('a non-fulfilled order cannot be reviewed', (WidgetTester tester) async {
    final AppLocalizations en = await _l10n('en');
    final ds = DummyServiceReviewDataSource(clock: () => _now);
    final ServiceOrder requested = ServiceOrder(
      id: 'order-9',
      reservationId: 'res-1',
      serviceId: 'svc-1',
      serviceName: const LocalizedText(ar: 'خدمة الغرف', en: 'Room Service'),
      quantity: 1,
      unitPrice: const Money(amount: 40),
      totalAmount: const Money(amount: 40),
      status: ServiceOrderStatus.requested,
      requestedAt: _now,
    );
    final ProviderContainer c = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        serviceReviewDataSourceProvider.overrideWithValue(ds),
        serviceReviewRepositoryProvider
            .overrideWithValue(ServiceReviewRepositoryImpl(ds)),
        stayServicesRepositoryProvider
            .overrideWithValue(_FakeStayServicesRepository(requested)),
      ],
    );
    c.read(appRouterProvider).go('/reservation/res-1/service-orders/order-9/review');
    await tester.pumpAndSettle();

    expect(find.text(en.serviceReviewNotEligibleTitle), findsOneWidget);
  });
}
