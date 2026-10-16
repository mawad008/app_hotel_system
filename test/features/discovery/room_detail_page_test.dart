import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/availability_request.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_guest_details.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/room_availability_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/stay_dates_controller.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import '../../support/scroll_helpers.dart';

/// `ROOM_Detail_Premium`: every section is data-driven — the room badge,
/// "price includes" items, catalog facilities, the hotel's "prices include
/// taxes / service fee" flags and its check-in / check-out times. The offline
/// fixtures carry the same fields as the API (hotel `oasis` / room `deluxe`
/// have all of them; hotel `marina` has none of the hotel-level ones).
Future<void> _openRoom(WidgetTester tester, String hotelId, String roomId) async {
  final ProviderContainer c = await pumpApp(tester, bootSession: completeSession());
  final DateTime n = DateTime.now();
  final StayRange stay = StayRange(
    checkIn: DateTime(n.year, n.month, n.day + 6),
    checkOut: DateTime(n.year, n.month, n.day + 9),
  );
  c.read(stayDatesControllerProvider.notifier).setRange(stay);
  await c.read(roomAvailabilityControllerProvider.notifier).load(
        AvailabilityRequest(
          hotelId: hotelId,
          stay: stay,
          party: const GuestParty(adults: 2, children: 0),
        ),
      );
  c.read(appRouterProvider).go('/discover/hotel/$hotelId/rooms/$roomId');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the dashboard-managed badge, inclusions, facilities, '
      'included price rows and check-in / check-out times', (tester) async {
    final AppLocalizations en = await tester.l10n();
    await _openRoom(tester, 'oasis', 'deluxe');
    final Set<String> page = await textsOnWholePage(tester);

    expect(page, contains('Featured room'));

    // "The price includes": breakfast flag + operator items + refundable flag.
    expect(page, contains(en.roomBreakfastIncluded));
    expect(page, contains('Pool access'));
    expect(page, contains('24-hour reception'));
    expect(page, contains(en.roomFreeCancellation));

    // Catalog facilities, by label.
    expect(page, contains('Smart TV'));
    expect(page, contains('Private bathroom'));

    // Taxes are in the rate ("شاملة"); the hotel also charges a real fixed
    // service fee (45), so there is no "no extra fees" note.
    expect(page, contains(en.roomTaxesLabel));
    expect(page, contains(en.roomPriceIncludedValue));
    expect(page, contains(en.bookingServiceFee));
    expect(page, isNot(contains(en.roomFinalPriceNote)));

    // Hotel check-in / check-out times, noon as PM.
    expect(page, contains(en.roomPolicyCheckInBody('3:00 PM')));
    expect(page, contains(en.roomPolicyCheckOutBody('12:00 PM')));
  });

  testWidgets('claims nothing the hotel has not set', (tester) async {
    final AppLocalizations en = await tester.l10n();
    await _openRoom(tester, 'marina', 'standard');
    final Set<String> page = await textsOnWholePage(tester);

    expect(page, isNot(contains('Featured room')));
    expect(page, isNot(contains(en.roomTaxesLabel)));
    expect(page, isNot(contains(en.roomPriceIncludedValue)));
    expect(page, isNot(contains(en.roomFinalPriceNote)));
    expect(page, isNot(contains(en.bookingServiceFee)));
    expect(page, isNot(contains(en.roomPolicyCheckInTitle)));
  });

  test('the service fee mirrors the server: fixed, or a % truncated to the halala', () {
    const Money stay = Money(amount: 466);
    expect(const HotelServiceFee(isPercentage: false, value: 45).feeFor(stay).amount, 45);
    // 7.5% of 466 = 34.95; 2.5% of 246.5 = 6.1625 → 6.16.
    expect(const HotelServiceFee(isPercentage: true, value: 7.5).feeFor(stay).amount, 34.95);
    expect(
      const HotelServiceFee(isPercentage: true, value: 2.5)
          .feeFor(const Money(amount: 246.5))
          .amount,
      6.16,
    );
  });

  test('parses API room content given as locale-resolved strings', () {
    expect(RoomTypeSummaryModel.parseRoomTag('  غرفة مميزة ')!.ar, 'غرفة مميزة');
    expect(RoomTypeSummaryModel.parseRoomTag('   '), isNull);
    expect(
      RoomTypeSummaryModel.parseRoomInclusions(<Object?>['دخول المسبح', '', null])
          .map((t) => t.ar),
      <String>['دخول المسبح'],
    );
    final facilities = RoomTypeSummaryModel.parseRoomFacilities(<Object?>[
      <String, Object?>{'key': 'rt_tv', 'label': 'تلفزيون ذكي', 'icon': 'tv'},
      <String, Object?>{'key': 'broken'},
    ]);
    expect(facilities, hasLength(1));
    expect(facilities.single.label.ar, 'تلفزيون ذكي');
    expect(facilities.single.icon, 'tv');
  });
}
