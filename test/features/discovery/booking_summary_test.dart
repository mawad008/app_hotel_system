import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/price_breakdown_card.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/room_summary_card.dart';

import '../../support/auth_test_support.dart';
import '../../support/calendar_test_support.dart';
import '../../support/pump_app.dart';

final List<Override> _fixedClock = <Override>[
  clockProvider.overrideWithValue(() => DateTime(2026, 9, 1)),
];

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

/// Authenticated guest → Oasis → 6–8 Sept → open the named room → select → summary.
Future<AppLocalizations> _toSummary(WidgetTester tester, String roomName) async {
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

  final Finder card = find.ancestor(
    of: find.text(roomName),
    matching: find.byType(RoomSummaryCard),
  );
  await tester.scrollUntilVisible(card, 200);
  await tester.tap(
    find.descendant(
      of: card,
      matching: find.widgetWithText(OutlinedButton, en.roomViewDetails),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, en.roomSelectThisRoom));
  await tester.pumpAndSettle();

  expect(find.text(en.bookingDetailsTitle), findsOneWidget);
  return en;
}

void main() {
  testWidgets("the price breakdown adds the hotel's own service fee to the total",
      (WidgetTester tester) async {
    final AppLocalizations en = await _toSummary(tester, 'Standard Room');

    expect(find.byType(PriceBreakdownCard), findsOneWidget);
    expect(find.text(en.bookingRoomSubtotal), findsOneWidget);
    // The Oasis charges a fixed 45 per booking (dashboard setting) — a real
    // fee now, not a design placeholder: 2 nights × 320 + 45.
    expect(find.text(en.bookingServiceFee), findsOneWidget);
    final PriceBreakdownCard card =
        tester.widget<PriceBreakdownCard>(find.byType(PriceBreakdownCard));
    expect(card.breakdown.serviceFee!.amount, 45);
    expect(card.breakdown.total.amount, 685);
    expect(find.text(en.bookingTotal), findsOneWidget);
  });

  testWidgets('an inline stepper change that still fits keeps the selection',
      (WidgetTester tester) async {
    // Deluxe Room fits 3 guests.
    final AppLocalizations en = await _toSummary(tester, 'Deluxe Room');

    // Add a third adult right on the summary.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pumpAndSettle();

    // Still on the summary with a real payment CTA (selection not dropped).
    expect(find.text(en.bookingDetailsTitle), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, en.bookingProceedToPayment),
      findsOneWidget,
    );
    expect(find.text(en.reviewNoSelectionTitle), findsNothing);
  });

  testWidgets(
      'the adults stepper stops at the room capacity and says why instead of '
      'dropping the selection', (WidgetTester tester) async {
    // Standard Room (double bed) fits 2 guests; the party starts at 2 adults.
    final AppLocalizations en = await _toSummary(tester, 'Standard Room');
    expect(find.text(en.roomMaxAdultsReached(2)), findsOneWidget);

    // Try a third adult.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pump();

    // The count holds at 2, the limit is explained, and the room stays chosen.
    expect(find.text('2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(en.roomMaxAdultsReached(2)),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.text(en.reviewNoSelectionTitle), findsNothing);
    expect(
      find.widgetWithText(FilledButton, en.bookingProceedToPayment),
      findsOneWidget,
    );
  });
}
