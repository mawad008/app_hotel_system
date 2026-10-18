import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('booking summary + payment screens render right-to-left in Arabic',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      bootSession: completeSession(),
      locale: arabic,
      extraOverrides: <Override>[
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 1)),
      ],
    );
    final AppLocalizations ar =
        await AppLocalizations.delegate.load(const Locale('ar'));

    await tester.tap(find.text('فندق الواحة').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.hotelBookNow));
    await tester.pumpAndSettle();
    await tapCalendarDay(tester, '٦');
    await tapCalendarDay(tester, '٨');
    await tester.tap(find.widgetWithText(FilledButton, ar.stayDatesShowRooms));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(OutlinedButton, ar.roomViewDetails).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, ar.roomSelectThisRoom));
    await tester.pumpAndSettle();

    // Booking summary with the Arabic "proceed to payment" CTA.
    expect(find.text(ar.bookingProceedToPayment), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.bookingDetailsTitle))),
      TextDirection.rtl,
    );

    await tester
        .tap(find.widgetWithText(FilledButton, ar.bookingProceedToPayment));
    await tester.pumpAndSettle();

    expect(find.text(ar.paymentReviewTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.paymentReviewTitle))),
      TextDirection.rtl,
    );
  });
}
