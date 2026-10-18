import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/config/app_environment.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/room_summary_card.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/upcoming_stay_card.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

const AppConfig _singleHotelConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: 'http://localhost',
  apiVersion: 'v1',
  useDummyData: true,
  singleHotelGroup: true,
);

void main() {
  testWidgets('the upcoming-stay card shows for a signed-in guest',
      (WidgetTester tester) async {
    await pumpApp(tester, bootSession: completeSession());
    final AppLocalizations en = await _en();

    expect(find.text(en.discoverUpcomingStay), findsOneWidget);
    expect(find.byType(UpcomingStayCard), findsOneWidget);
  });

  testWidgets('the upcoming-stay card is hidden for a guest',
      (WidgetTester tester) async {
    await pumpApp(tester);
    final AppLocalizations en = await _en();

    expect(find.text(en.discoverUpcomingStay), findsNothing);
    expect(find.byType(UpcomingStayCard), findsNothing);
  });

  testWidgets('a single-hotel group shows "explore rooms" instead of the grid',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        appConfigProvider.overrideWithValue(_singleHotelConfig),
      ],
    );
    final AppLocalizations en = await _en();

    expect(find.text(en.discoverExploreRooms), findsOneWidget);
    expect(find.text(en.discoverExploreHotels), findsNothing);
    expect(find.byType(RoomSummaryCard), findsWidgets);
    // The subtitle names the sole hotel.
    expect(find.text(en.discoverSubtitleHotel('The Oasis Hotel')), findsOneWidget);
  });
}
