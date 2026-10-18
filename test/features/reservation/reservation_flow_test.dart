import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/features/payment/presentation/pages/payment_review_page.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/dummy_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

final DateTime _now = DateTime(2026, 9, 1);
final List<Override> _fixedClock = <Override>[
  clockProvider.overrideWithValue(() => _now),
];

/// Drives an authenticated guest to the booking summary ("تفاصيل الحجز").
Future<AppLocalizations> _toSummary(
  WidgetTester tester, {
  List<Override> extra = const <Override>[],
}) async {
  await pumpApp(
    tester,
    bootSession: completeSession(),
    extraOverrides: <Override>[..._fixedClock, ...extra],
  );
  final AppLocalizations en =
      await AppLocalizations.delegate.load(const Locale('en'));

  await tester.tap(find.text('The Oasis Hotel').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(en.hotelBookNow));
  await tester.pumpAndSettle();
  await tapCalendarDay(tester, '6');
  await tapCalendarDay(tester, '8');
  await tester.tap(find.widgetWithText(FilledButton, en.stayDatesShowRooms));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).first);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, en.roomSelectThisRoom));
  await tester.pumpAndSettle();

  expect(find.text(en.bookingDetailsTitle), findsOneWidget);
  return en;
}

void main() {
  testWidgets('booking summary → proceed to payment → payment review',
      (WidgetTester tester) async {
    final AppLocalizations en = await _toSummary(tester);

    final Finder pay =
        find.widgetWithText(FilledButton, en.bookingProceedToPayment);
    expect(pay, findsOneWidget);

    await tester.tap(pay);
    await tester.pumpAndSettle();

    // Straight to the payment review screen for the freshly-created reservation.
    expect(find.byType(PaymentReviewPage), findsOneWidget);
    expect(find.text(en.paymentReviewTitle), findsOneWidget);
  });

  group('back from payment', () {
    Future<AppLocalizations> toPaymentAndBack(WidgetTester tester) async {
      final AppLocalizations en = await _toSummary(tester);
      await tester
          .tap(find.widgetWithText(FilledButton, en.bookingProceedToPayment));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentReviewPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(en.roomsTitle), findsWidgets);
      return en;
    }

    testWidgets('changing the room still offers proceed to payment',
        (WidgetTester tester) async {
      final AppLocalizations en = await toPaymentAndBack(tester);

      await tester
          .tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, en.roomSelectThisRoom));
      await tester.pumpAndSettle();

      final Finder pay =
          find.widgetWithText(FilledButton, en.bookingProceedToPayment);
      expect(pay, findsOneWidget);
      await tester.tap(pay);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentReviewPage), findsOneWidget);
    });

    testWidgets('the same room continues to its existing reservation',
        (WidgetTester tester) async {
      final AppLocalizations en = await toPaymentAndBack(tester);

      await tester
          .tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, en.commonContinue));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, en.bookingProceedToPayment));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentReviewPage), findsOneWidget);
    });
  });

  testWidgets('a failed create shows an error banner and allows retry',
      (WidgetTester tester) async {
    final DummyReservationDataSource ds = DummyReservationDataSource()
      ..failWith = const NetworkException();

    final AppLocalizations en = await _toSummary(tester, extra: <Override>[
      reservationRepositoryProvider
          .overrideWithValue(ReservationRepositoryImpl(ds)),
    ]);

    await tester
        .tap(find.widgetWithText(FilledButton, en.bookingProceedToPayment));
    await tester.pumpAndSettle();

    // Still on the booking summary, now showing the failure.
    expect(find.text(en.bookingDetailsTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(en.reservationCreateFailedTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(en.reservationCreateFailedTitle), findsOneWidget);

    // Recover and retry.
    ds.failWith = null;
    await tester
        .tap(find.widgetWithText(FilledButton, en.bookingProceedToPayment));
    await tester.pumpAndSettle();
    expect(find.text(en.paymentReviewTitle), findsOneWidget);
  });

  testWidgets('the payment CTA is not offered without a selection',
      (WidgetTester tester) async {
    final container = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: _fixedClock,
    );
    final AppLocalizations en =
        await AppLocalizations.delegate.load(const Locale('en'));

    final GoRouter router = container.read(appRouterProvider);
    router.go('/discover/hotel/oasis/review');
    await tester.pumpAndSettle();

    expect(find.text(en.reviewNoSelectionTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.bookingProceedToPayment),
        findsNothing);
  });
}
