import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/availability_request.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/favorite_room.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/discovery/presentation/pages/favorites_page.dart';
import 'package:hotel_guest_app/features/discovery/presentation/pages/room_detail_page.dart';
import 'package:hotel_guest_app/features/discovery/presentation/pages/stay_dates_page.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/favorite_hotels_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/favorite_rooms_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/room_availability_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/stay_dates_controller.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

StayRange _stay() {
  final DateTime n = DateTime.now();
  return StayRange(
    checkIn: DateTime(n.year, n.month, n.day + 6),
    checkOut: DateTime(n.year, n.month, n.day + 9),
  );
}

/// Opens Room Detail for the offline `oasis` / `deluxe` fixture.
Future<ProviderContainer> _openRoom(
  WidgetTester tester, {
  bool signedIn = true,
  bool preloadAvailability = true,
  bool withDates = true,
}) async {
  final ProviderContainer c = await pumpApp(
    tester,
    bootSession: signedIn ? completeSession() : null,
    locale: const Locale('en'),
  );
  if (withDates) {
    final StayRange stay = _stay();
    c.read(stayDatesControllerProvider.notifier).setRange(stay);
    if (preloadAvailability) {
      await c.read(roomAvailabilityControllerProvider.notifier).load(
            AvailabilityRequest(
              hotelId: 'oasis',
              stay: stay,
              party: const GuestParty(adults: 2, children: 0),
            ),
          );
    }
  }
  c.read(appRouterProvider).go('/discover/hotel/oasis/rooms/deluxe');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('the Room Detail heart saves the room itself, not its hotel', (tester) async {
    final AppLocalizations en = await tester.l10n();
    final ProviderContainer c = await _openRoom(tester);

    expect(find.byTooltip(en.roomFavoriteAdd), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('room-favorite')));
    await tester.pumpAndSettle();

    expect(find.text(en.favoriteRoomSavedSnack), findsOneWidget);
    expect(find.byTooltip(en.roomFavoriteRemove), findsOneWidget);
    final FavoriteRoom saved = c.read(favoriteRoomsProvider).single;
    expect(saved.roomTypeId, 'deluxe');
    expect(saved.hotelId, 'oasis');
    expect(c.read(favoriteHotelsProvider), isEmpty);
  });

  testWidgets('a saved room is listed under Favourites, opens its detail, '
      'and can be removed and restored', (tester) async {
    final AppLocalizations en = await tester.l10n();
    final ProviderContainer c = await _openRoom(tester);
    await tester.tap(find.byKey(const ValueKey<String>('room-favorite')));
    await tester.pumpAndSettle();
    final String roomName = c.read(favoriteRoomsProvider).single.name.en;

    // The snackbar leads to the list.
    await tester.tap(
      find.descendant(of: find.byType(SnackBar), matching: find.text(en.favoriteViewAction)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text(en.favoritesRoomsSection), findsOneWidget);
    expect(find.text(en.favoritesHotelsSection), findsNothing);
    expect(find.text(roomName), findsOneWidget);

    // Tapping the row opens the room.
    await tester.tap(find.text(roomName));
    await tester.pumpAndSettle();
    expect(find.byType(RoomDetailPage), findsOneWidget);
    expect(find.byTooltip(en.roomFavoriteRemove), findsOneWidget);

    // Back on the list: remove, then undo.
    c.read(appRouterProvider).goNamed(AppRoutes.favoritesName);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('favorite-room-remove-deluxe')));
    await tester.pumpAndSettle();
    expect(find.text(en.favoritesEmptyTitle), findsOneWidget);
    await tester.tap(find.text(en.favoriteUndoAction));
    await tester.pumpAndSettle();
    expect(find.text(roomName), findsOneWidget);
  });

  testWidgets('Room Detail loads its own availability when opened directly', (tester) async {
    final AppLocalizations en = await tester.l10n();
    await _openRoom(tester, preloadAvailability: false);
    expect(find.byTooltip(en.roomFavoriteAdd), findsOneWidget);
    expect(find.text(en.reviewNoSelectionTitle), findsNothing);
  });

  testWidgets('Room Detail without stay dates asks for them', (tester) async {
    final AppLocalizations en = await tester.l10n();
    await _openRoom(tester, withDates: false);
    expect(find.text(en.roomDetailNeedsDatesTitle), findsOneWidget);
    await tester.tap(find.text(en.roomDetailChooseDates));
    await tester.pumpAndSettle();
    expect(find.byType(StayDatesPage), findsOneWidget);
  });

  testWidgets('the Account row opens Favourites and counts rooms and hotels', (tester) async {
    final AppLocalizations en = await tester.l10n();
    final ProviderContainer c = await pumpApp(
      tester,
      bootSession: completeSession(),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();
    await c.read(favoriteRoomsProvider.notifier).toggle(
          const FavoriteRoom(
            roomTypeId: 'deluxe',
            hotelId: 'oasis',
            name: LocalizedText(ar: 'غرفة', en: 'Saved room'),
          ),
        );
    await c.read(favoriteHotelsProvider.notifier).toggle('marina');
    c.read(appRouterProvider).go(AppRoutes.account);
    await tester.pumpAndSettle();

    final Finder row = find.byKey(const ValueKey<String>('account-favorites'));
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: row, matching: find.text('2')), findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text(en.favoritesRoomsSection), findsOneWidget);
    expect(find.text(en.favoritesHotelsSection), findsOneWidget);
    expect(find.text('Saved room'), findsOneWidget);
  });

  test('room favourites are persisted through the data source', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(bootSession: completeSession()),
    );
    addTearDown(c.dispose);
    c.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    const FavoriteRoom room = FavoriteRoom(
      roomTypeId: 'r1',
      hotelId: 'h1',
      name: LocalizedText(ar: 'غرفة', en: 'Room'),
    );
    final FavoriteRoomsController favorites = c.read(favoriteRoomsProvider.notifier);
    expect(await favorites.toggle(room), FavoriteToggleOutcome.saved);
    expect(c.read(favoriteRoomsProvider), <FavoriteRoom>[room]);
    expect(await c.read(favoriteRoomsDataSourceProvider).fetch(), <FavoriteRoom>[room]);
    expect(await favorites.toggle(room), FavoriteToggleOutcome.removed);
    expect(c.read(favoriteRoomsProvider), isEmpty);
    expect(await c.read(favoriteRoomsDataSourceProvider).fetch(), isEmpty);
  });

  testWidgets('a signed-out room heart asks the guest to sign in first', (tester) async {
    final ProviderContainer c = await _openRoom(tester, signedIn: false);
    await tester.tap(find.byKey(const ValueKey<String>('room-favorite')));
    await tester.pumpAndSettle();
    expect(find.byType(RoomDetailPage), findsNothing);
    expect(c.read(favoriteRoomsProvider), isEmpty);
  });
}
