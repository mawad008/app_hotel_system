import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';
import 'package:hotel_guest_app/features/reviews/data/datasources/dummy_review_data_source.dart';
import 'package:hotel_guest_app/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_category.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_draft.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/submit_review.dart';
import 'package:hotel_guest_app/features/reviews/presentation/state/review_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'reviews_test_support.dart';

/// Serves whatever categories a test gives it and records what is submitted —
/// the form must work for any list, without knowing any category.
class _CategorySource extends DummyReviewDataSource {
  _CategorySource(this.categories) : super(clock: () => DateTime(2026, 9, 8));

  final List<ReviewCategory> categories;
  final List<SubmitReviewRequest> submitted = <SubmitReviewRequest>[];
  String? askedHotelId;

  @override
  Future<List<ReviewCategory>> fetchCategories(ReviewContext context) async {
    askedHotelId = context.hotelId;
    return categories;
  }

  @override
  Future<SubmitReviewResult> submit(
    SubmitReviewRequest request,
    ReviewContext context,
  ) {
    submitted.add(request);
    return super.submit(request, context);
  }
}

class _ReservationRepo implements ReservationRepository {
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: ReservationStatus.checkedOut);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: ReservationStatus.checkedOut);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];
  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);
  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async =>
      throw UnimplementedError();
}

Future<_CategorySource> _open(
  WidgetTester tester,
  List<ReviewCategory> categories,
) async {
  final _CategorySource ds = _CategorySource(categories);
  final ProviderContainer c = await pumpApp(
    tester,
    bootSession: completeSession(),
    extraOverrides: <Override>[
      reviewDataSourceProvider.overrideWithValue(ds),
      reviewRepositoryProvider.overrideWithValue(ReviewRepositoryImpl(ds)),
      reservationRepositoryProvider.overrideWithValue(_ReservationRepo()),
    ],
  );
  final String id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
  c.read(appRouterProvider).go('/reservation/$id/review');
  await tester.pumpAndSettle();
  return ds;
}

/// The `n`-star button inside the row labelled [label].
Finder _star(String label, int n, AppLocalizations en) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
  matching: find.bySemanticsLabel(en.reviewStarsLabel(n)),
);

void main() {
  testWidgets('builds one rating row per category the hotel defines', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    final _CategorySource ds = await _open(tester, const <ReviewCategory>[
      ReviewCategory(id: '19', label: 'Pool'),
      ReviewCategory(id: '12', label: 'Staff'),
      ReviewCategory(id: '77', label: 'Noise'),
    ]);

    expect(ds.askedHotelId, 'oasis'); // the reservation's own hotel
    expect(find.text(en.reviewCategoriesHeading), findsOneWidget);
    expect(find.text('Pool'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Noise'), findsOneWidget);
  });

  testWidgets('submits the ratings given to dynamic categories', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    final _CategorySource ds = await _open(tester, const <ReviewCategory>[
      ReviewCategory(id: '19', label: 'Pool'),
      ReviewCategory(id: '77', label: 'Noise'),
    ]);

    // Overall rating: the first (largest) selector.
    await tester.tap(find.bySemanticsLabel(en.reviewStarsLabel(4)).first);
    await tester.tap(_star('Pool', 5, en));
    await tester.tap(_star('Noise', 2, en));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.reviewSubmitCta));
    await tester.pumpAndSettle();

    expect(ds.submitted, hasLength(1));
    expect(ds.submitted.single.rating, 4);
    expect(ds.submitted.single.categoryRatings, <String, int>{
      '19': 5,
      '77': 2,
    });
  });

  testWidgets('with no categories the form is just the overall rating', (
    WidgetTester tester,
  ) async {
    final AppLocalizations en = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    await _open(tester, const <ReviewCategory>[]);

    expect(find.text(en.reviewFormPrompt), findsOneWidget);
    expect(find.text(en.reviewCategoriesHeading), findsNothing);
  });
}
