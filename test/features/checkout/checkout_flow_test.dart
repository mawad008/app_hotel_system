import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/dummy_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/presentation/state/checkout_providers.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'checkout_test_support.dart';

class _ReservationRepo implements ReservationRepository {
  _ReservationRepo(this.status, {this.stay});
  final ReservationStatus status;
  final StayRange? stay;
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: status);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: status, stay: stay);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<ProviderContainer> _open(
  WidgetTester tester,
  String reservationId, {
  // CheckoutService only starts from `in_stay` (reception starts the stay).
  ReservationStatus status = ReservationStatus.inStay,
  Locale? locale,
  DummyCheckoutDataSource? source,
  StayRange? stay,
}) async {
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reservationRepositoryProvider.overrideWithValue(_ReservationRepo(status, stay: stay)),
      if (source != null) ...<Override>[
        checkoutDataSourceProvider.overrideWithValue(source),
        invoiceDataSourceProvider.overrideWithValue(source),
      ],
    ],
  );
  c.read(appRouterProvider).go('/reservation/$reservationId/checkout');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('leaving before the booked check-out day says only stayed nights are billed',
      (tester) async {
    final en = await _l10n('en');
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    await _open(
      tester,
      id,
      stay: StayRange(
        checkIn: today.subtract(const Duration(days: 1)),
        checkOut: today.add(const Duration(days: 2)),
      ),
    );

    expect(find.byKey(const ValueKey<String>('checkout-early-departure-note')), findsOneWidget);
    // Checkout is not blocked before the booked day.
    final FilledButton cta = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, en.checkoutCompleteCta));
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('on/after the booked check-out day there is no early-departure note',
      (tester) async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    await _open(tester, id); // fake stay ended 2026-09-08

    expect(find.byKey(const ValueKey<String>('checkout-early-departure-note')), findsNothing);
  });

  testWidgets('checkout → processing → completion → invoice (EN)',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    await _open(tester, id);

    expect(find.text(en.checkoutTitle), findsWidgets);
    expect(find.text(en.folioSummaryTitle), findsOneWidget);
    expect(find.text(en.folioAccommodationLine), findsOneWidget);

    await tester
        .tap(find.widgetWithText(FilledButton, en.checkoutCompleteCta));
    await tester.pumpAndSettle();

    expect(find.text(en.checkoutDoneTitle), findsOneWidget);

    await tester
        .tap(find.widgetWithText(FilledButton, en.checkoutViewInvoiceCta));
    await tester.pumpAndSettle();

    expect(find.text(en.invoiceTitle), findsWidgets);
    expect(find.text(en.invoiceItemsTitle), findsOneWidget);
    expect(find.textContaining('INV-'), findsWidgets);
    expect(find.text(en.invoiceSettledTag), findsOneWidget);
  });

  testWidgets('the CTA is disabled until the stay has started', (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    await _open(tester, id, status: ReservationStatus.verified);

    expect(find.text(en.checkoutNotReadyTitle), findsWidgets);
    final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, en.checkoutCompleteCta));
    expect(btn.onPressed, isNull);
  });

  testWidgets('a settlement failure shows a safe retry that then completes',
      (tester) async {
    final en = await _l10n('en');
    final id =
        reservationIdForSettlement(DummySettlementScenario.failsThenSettles);
    await _open(tester, id);

    await tester
        .tap(find.widgetWithText(FilledButton, en.checkoutCompleteCta));
    await tester.pumpAndSettle();

    expect(find.text(en.checkoutFailedTitle), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, en.checkoutRetryCta));
    await tester.pumpAndSettle();
    expect(find.text(en.checkoutDoneTitle), findsOneWidget);
  });

  testWidgets('a pending settlement shows the waiting state, no completion',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForSettlement(DummySettlementScenario.staysPending);
    await _open(tester, id);

    await tester
        .tap(find.widgetWithText(FilledButton, en.checkoutCompleteCta));
    await tester.pumpAndSettle();
    expect(find.text(en.checkoutPendingTitle), findsOneWidget);
    expect(find.text(en.checkoutDoneTitle), findsNothing);
  });

  testWidgets('the invoice screen shows "not ready" before checkout',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final c = await _open(tester, id);
    c.read(appRouterProvider).go('/reservation/$id/invoice');
    await tester.pumpAndSettle();
    expect(find.text(en.invoiceNotReadyTitle), findsOneWidget);
  });

  testWidgets('the flow renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    await _open(tester, id, locale: arabic);

    expect(
      Directionality.of(tester.element(find.text(ar.checkoutCompleteCta))),
      TextDirection.rtl,
    );
    await tester
        .tap(find.widgetWithText(FilledButton, ar.checkoutCompleteCta));
    await tester.pumpAndSettle();
    expect(find.text(ar.checkoutDoneTitle), findsOneWidget);
  });

  testWidgets('a checked-in (not yet in-stay) reservation cannot check out yet',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    await _open(tester, 'r-ci', status: ReservationStatus.checkedIn);
    expect(find.text(en.checkoutNotReadyTitle), findsOneWidget);
  });
}
