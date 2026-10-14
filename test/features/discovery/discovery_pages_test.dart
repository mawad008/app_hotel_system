import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/home_hotel_card.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/hotel_summary_card.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/room_summary_card.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/stay_range_calendar.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

final List<Override> _fixedClock = <Override>[
  clockProvider.overrideWithValue(() => DateTime(2026, 9, 1)),
];

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  testWidgets('discover renders the greeting and featured hotel cards', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, bootSession: completeSession());
    final AppLocalizations en = await _en();

    expect(find.textContaining(en.discoverGreeting), findsOneWidget);
    expect(find.text(en.discoverExploreHotels), findsOneWidget);
    expect(find.byType(HomeHotelCard), findsWidgets);
    expect(find.text('The Oasis Hotel'), findsWidgets);
  });

  testWidgets('the Home search button opens the search screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, bootSession: completeSession());

    // v2 Home opens search from the header's search circle button.
    await tester.tap(find.byTooltip((await tester.l10n()).searchTitle));
    await tester.pumpAndSettle();

    // The initial load shows every hotel (a search-only count line).
    expect(find.textContaining('hotels available'), findsOneWidget);
  });

  testWidgets(
    'a query with no matches shows the no-results state, then clears',
    (WidgetTester tester) async {
      await pumpApp(tester, bootSession: completeSession());
      final AppLocalizations en = await _en();

      // v2 Home opens search from the header's search circle button.
      await tester.tap(find.byTooltip((await tester.l10n()).searchTitle));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'zzzzz');
      await tester.pumpAndSettle();
      expect(find.text(en.searchNoResultsTitle), findsOneWidget);

      await tester.tap(find.byTooltip(en.searchClearTooltip));
      await tester.pumpAndSettle();
      expect(find.text(en.searchNoResultsTitle), findsNothing);
      expect(find.byType(HotelSummaryCard), findsWidgets);
    },
  );

  testWidgets('the filter sheet applies a city filter', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, bootSession: completeSession());
    final AppLocalizations en = await _en();

    // v2 Home opens search from the header's search circle button.
    await tester.tap(find.byTooltip((await tester.l10n()).searchTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(en.filterTitle));
    await tester.pumpAndSettle();
    expect(find.text(en.filterTitle), findsOneWidget);

    final Finder jeddahChip = find.widgetWithText(
      FilterChip,
      'Jeddah · ${en.cityHotelCount(2)}',
    );
    await tester.ensureVisible(jeddahChip);
    await tester.tap(jeddahChip);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.filterApply));
    await tester.pumpAndSettle();

    // Only Jeddah hotels remain.
    expect(find.text('The Marina Hotel'), findsWidgets);
    expect(find.text('The Palm Hotel'), findsNothing);
  });

  testWidgets('the sort chips reorder the results', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, bootSession: completeSession());
    final AppLocalizations en = await _en();

    // v2 Home opens search from the header's search circle button.
    await tester.tap(find.byTooltip((await tester.l10n()).searchTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.sortLowestPrice));
    await tester.pumpAndSettle();

    expect(find.byType(HotelSummaryCard), findsWidgets);
  });

  testWidgets('discover → hotel detail → stay dates → available rooms', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: _fixedClock,
    );
    final AppLocalizations en = await _en();

    await tester.tap(find.text('The Oasis Hotel').first);
    await tester.pumpAndSettle();
    expect(find.text(en.hotelBookNow), findsOneWidget);

    await tester.tap(find.text(en.hotelBookNow));
    await tester.pumpAndSettle();
    expect(find.text(en.stayDatesTitle), findsOneWidget);
    expect(find.byType(StayRangeCalendar), findsOneWidget);
    // Guidance line, empty state.
    expect(find.text(en.stayDatesHintPickCheckIn), findsOneWidget);

    // CTA disabled until both dates chosen.
    final Finder cta = find.widgetWithText(FilledButton, en.stayDatesShowRooms);
    expect(tester.widget<FilledButton>(cta).onPressed, isNull);

    await tapCalendarDay(tester, '6');
    // After the first tap the guidance moves past the initial hint.
    expect(find.text(en.stayDatesHintPickCheckIn), findsNothing);

    await tapCalendarDay(tester, '8');
    // Both chosen → range + nights guidance and an enabled CTA.
    expect(find.textContaining(en.stayNights(2)), findsWidgets);

    final Finder cta2 = find.widgetWithText(
      FilledButton,
      en.stayDatesShowRooms,
    );
    expect(tester.widget<FilledButton>(cta2).onPressed, isNotNull);

    await tester.tap(cta2);
    await tester.pumpAndSettle();

    expect(find.text(en.roomsTitle), findsWidgets);
    expect(find.byType(RoomSummaryCard), findsWidgets);
    // The stay summary card shows the hotel and labelled dates.
    expect(find.text('The Oasis Hotel'), findsWidgets);
    expect(find.text(en.stayDatesCheckIn), findsWidgets);

    // Open a room's detail page.
    await tester.tap(
      find.widgetWithText(OutlinedButton, en.roomViewDetails).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(en.roomSelectThisRoom), findsOneWidget);
    expect(find.text(en.roomDetailAmenitiesHeading), findsOneWidget);
    expect(find.text(en.roomDetailCancellationHeading), findsOneWidget);
    // The room type's full description now renders on its own detail page
    // (not just the one-line truncated copy on the list card).
    expect(
      find.textContaining('A practical room with a calm city outlook.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'too many guests shows the no-rooms state with recovery actions',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        bootSession: completeSession(),
        extraOverrides: _fixedClock,
      );
      final AppLocalizations en = await _en();

      await tester.tap(find.text('The Oasis Hotel').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.hotelBookNow));
      await tester.pumpAndSettle();
      await tapCalendarDay(tester, '6');
      await tapCalendarDay(tester, '8');
      await tester.tap(
        find.widgetWithText(FilledButton, en.stayDatesShowRooms),
      );
      await tester.pumpAndSettle();

      // Bump the party past every room's occupancy via the guests sheet
      // ("Edit" link in the stay summary card).
      await tester.tap(find.text(en.commonEdit).first);
      await tester.pumpAndSettle();
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
        await tester.pump();
      }
      await tester.tap(find.text(en.guestsConfirm));
      await tester.pumpAndSettle();

      expect(find.text(en.roomsNoResultsTitle), findsWidgets);
      expect(find.text(en.roomsChangeDates), findsWidgets);
    },
  );

  testWidgets(
    'guests are chosen on the stay-dates screen before the room list',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        bootSession: completeSession(),
        extraOverrides: _fixedClock,
      );
      final AppLocalizations en = await _en();

      await tester.tap(find.text('The Oasis Hotel').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.hotelBookNow));
      await tester.pumpAndSettle();

      // The guests field is part of the dates step, defaulting to 2 adults.
      expect(find.text(en.guestsTitle), findsOneWidget);
      expect(find.text(en.guestsAdultsCount(2)), findsOneWidget);

      await tester.tap(find.text(en.guestsTitle));
      await tester.pumpAndSettle();
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
        await tester.pump();
      }
      await tester.tap(find.text(en.guestsConfirm));
      await tester.pumpAndSettle();
      expect(find.text(en.guestsAdultsCount(8)), findsOneWidget);

      await tapCalendarDay(tester, '6');
      await tapCalendarDay(tester, '8');
      await tester.tap(
        find.widgetWithText(FilledButton, en.stayDatesShowRooms),
      );
      await tester.pumpAndSettle();

      // No room seats 8, so none is offered.
      expect(find.byType(RoomSummaryCard), findsNothing);
      expect(find.text(en.roomsNoResultsTitle), findsWidgets);
    },
  );
}
