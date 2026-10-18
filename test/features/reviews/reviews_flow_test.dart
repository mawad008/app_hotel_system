import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/reviews/data/datasources/dummy_review_data_source.dart';
import 'package:hotel_guest_app/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:hotel_guest_app/features/reviews/presentation/state/review_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'reviews_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 11);

class _ReservationRepo implements ReservationRepository {
  _ReservationRepo(this.status);
  final ReservationStatus status;
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: status);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: status);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<void> _openReview(
  WidgetTester tester,
  String id, {
  ReservationStatus status = ReservationStatus.checkedOut,
  Locale? locale,
}) async {
  final ds = DummyReviewDataSource(clock: () => _now);
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reviewDataSourceProvider.overrideWithValue(ds),
      reviewRepositoryProvider.overrideWithValue(ReviewRepositoryImpl(ds)),
      reservationRepositoryProvider.overrideWithValue(_ReservationRepo(status)),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$id/review');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rate → submit → processing → "thanks" result (pending)',
      (tester) async {
    final en = await _l10n('en');
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    await _openReview(tester, id);

    expect(find.text(en.reviewFormPrompt), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(en.reviewStarsLabel(5)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.reviewSubmitCta));
    await tester.pumpAndSettle();

    expect(find.text(en.reviewSubmittedTitle), findsOneWidget);
    expect(find.text(en.reviewPendingModerationBody), findsOneWidget);
  });

  testWidgets('submitting without a rating shows the validation message',
      (tester) async {
    final en = await _l10n('en');
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    await _openReview(tester, id);

    await tester.tap(find.widgetWithText(FilledButton, en.reviewSubmitCta));
    await tester.pumpAndSettle();

    expect(find.text(en.reviewRatingRequired), findsOneWidget);
    expect(find.text(en.reviewSubmittedTitle), findsNothing);
  });

  testWidgets('an already-reviewed stay shows the existing review read-only',
      (tester) async {
    final en = await _l10n('en');
    final id = reviewScenarioId(DummyReviewScenario.alreadyReviewedPending);
    await _openReview(tester, id);

    expect(find.text(en.reviewAlreadyTitle), findsOneWidget);
    expect(find.text(en.reviewPendingModerationBody), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.reviewSubmitCta), findsNothing);
  });

  testWidgets('a non-completed stay cannot be reviewed', (tester) async {
    final en = await _l10n('en');
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    await _openReview(tester, id, status: ReservationStatus.checkedIn);

    expect(find.text(en.reviewNotEligibleTitle), findsOneWidget);
  });

  testWidgets('renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    await _openReview(tester, id, locale: arabic);
    expect(
      Directionality.of(tester.element(find.text(ar.reviewFormPrompt))),
      TextDirection.rtl,
    );
  });
}
