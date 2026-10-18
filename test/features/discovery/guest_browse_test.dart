import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/payment/presentation/pages/payment_review_page.dart';

import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

/// Deferred auth (docs/mobile-deferred-auth.md): a guest browses discovery and
/// the booking summary without an account; sign-in is requested only at the
/// "proceed to payment" step and returns the guest to the summary intact.

final List<Override> _fixedClock = <Override>[
  clockProvider.overrideWithValue(() => DateTime(2026, 9, 1)),
];

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

String _path(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

/// Guest drives welcome → discover → Oasis → dates → rooms → select → summary.
Future<AppLocalizations> _guestToSummary(
  WidgetTester tester,
  ProviderContainer Function() container,
) async {
  final AppLocalizations en = await _en();

  await tester.tap(find.text(en.entryStartAction));
  await tester.pumpAndSettle();
  expect(_path(container()), AppRoutes.discover);

  await tester.tap(find.text('The Oasis Hotel').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(en.hotelBookNow));
  await tester.pumpAndSettle();
  await tapCalendarDay(tester, '6');
  await tapCalendarDay(tester, '8');
  await tester.tap(find.widgetWithText(FilledButton, en.stayDatesShowRooms));
  await tester.pumpAndSettle();
  await tester
      .tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).first);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, en.roomSelectThisRoom));
  await tester.pumpAndSettle();

  expect(find.text(en.bookingDetailsTitle), findsOneWidget);
  return en;
}

void main() {
  testWidgets('a guest reaches the booking summary and sees a sign-in CTA',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, extraOverrides: _fixedClock);
    final AppLocalizations en = await _guestToSummary(tester, () => container);

    // The price breakdown is visible (320/night × 2 nights = 640 subtotal)…
    expect(find.text(en.bookingRoomSubtotal), findsOneWidget);
    // …but the CTA asks the guest to sign in, not to pay.
    expect(find.text(en.reviewSignInToConfirm), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, en.bookingProceedToPayment),
      findsNothing,
    );
  });

  testWidgets(
      'signing in from the booking summary returns the guest there to pay',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, extraOverrides: _fixedClock);
    final AppLocalizations en = await _guestToSummary(tester, () => container);

    await tester.tap(find.text(en.reviewSignInToConfirm));
    await tester.pumpAndSettle();
    expect(find.text(en.authPhoneHeading), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0512345678');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, en.authPhoneSubmit));
    await tester.pumpAndSettle();
    expect(find.text(en.authOtpHeading), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text(en.authProfileTitle), findsOneWidget);

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Mahmoud Nabil');
    await tester.enterText(fields.at(1), 'mahmoud@example.com');
    await tester.pump();
    await tester.tap(find.text(en.authProfileSubmit));
    await tester.pumpAndSettle();

    expect(_path(container), '/discover/hotel/oasis/review');
    expect(find.text(en.bookingDetailsTitle), findsOneWidget);

    // Now a real "proceed to payment" CTA — it creates the reservation and
    // routes straight to the payment review.
    final Finder pay =
        find.widgetWithText(FilledButton, en.bookingProceedToPayment);
    expect(pay, findsOneWidget);
    await tester.tap(pay);
    await tester.pumpAndSettle();

    expect(_path(container), endsWith('/payment'));
  });

  testWidgets(
      'after signing in mid-booking, back from payment reaches the rooms and '
      'a changed room can still proceed to payment',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, extraOverrides: _fixedClock);
    final AppLocalizations en = await _guestToSummary(tester, () => container);

    await tester.tap(find.text(en.reviewSignInToConfirm));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0512345678');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, en.authPhoneSubmit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Mahmoud Nabil');
    await tester.enterText(fields.at(1), 'mahmoud@example.com');
    await tester.pump();
    await tester.tap(find.text(en.authProfileSubmit));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, en.bookingProceedToPayment));
    await tester.pumpAndSettle();
    expect(_path(container), endsWith('/payment'));

    // The sign-in replaced the stack, so payment is the only page: its
    // "Back" must still lead to the rooms list.
    await tester.tap(find.widgetWithText(OutlinedButton, en.commonBack));
    await tester.pumpAndSettle();
    expect(_path(container), '/discover/hotel/oasis/rooms');

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

  testWidgets('the summary reached by sign-in has a back button to the rooms',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, extraOverrides: _fixedClock);
    await _guestToSummary(tester, () => container);
    container.read(appRouterProvider).go('/discover/hotel/oasis/review');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(_path(container), '/discover/hotel/oasis/rooms');
  });
}
