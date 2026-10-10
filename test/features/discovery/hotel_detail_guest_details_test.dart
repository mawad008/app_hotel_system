import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/time/hotel_time.dart';
import 'package:hotel_guest_app/core/widgets/app_icons.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_facility.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_guest_details.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/hotel_location_map.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/hotel_share.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/favorite_hotels_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/pages/favorites_page.dart';
import 'package:hotel_guest_app/features/discovery/presentation/pages/hotel_detail_page.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/hotel_detail_provider.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/hotel_service.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/stay_services_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

const String _hotelId = 'guest-details-hotel';

Hotel _hotel({
  HotelGuestDetails details = const HotelGuestDetails(),
  LocalizedText? country,
  List<HotelFacility> facilities = const <HotelFacility>[],
}) => Hotel(
  summary: const HotelSummary(
    id: _hotelId,
    name: LocalizedText(ar: 'فندق تجريبي', en: 'Test Hotel'),
    cityId: 'Jeddah',
    cityName: LocalizedText(ar: 'جدة', en: 'Jeddah'),
    tagline: LocalizedText(ar: '', en: ''),
    rating: null,
    reviewCount: null,
    nightlyRateFrom: Money(amount: 300),
    isAvailable: true,
  ),
  description: const LocalizedText(ar: '', en: ''),
  facilities: facilities,
  roomTypeCount: 2,
  photoCount: 0,
  country: country,
  details: details,
);

const HotelGuestDetails _full = HotelGuestDetails(
  checkInTime: '15:00',
  checkOutTime: '12:00',
  suitableFor: 'Families / business',
  roomsCount: 180,
  highlights: <HotelHighlight>[
    HotelHighlight(
      title: 'Outdoor pool',
      subtitle: 'Views and full facilities',
      icon: 'waves',
    ),
    HotelHighlight(title: 'Free Wi-Fi', icon: 'wifi'),
  ],
  location: HotelLocation(
    note: '10 minutes from the Corniche',
    latitude: 21.54,
    longitude: 39.17,
    nearbyPlaces: <NearbyPlace>[
      NearbyPlace(name: 'Jeddah Airport', travelMinutes: 25, icon: 'plane'),
      NearbyPlace(name: 'Old town'),
    ],
  ),
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  Hotel hotel, {
  AuthSession? session,
}) async {
  final ProviderContainer container = await pumpApp(
    tester,
    bootSession: session,
    locale: const Locale('en'),
    extraOverrides: <Override>[
      hotelDetailProvider(_hotelId).overrideWith((Ref ref) async => hotel),
      serviceCatalogueProvider(_hotelId).overrideWith(
        (Ref ref) async => const ServiceCatalogue(
          categories: <ServiceCategory>[],
          services: <HotelService>[],
        ),
      ),
    ],
  );
  container
      .read(appRouterProvider)
      .goNamed(
        AppRoutes.hotelDetailName,
        pathParameters: <String, String>{'hotelId': _hotelId},
      );
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('en'));
}

/// The page's vertical scroll view (the highlight row scrolls horizontally).
final Finder _pageScrollable = find
    .descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  testWidgets('quick info shows check-in/out, rooms and suitable-for', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(tester, _hotel(details: _full));

    expect(find.text(en.hotelInfoCheckInLabel), findsOneWidget);
    expect(find.text('3:00 PM'), findsOneWidget);
    expect(find.text(en.hotelInfoCheckOutLabel), findsOneWidget);
    expect(find.text('12:00 PM'), findsOneWidget);
    expect(find.text(en.hotelRoomCount(180)), findsOneWidget);
    expect(find.text('Families / business'), findsOneWidget);
    // The stand-in rows are not used once the real ones exist.
    expect(find.text(en.hotelInfoRoomTypesLabel), findsNothing);
  });

  testWidgets('tapping the location map opens the full-screen map', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(tester, _hotel(details: _full));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('hotel-location-map')),
      300,
      scrollable: _pageScrollable,
    );
    expect(find.byType(HotelLocationMap), findsOneWidget);
    expect(find.text(en.mapAttribution), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('hotel-location-map')));
    await tester.pumpAndSettle();

    expect(find.byType(HotelMapPage), findsOneWidget);
  });

  testWidgets('highlights and location render from the API data', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(tester, _hotel(details: _full));

    expect(find.text(en.hotelWhyChooseHeading), findsOneWidget);
    expect(find.text('Outdoor pool'), findsOneWidget);
    expect(find.text('Views and full facilities'), findsOneWidget);
    expect(find.text('Free Wi-Fi'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(en.hotelLocationHeading),
      300,
      scrollable: _pageScrollable,
    );
    expect(find.text('10 minutes from the Corniche'), findsOneWidget);
    expect(find.bySemanticsLabel(en.hotelLocationMapSemantics), findsOneWidget);
    expect(
      find.text(en.hotelNearbyPlace('Jeddah Airport', 25)),
      findsOneWidget,
    );
    expect(find.text('Old town'), findsOneWidget);
  });

  testWidgets('nothing is invented when the hotel has no detail content', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(
      tester,
      _hotel(
        country: const LocalizedText(ar: 'السعودية', en: 'Saudi Arabia'),
      ),
    );

    expect(find.text(en.hotelInfoCheckInLabel), findsNothing);
    expect(find.text(en.hotelInfoSuitableForLabel), findsNothing);
    expect(find.text(en.hotelWhyChooseHeading), findsNothing);
    expect(find.text(en.hotelLocationHeading), findsNothing);
    // Falls back to the hotel's other real facts.
    expect(find.text(en.hotelInfoRoomTypesLabel), findsOneWidget);
    expect(find.text('Saudi Arabia'), findsWidgets);
  });

  testWidgets('location without coordinates shows no map', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(
      tester,
      _hotel(
        details: const HotelGuestDetails(
          location: HotelLocation(
            nearbyPlaces: <NearbyPlace>[
              NearbyPlace(name: 'Mall', travelMinutes: 1),
            ],
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(en.hotelLocationHeading),
      300,
      scrollable: _pageScrollable,
    );
    expect(find.bySemanticsLabel(en.hotelLocationMapSemantics), findsNothing);
    expect(find.text(en.hotelNearbyPlace('Mall', 1)), findsOneWidget);
  });

  testWidgets('nearby places without a travel time show their distance', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(
      tester,
      _hotel(
        details: const HotelGuestDetails(
          location: HotelLocation(
            nearbyPlaces: <NearbyPlace>[
              NearbyPlace(
                name: 'Airport',
                category: 'airport',
                distance: 18.5,
                distanceUnit: DistanceUnit.kilometers,
              ),
              NearbyPlace(
                name: 'Beach',
                distance: 800,
                distanceUnit: DistanceUnit.meters,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(en.hotelLocationHeading),
      300,
      scrollable: _pageScrollable,
    );
    expect(find.text(en.hotelNearbyPlaceKm('Airport', '18.5')), findsOneWidget);
    expect(find.text(en.hotelNearbyPlaceMeters('Beach', '800')), findsOneWidget);
    // No icon key → the category's glyph.
    expect(find.byIcon(AppIcons.forNearbyCategory('airport')), findsOneWidget);
  });

  testWidgets('facilities render the operator icon and description', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(
      tester,
      _hotel(
        facilities: const <HotelFacility>[
          HotelFacility(
            key: 'valet',
            label: LocalizedText(ar: 'صف السيارات', en: 'Valet parking'),
            description: LocalizedText(ar: 'متاح', en: 'Available 24/7'),
            icon: 'parking',
          ),
          HotelFacility(
            key: 'custom',
            label: LocalizedText(ar: 'مخصص', en: 'Custom'),
            icon: 'not-a-known-icon',
          ),
        ],
      ),
    );

    await tester.scrollUntilVisible(
      find.text(en.hotelDetailAmenities),
      300,
      scrollable: _pageScrollable,
    );
    expect(find.text('Valet parking'), findsOneWidget);
    expect(find.text('Available 24/7'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.byIcon(AppIcons.forDetailKey('parking')), findsOneWidget);
  });

  group('formatHotelTime', () {
    test('formats 24h times with a localized period', () async {
      final AppLocalizations en = await AppLocalizations.delegate.load(
        const Locale('en'),
      );
      final AppLocalizations ar = await AppLocalizations.delegate.load(
        const Locale('ar'),
      );
      expect(formatHotelTime('15:00', en), '3:00 PM');
      expect(formatHotelTime('00:30', en), '12:30 AM');
      // Midday is "ظهرًا" (Figma ROOM_Detail: "12:00 ظهراً"), not evening.
      expect(formatHotelTime('12:00', ar), '12:00 ظهرًا');
      expect(formatHotelTime('12:30', en), '12:30 PM');
      expect(formatHotelTime('13:00', ar), '1:00 مساءً');
      expect(formatHotelTime('09:05', ar), '9:05 صباحًا');
      expect(formatHotelTime(null, en), isNull);
      expect(formatHotelTime('25:00', en), isNull);
      expect(formatHotelTime('abc', en), isNull);
    });
  });

  group('HotelModel.parseGuestDetails', () {
    test('parses every field and skips blank rows', () {
      final HotelGuestDetails d = HotelModel.parseGuestDetails(
        <String, Object?>{
          'check_in_time': '15:00',
          'check_out_time': '12:00',
          'suitable_for': '  ',
          'rooms_count': 3,
          'highlights': <Object?>[
            <String, Object?>{
              'icon': 'waves',
              'title': 'Pool',
              'subtitle': null,
            },
            <String, Object?>{'icon': 'x', 'title': ''},
          ],
          'location': <String, Object?>{
            'note': 'Near the sea',
            'latitude': 21.5,
            'longitude': '39.1',
            'nearby_places': <Object?>[
              <String, Object?>{
                'icon': 'plane',
                'name': 'Airport',
                'travel_minutes': 25,
              },
              <String, Object?>{'name': null},
            ],
          },
        },
      );

      expect(d.checkInTime, '15:00');
      expect(d.suitableFor, isNull);
      expect(d.roomsCount, 3);
      expect(d.highlights, const <HotelHighlight>[
        HotelHighlight(title: 'Pool', icon: 'waves'),
      ]);
      expect(d.location!.hasCoordinates, isTrue);
      expect(d.location!.longitude, 39.1);
      expect(d.location!.nearbyPlaces, const <NearbyPlace>[
        NearbyPlace(name: 'Airport', travelMinutes: 25, icon: 'plane'),
      ]);
    });

    test('parses nearby place category, distance and pin', () {
      final HotelGuestDetails d = HotelModel.parseGuestDetails(
        <String, Object?>{
          'location': <String, Object?>{
            'nearby_places': <Object?>[
              <String, Object?>{
                'name': 'Airport',
                'category': 'airport',
                'distance': 18.5,
                'distance_unit': 'km',
                'latitude': 21.68,
                'longitude': 39.16,
              },
              // Unknown unit → no distance; half a pin → no pin.
              <String, Object?>{
                'name': 'Mall',
                'distance': 3,
                'distance_unit': 'mi',
                'latitude': 21.5,
              },
            ],
          },
        },
      );

      expect(d.location!.nearbyPlaces, const <NearbyPlace>[
        NearbyPlace(
          name: 'Airport',
          category: 'airport',
          distance: 18.5,
          distanceUnit: DistanceUnit.kilometers,
          latitude: 21.68,
          longitude: 39.16,
        ),
        NearbyPlace(name: 'Mall'),
      ]);
    });

    test('an empty payload yields empty details', () {
      final HotelGuestDetails d = HotelModel.parseGuestDetails(
        <String, Object?>{},
      );
      expect(d, const HotelGuestDetails());
      expect(d.location, isNull);
    });
  });

  testWidgets('the hero favourite button saves and removes the hotel', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(
      tester,
      _hotel(details: _full),
      session: completeSession(),
    );

    expect(find.byIcon(AppIcons.favorite), findsOneWidget);
    expect(find.byTooltip(en.hotelShare), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('hotel-favorite')));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.favoriteActive), findsOneWidget);
    expect(find.byTooltip(en.hotelFavoriteRemove), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('hotel-favorite')));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.favorite), findsOneWidget);
  });

  testWidgets('a saved hotel is listed under Favourites and can be removed there', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await _pump(
      tester,
      _hotel(details: _full),
      session: completeSession(),
    );

    await tester.tap(find.byKey(const ValueKey<String>('hotel-favorite')));
    await tester.pumpAndSettle();
    expect(find.text(en.favoriteSavedSnack), findsOneWidget);

    // The snackbar leads to the list, so the heart never ends nowhere.
    await tester.tap(find.text(en.favoriteViewAction));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text('Test Hotel'), findsOneWidget);
    expect(find.text('Jeddah'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('favorite-remove-$_hotelId')));
    await tester.pumpAndSettle();
    expect(find.text(en.favoritesEmptyTitle), findsOneWidget);

    // Undo puts it back.
    await tester.tap(find.text(en.favoriteUndoAction));
    await tester.pumpAndSettle();
    expect(find.text('Test Hotel'), findsOneWidget);

    // Tapping the row opens the hotel.
    await tester.tap(find.text('Test Hotel'));
    await tester.pumpAndSettle();
    expect(find.byType(HotelDetailPage), findsOneWidget);
  });

  testWidgets('a signed-out heart tap asks the guest to sign in first', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _hotel(details: _full));
    await tester.tap(find.byKey(const ValueKey<String>('hotel-favorite')));
    await tester.pumpAndSettle();
    expect(find.byType(HotelDetailPage), findsNothing);
  });

  test('favourites are persisted through the data source, per hotel', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(bootSession: completeSession()),
    );
    addTearDown(c.dispose);
    // Let the session restore.
    c.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(await c.read(favoriteHotelsProvider.notifier).toggle('a'), FavoriteToggleOutcome.saved);
    expect(c.read(favoriteHotelsProvider), <String>{'a'});
    expect(await c.read(favoriteHotelsDataSourceProvider).fetchIds(), <String>{'a'});
    expect(await c.read(favoriteHotelsProvider.notifier).toggle('a'), FavoriteToggleOutcome.removed);
    expect(c.read(favoriteHotelsProvider), isEmpty);
    expect(await c.read(favoriteHotelsDataSourceProvider).fetchIds(), isEmpty);
  });

  test('share text carries name, location and a map link', () {
    expect(
      hotelShareText(name: 'فندق الواحة', location: 'جدة', latitude: 21.56, longitude: 39.15),
      'فندق الواحة\nجدة\nhttps://www.google.com/maps/search/?api=1&query=21.56,39.15',
    );
    expect(hotelShareText(name: 'X', location: ''), 'X');
  });

  test('facility icons fall back to the Figma glyph for the catalog key', () {
    expect(AppIcons.forFacility(null, 'reception_24h'), AppIcons.forDetailKey('headset'));
    expect(AppIcons.forFacility('wifi', 'elevator'), AppIcons.forDetailKey('wifi'));
    expect(AppIcons.forFacility(null, 'unknown'), AppIcons.detailCheck);
  });
}
