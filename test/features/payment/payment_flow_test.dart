import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/dummy_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_request.dart';
import 'package:hotel_guest_app/features/payment/presentation/state/payment_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'payment_test_support.dart';

class _StubReservationRepository implements ReservationRepository {
  _StubReservationRepository({this.amount = 900, this.depositAmount});

  final int amount;
  final num? depositAmount;

  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation();

  @override
  Future<Reservation> getById(String id) async => fakeReservation(
    id: id,
    amount: amount,
    depositAmount: depositAmount,
  );

  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}

/// Simulates the backend flipping `PENDING` → `DEPOSIT_HELD` the moment the
/// deposit hold goes active (`PaymentWorkflowService`) — the first `getById`
/// call is still `pending` (the review screen's own initial read), every call
/// after that is `depositHeld`, so a test can tell a genuine refetch (the
/// fix) apart from a cached, pre-payment value (the bug).
class _TransitioningReservationRepository implements ReservationRepository {
  int _getByIdCalls = 0;

  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation();

  @override
  Future<Reservation> getById(String id) async {
    _getByIdCalls++;
    return fakeReservation(
      id: id,
      status: _getByIdCalls == 1
          ? ReservationStatus.pending
          : ReservationStatus.depositHeld,
    );
  }

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

/// Review → "pay now" → method (Apple Pay, the default selection) →
/// "continue", which is what actually requests the hold.
Future<void> _payNow(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.widgetWithText(FilledButton, l10n.paymentPayNowCta));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, l10n.commonContinue));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  String reservationId, {
  Locale? locale,
  DummyPaymentDataSource? paymentSource,
  ReservationRepository? reservationRepository,
}) async {
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reservationRepositoryProvider
          .overrideWithValue(reservationRepository ?? _StubReservationRepository()),
      if (paymentSource != null)
        paymentDataSourceProvider.overrideWithValue(paymentSource),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$reservationId/payment');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets(
      'before any hold, the deposit row shows the server deposit — never the stay total',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    // A 2-night stay of 466 at the hotel's 20% deposit → a 93.20 hold.
    await _open(
      tester,
      id,
      reservationRepository:
          _StubReservationRepository(amount: 466, depositAmount: 93.2),
    );

    expect(find.text(en.paymentCardDepositLabel), findsOneWidget);
    // The stay total appears only in the cost breakdown (subtotal + total);
    // the deposit row carries the 93.20 hold.
    expect(find.text('93.20'), findsOneWidget);
    expect(find.text('466'), findsNWidgets(2));
    final Finder depositRow = find
        .ancestor(of: find.text(en.paymentCardDepositLabel), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: depositRow, matching: find.text('93.20')),
      findsOneWidget,
    );
  });

  testWidgets('review → pay → processing → result → back to reservation (EN)',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    await _open(tester, id);

    expect(find.text(en.paymentReviewTitle), findsWidgets);
    expect(find.text(en.paymentPayNowCta), findsOneWidget);

    await _payNow(tester, en);

    // Landed on the authoritative result screen.
    expect(find.text(en.paymentSuccessTitle), findsOneWidget);
    expect(find.text(en.paymentStatusHoldActive), findsWidgets);

    await tester
        .tap(find.widgetWithText(OutlinedButton, en.paymentBackToReservation));
    await tester.pumpAndSettle();
    expect(find.text(en.bookingDetailTitle), findsWidgets);
  });

  testWidgets(
      'after a held deposit, Reservation Detail offers "Verify identity" — '
      'not a stale "Continue payment" (regression: reservation must be '
      'refetched, not read from the pre-payment cache)', (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    await _open(
      tester,
      id,
      reservationRepository: _TransitioningReservationRepository(),
    );

    await _payNow(tester, en);
    expect(find.text(en.paymentSuccessTitle), findsOneWidget);

    await tester
        .tap(find.widgetWithText(OutlinedButton, en.paymentBackToReservation));
    await tester.pumpAndSettle();

    expect(find.text(en.bookingDetailTitle), findsWidgets);
    expect(find.text(en.bookingCtaVerifyIdentity), findsOneWidget);
    expect(find.text(en.bookingCtaContinuePayment), findsNothing);
  });

  testWidgets('a pending hold shows the processing result', (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyHoldScenario.staysPending);
    await _open(tester, id);

    await _payNow(tester, en);
    expect(find.text(en.paymentPendingTitle), findsOneWidget);
  });

  testWidgets('an infrastructure failure shows a safe error and retry works',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final src = DummyPaymentDataSource(clock: () => DateTime(2026, 9, 8));

    await _open(tester, id, paymentSource: src);
    // The review screen loads fine; the hold request is what fails.
    src.failWith = Exception('offline');
    await _payNow(tester, en);

    expect(find.text(en.paymentFailedTitle), findsWidgets);
    // No provider/internal detail is shown.
    expect(find.textContaining('offline'), findsNothing);

    src.failWith = null;
    await tester.tap(find.widgetWithText(FilledButton, en.paymentRetryCta));
    await tester.pumpAndSettle();
    expect(find.text(en.paymentSuccessTitle), findsOneWidget);
  });

  testWidgets('the flow renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    await _open(tester, id, locale: arabic);

    expect(
      Directionality.of(tester.element(find.text(ar.paymentPayNowCta))),
      TextDirection.rtl,
    );
    await _payNow(tester, ar);
    expect(find.text(ar.paymentSuccessTitle), findsOneWidget);
  });

  testWidgets('tapping continue twice never places two holds', (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final c = await _open(tester, id);

    await tester.tap(find.widgetWithText(FilledButton, en.paymentPayNowCta));
    await tester.pumpAndSettle();

    final continueBtn = find.widgetWithText(FilledButton, en.commonContinue);
    await tester.tap(continueBtn);
    await tester.pump();
    // Second tap while the first request is settling.
    if (tester.any(continueBtn)) {
      await tester.tap(continueBtn, warnIfMissed: false);
    }
    await tester.pumpAndSettle();

    expect(find.text(en.paymentSuccessTitle), findsOneWidget);
    final PaymentHoldRequest req = PaymentHoldRequest.forReservation(fakeReservation(id: id));
    final payment =
        await c.read(paymentRepositoryProvider).currentForReservation(id);
    expect(payment.amount.amount, req.amount.amount);
  });
}
