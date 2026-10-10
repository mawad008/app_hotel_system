import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

final List<Override> _fixedClock = <Override>[
  clockProvider.overrideWithValue(() => DateTime(2026, 9, 1)),
];

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

/// Drives the flow to the available-rooms page for The Oasis Hotel,
/// 6–8 September, default party.
Future<AppLocalizations> _openRooms(WidgetTester tester) async {
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
  await tester.tap(find.widgetWithText(FilledButton, en.stayDatesShowRooms));
  await tester.pumpAndSettle();
  return en;
}

/// Opens the first room's detail page and taps "Select this room" — which
/// goes straight on to the booking summary (Figma routing, no Continue bar).
Future<void> _selectFirstRoom(WidgetTester tester, AppLocalizations en) async {
  await tester.tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).first);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, en.roomSelectThisRoom));
  await tester.pumpAndSettle();
}

/// Selects the first room, then steps back from the summary to the list.
Future<void> _selectAndReturnToRooms(WidgetTester tester, AppLocalizations en) async {
  await _selectFirstRoom(tester, en);
  expect(find.text(en.bookingDetailsTitle), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('selecting a room opens the booking summary for it',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openRooms(tester);

    await _selectFirstRoom(tester, en);

    expect(find.text(en.bookingDetailsTitle), findsOneWidget);
    expect(find.text('The Oasis Hotel'), findsWidgets);
    expect(find.text('Standard Room'), findsWidgets);
    // 320 / night × 2 nights = 640 subtotal.
    expect(find.text(en.bookingRoomSubtotal), findsOneWidget);
    expect(find.text(en.bookingTotal), findsOneWidget);

    // Back returns to the rooms list with the room marked selected.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(en.roomSelected), findsWidgets);
  });

  testWidgets(
      'with a room selected, the guests sheet stops at its capacity and keeps '
      'the selection', (WidgetTester tester) async {
    // The first room (Standard Room, double bed) fits 2; the party is 2 adults.
    final AppLocalizations en = await _openRooms(tester);
    await _selectAndReturnToRooms(tester, en);
    expect(find.text(en.roomSelected), findsWidgets);

    // Try to add an adult via the guests sheet ("Edit" in the summary card).
    await tester.tap(find.text(en.commonEdit).first);
    await tester.pumpAndSettle();
    expect(find.text(en.roomMaxAdultsReached(2)), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pump();
    await tester.tap(find.text(en.guestsConfirm));
    await tester.pumpAndSettle();

    expect(find.text(en.roomsSelectionClearedNotice), findsNothing);
    expect(find.text(en.roomSelected), findsWidgets);
  });

  testWidgets('changing dates after selecting clears the selection',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openRooms(tester);
    await _selectAndReturnToRooms(tester, en);
    expect(find.text(en.roomSelected), findsWidgets);

    // "Edit dates" in the summary card → back to the calendar.
    await tester.tap(find.text(en.stayDatesEditDates).first);
    await tester.pumpAndSettle();
    expect(find.text(en.stayDatesTitle), findsOneWidget);

    // A new check-in day restarts the range and invalidates the selection.
    await tapCalendarDay(tester, '3');
    await tapCalendarDay(tester, '5');
    await tester.tap(find.widgetWithText(FilledButton, en.stayDatesShowRooms));
    await tester.pumpAndSettle();

    expect(find.text(en.roomSelected), findsNothing);
  });

  testWidgets('the room detail page can remove an existing selection',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openRooms(tester);
    await _selectAndReturnToRooms(tester, en);
    expect(find.text(en.roomSelected), findsWidgets);

    // Re-open the same room's detail and remove the selection.
    await tester.tap(find.widgetWithText(OutlinedButton, en.roomViewDetails).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, en.roomRemoveSelection));
    await tester.pumpAndSettle();

    expect(find.text(en.roomSelected), findsNothing);
  });

  testWidgets('the review route shows an empty state when nothing is selected',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: _fixedClock,
    );
    final AppLocalizations en = await _en();

    final GoRouter router = container.read(appRouterProvider);
    router.go('/discover/hotel/oasis/review');
    await tester.pumpAndSettle();

    expect(find.text(en.reviewNoSelectionTitle), findsOneWidget);
    expect(find.text(en.reviewBackToRooms), findsOneWidget);
  });
}
