import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_facility.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_review_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/hotel_detail_provider.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/detail_premium.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/hotel_service.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/stay_services_providers.dart';

import '../../support/pump_app.dart';

const String _hotelId = 'review-summary-hotel';

Hotel _hotelWith({HotelReviewSummary? summary}) => Hotel(
  summary: const HotelSummary(
    id: _hotelId,
    name: LocalizedText(ar: 'فندق تجريبي', en: 'Test Hotel'),
    cityId: 'Riyadh',
    cityName: LocalizedText(ar: 'الرياض', en: 'Riyadh'),
    tagline: LocalizedText(ar: '', en: ''),
    rating: 4.6,
    reviewCount: 120,
    nightlyRateFrom: Money(amount: 300),
    isAvailable: true,
  ),
  description: const LocalizedText(ar: '', en: ''),
  facilities: const <HotelFacility>[],
  roomTypeCount: 0,
  photoCount: 0,
  reviewSummary: summary,
);

/// A summary with [n] rated categories named by [names] (dynamic — the test
/// invents arbitrary labels to prove nothing is hardcoded).
HotelReviewSummary _summary(List<String> names, {int count = 12}) =>
    HotelReviewSummary(
      average: 4.5,
      count: count,
      categories: <ReviewCategoryScore>[
        for (int i = 0; i < names.length; i++)
          ReviewCategoryScore(
            id: '${100 + i}',
            label: names[i],
            average: 3.0 + (i % 3) * 0.5,
            ratingsCount: 5 + i,
          ),
      ],
    );

Future<void> _pump(WidgetTester tester, Hotel hotel) async {
  final ProviderContainer container = await pumpApp(
    tester,
    locale: const Locale('en'),
    extraOverrides: <Override>[
      hotelDetailProvider(_hotelId).overrideWith((Ref ref) async => hotel),
      // No hotel services: only the review-category rows are rating rows.
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
}

void main() {
  testWidgets('renders one rating row per dynamic category — 2 categories', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    await _pump(
      tester,
      _hotelWith(summary: _summary(<String>['Rooms', 'Breakfast'])),
    );

    expect(find.text(en.hotelDetailReviewsHeading), findsOneWidget);
    expect(find.byType(DetailRatingRow), findsNWidgets(2));
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text(en.hotelReviewCount(12)), findsOneWidget);
  });

  const List<String> eight = <String>[
    'جودة الغرف',
    'الإفطار',
    'النظافة',
    'تعامل الموظفين',
    'الموقع',
    'الهدوء',
    'المسبح',
    'القيمة مقابل السعر',
  ];

  testWidgets('works for 5 categories', (WidgetTester tester) async {
    await _pump(tester, _hotelWith(summary: _summary(eight.sublist(0, 5))));
    expect(find.byType(DetailRatingRow), findsNWidgets(5));
  });

  testWidgets('works for 8 categories with the backend labels as-is', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _hotelWith(summary: _summary(eight)));
    expect(find.byType(DetailRatingRow), findsNWidgets(8));
    for (final String label in eight) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows each category average to one decimal', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _hotelWith(
        summary: const HotelReviewSummary(
          average: 4.0,
          count: 3,
          categories: <ReviewCategoryScore>[
            ReviewCategoryScore(
              id: '7',
              label: 'Comfort',
              average: 4.25,
              ratingsCount: 3,
            ),
          ],
        ),
      ),
    );
    final Finder row = find.byType(DetailRatingRow);
    expect(
      find.descendant(of: row, matching: find.text('4.3')),
      findsOneWidget,
    );
  });

  testWidgets('an unrated category is not drawn as a bar', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _hotelWith(
        summary: const HotelReviewSummary(
          average: 4.0,
          count: 3,
          categories: <ReviewCategoryScore>[
            ReviewCategoryScore(
              id: '1',
              label: 'Rated',
              average: 4.0,
              ratingsCount: 3,
            ),
            ReviewCategoryScore(id: '2', label: 'New one', ratingsCount: 0),
          ],
        ),
      ),
    );
    expect(find.byType(DetailRatingRow), findsOneWidget);
    expect(find.text('New one'), findsNothing);
  });

  testWidgets('omits the section when the hotel has no summary', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    await _pump(tester, _hotelWith());
    expect(find.text(en.hotelDetailReviewsHeading), findsNothing);
  });

  testWidgets('omits the section while nothing has been rated', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    await _pump(
      tester,
      _hotelWith(
        summary: const HotelReviewSummary(
          average: null,
          count: 0,
          categories: <ReviewCategoryScore>[
            ReviewCategoryScore(id: '1', label: 'Unrated', ratingsCount: 0),
          ],
        ),
      ),
    );
    expect(find.text(en.hotelDetailReviewsHeading), findsNothing);
  });

  test('parses review_summary from the API into dynamic categories', () {
    final HotelReviewSummary? s = HotelModel.parseReviewSummary(
      <String, Object?>{
        'average': 4.62,
        'count': 128,
        'categories': <Object?>[
          <String, Object?>{
            'id': 12,
            'label': 'النظافة',
            'icon': null,
            'average': 4.7,
            'ratings_count': 96,
          },
          <String, Object?>{
            'id': 15,
            'label': 'الإفطار',
            'icon': 'coffee',
            'average': null,
            'ratings_count': 0,
          },
        ],
      },
    );
    expect(s, isNotNull);
    expect(s!.average, 4.62);
    expect(s.count, 128);
    expect(s.categories.map((ReviewCategoryScore c) => c.id), <String>[
      '12',
      '15',
    ]);
    expect(s.categories.first.label, 'النظافة');
    expect(s.categories.last.icon, 'coffee');
    expect(s.ratedCategories.length, 1);
    expect(HotelModel.parseReviewSummary(null), isNull);
  });
}
