import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_facility.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/hotel_detail_provider.dart';

import '../../support/pump_app.dart';

const String _hotelId = 'hero-carousel-test-hotel';
const List<String> _photos = <String>[
  'https://example.test/photo-0.jpg',
  'https://example.test/photo-1.jpg',
  'https://example.test/photo-2.jpg',
];

final Hotel _fakeHotel = Hotel(
  summary: const HotelSummary(
    id: _hotelId,
    name: LocalizedText(ar: 'فندق تجريبي', en: 'Test Hotel'),
    cityId: 'Riyadh',
    cityName: LocalizedText(ar: 'الرياض', en: 'Riyadh'),
    tagline: LocalizedText(ar: '', en: ''),
    rating: null,
    reviewCount: null,
    nightlyRateFrom: Money(amount: 300),
    isAvailable: true,
  ),
  description: const LocalizedText(ar: '', en: ''),
  facilities: const <HotelFacility>[],
  roomTypeCount: 0,
  photoCount: _photos.length,
  galleryUrls: _photos,
);

/// Locates the [Image] for [url] rendered as the swipeable hero (inside the
/// `PageView`), as distinct from the same URL's copy in the thumbnail strip
/// below (which is not inside a `PageView`).
Finder _heroImage(String url) => find.descendant(
      of: find.byType(PageView),
      matching: find.byWidgetPredicate(
        (Widget w) => w is Image && (w.image as NetworkImage).url == url,
      ),
    );

Future<ProviderContainer> _pumpHotelDetail(WidgetTester tester) async {
  final ProviderContainer container = await pumpApp(
    tester,
    locale: const Locale('en'),
    extraOverrides: <Override>[
      hotelDetailProvider(_hotelId).overrideWith((Ref ref) async => _fakeHotel),
    ],
  );
  container.read(appRouterProvider).goNamed(
        AppRoutes.hotelDetailName,
        pathParameters: <String, String>{'hotelId': _hotelId},
      );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('the hero starts on the first photo', (WidgetTester tester) async {
    await _pumpHotelDetail(tester);

    expect(_heroImage(_photos[0]), findsOneWidget);
    expect(_heroImage(_photos[1]), findsNothing);
  });

  testWidgets('the v2 photo counter follows the hero (no thumbnail strip)',
      (WidgetTester tester) async {
    await _pumpHotelDetail(tester);

    // `HOTEL_Detail_Premium` replaces the thumbnail strip with a `1/N` pill.
    expect(find.text('1/${_photos.length}'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('2/${_photos.length}'), findsOneWidget);
  });

  testWidgets('swiping the hero moves to the next photo',
      (WidgetTester tester) async {
    final ProviderContainer container = await _pumpHotelDetail(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(container.read(heroPhotoIndexProvider(_hotelId)), 1);
    expect(_heroImage(_photos[1]), findsOneWidget);
  });
}
