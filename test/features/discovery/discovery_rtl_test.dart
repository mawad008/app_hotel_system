import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/stay_range_calendar.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('discover renders right-to-left in Arabic', (WidgetTester tester) async {
    await pumpApp(tester, bootSession: completeSession(), locale: arabic);
    final AppLocalizations ar =
        await AppLocalizations.delegate.load(const Locale('ar'));

    expect(find.text(ar.discoverExploreHotels), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.discoverExploreHotels))),
      TextDirection.rtl,
    );
    // Arabic hotel names come through the localized entities.
    expect(find.text('فندق الواحة'), findsWidgets);
  });

  testWidgets('search renders right-to-left in Arabic', (WidgetTester tester) async {
    await pumpApp(tester, bootSession: completeSession(), locale: arabic);
    final AppLocalizations ar =
        await AppLocalizations.delegate.load(const Locale('ar'));

    // v2 Home opens search from the header's search circle button.
    await tester.tap(find.byTooltip(ar.searchTitle));
    await tester.pumpAndSettle();

    // The search screen's app-bar title.
    expect(find.text(ar.discoverFeaturedSection), findsWidgets);
    expect(
      Directionality.of(
        tester.element(find.text(ar.discoverFeaturedSection).last),
      ),
      TextDirection.rtl,
    );
  });

  testWidgets('the stay-dates calendar renders in Arabic', (WidgetTester tester) async {
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

    expect(find.byType(StayRangeCalendar), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(StayRangeCalendar))),
      TextDirection.rtl,
    );
    // Arabic month label (September 2026 → "سبتمبر ٢٠٢٦").
    expect(find.textContaining('سبتمبر'), findsWidgets);
    // Arabic weekday names and Arabic-Indic day digits.
    expect(find.text('أحد'), findsWidgets);
    expect(find.text('٦'), findsWidgets);
  });

  testWidgets('the available-rooms + review screens render in Arabic',
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
    // Calendar day cells render Arabic-Indic digits for `ar`.
    await tapCalendarDay(tester, '٦');
    await tapCalendarDay(tester, '٨');
    await tester.tap(find.widgetWithText(FilledButton, ar.stayDatesShowRooms));
    await tester.pumpAndSettle();

    expect(find.text(ar.roomsTitle), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text(ar.roomsTitle).first)),
      TextDirection.rtl,
    );

    await tester
        .tap(find.widgetWithText(OutlinedButton, ar.roomViewDetails).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, ar.roomSelectThisRoom));
    await tester.pumpAndSettle();

    expect(find.text(ar.bookingDetailsTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.bookingDetailsTitle))),
      TextDirection.rtl,
    );
    expect(find.text('فندق الواحة'), findsWidgets);
  });
}
