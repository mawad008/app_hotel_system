import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/reviews/data/datasources/dummy_review_data_source.dart';
import 'package:hotel_guest_app/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_draft.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/submit_review.dart';
import 'package:hotel_guest_app/features/reviews/presentation/state/review_providers.dart';
import 'package:hotel_guest_app/features/reviews/presentation/state/review_submission_controller.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

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

ProviderContainer _container({
  ReservationStatus status = ReservationStatus.checkedOut,
  DummyReviewDataSource? source,
}) {
  final ds = source ?? DummyReviewDataSource(clock: () => _now);
  final c = ProviderContainer(overrides: <Override>[
    reviewDataSourceProvider.overrideWithValue(ds),
    reviewRepositoryProvider.overrideWithValue(ReviewRepositoryImpl(ds)),
    reservationRepositoryProvider.overrideWithValue(_ReservationRepo(status)),
  ]);
  addTearDown(c.dispose);
  c.listen(reviewSubmissionControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('idle → submitting → done (submitted)', () async {
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    final c = _container();
    expect(c.read(reviewSubmissionControllerProvider), isA<ReviewIdle>());

    await c.read(reviewSubmissionControllerProvider.notifier).submit(
          id,
          const ReviewDraft(rating: 5, text: 'Great'),
        );

    final state = c.read(reviewSubmissionControllerProvider);
    expect(state, isA<ReviewSubmitDone>());
    expect(state.resultOrNull!.outcome, ReviewSubmitOutcome.submitted);
  });

  test('a second submit of the same draft is ignored (double-tap safe)',
      () async {
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    final c = _container();
    final n = c.read(reviewSubmissionControllerProvider.notifier);
    const draft = ReviewDraft(rating: 4);
    await n.submit(id, draft);
    final first = c.read(reviewSubmissionControllerProvider).resultOrNull;
    await n.submit(id, draft);
    final second = c.read(reviewSubmissionControllerProvider).resultOrNull;
    expect(identical(first, second), isTrue);
  });

  test('an already-reviewed reservation resolves to alreadyReviewed', () async {
    final id = reviewScenarioId(DummyReviewScenario.alreadyReviewedPending);
    final c = _container();
    await c
        .read(reviewSubmissionControllerProvider.notifier)
        .submit(id, const ReviewDraft(rating: 3));
    expect(c.read(reviewSubmissionControllerProvider).resultOrNull!.outcome,
        ReviewSubmitOutcome.alreadyReviewed);
  });

  test('a not-eligible stay is a blocked done, not a Failure', () async {
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    final c = _container(status: ReservationStatus.checkedIn);
    await c
        .read(reviewSubmissionControllerProvider.notifier)
        .submit(id, const ReviewDraft(rating: 4));
    final state = c.read(reviewSubmissionControllerProvider);
    expect(state, isA<ReviewSubmitDone>());
    expect(state.resultOrNull!.outcome, ReviewSubmitOutcome.notEligible);
  });

  test('on a successful submit the existing-review provider is re-read',
      () async {
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    final c = _container();
    expect(await c.read(reservationReviewProvider(id).future), isNull);

    await c
        .read(reviewSubmissionControllerProvider.notifier)
        .submit(id, const ReviewDraft(rating: 5));

    final Review? review = await c.read(reservationReviewProvider(id).future);
    expect(review, isNotNull);
    expect(review!.rating, 5);
  });

  test('an infrastructure failure surfaces and an edited re-submit recovers',
      () async {
    final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
    final ds = DummyReviewDataSource(clock: () => _now)
      ..failWith = const NetworkException();
    final c = _container(source: ds);
    final n = c.read(reviewSubmissionControllerProvider.notifier);

    await n.submit(id, const ReviewDraft(rating: 4));
    expect(c.read(reviewSubmissionControllerProvider), isA<ReviewSubmitFailed>());

    ds.failWith = null;
    await n.submit(id, const ReviewDraft(rating: 5)); // different request
    expect(c.read(reviewSubmissionControllerProvider), isA<ReviewSubmitDone>());
  });
}
