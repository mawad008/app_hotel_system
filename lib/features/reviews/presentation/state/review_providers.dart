import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/localization/content_language_provider.dart';
import '../../../../core/presentation/cache_for.dart';
import '../../../../core/time/clock.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../data/datasources/api_review_data_source.dart';
import '../../data/datasources/dummy_review_data_source.dart';
import '../../data/datasources/review_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_category.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/repositories/review_repository.dart';

/// One dummy instance holds any review submitted this session so a later fetch
/// is consistent. Kept alive.
final _dummyReviewProvider = Provider<DummyReviewDataSource>(
  (Ref ref) => DummyReviewDataSource(clock: ref.watch(clockProvider)),
);

/// Selects the reviews data source by configuration — mirrors
/// `loyaltyDataSourceProvider`.
final reviewDataSourceProvider = Provider<ReviewDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyReviewProvider)
      : ApiReviewDataSource(ref.watch(apiClientProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (Ref ref) => ReviewRepositoryImpl(ref.watch(reviewDataSourceProvider)),
);

/// The review context seeded from the authoritative reservation.
final reviewContextProvider = FutureProvider.autoDispose
    .family<ReviewContext, String>((Ref ref, String reservationId) async {
      final Reservation r = await ref.watch(
        reservationDetailProvider(reservationId).future,
      );
      return ReviewContext.forReservation(r);
    });

/// The guest's existing review for a reservation (or `null`).
final reservationReviewProvider = FutureProvider.autoDispose
    .family<Review?, String>((Ref ref, String reservationId) async {
      final ReviewContext ctx = await ref.watch(
        reviewContextProvider(reservationId).future,
      );
      return ref.watch(reviewRepositoryProvider).reviewFor(ctx);
    });

/// The active review categories of the reservation's hotel — the review form
/// adds one rating row per entry. Dynamic; possibly empty.
final reviewCategoriesProvider = FutureProvider.autoDispose
    .family<List<ReviewCategory>, String>((
      Ref ref,
      String reservationId,
    ) async {
      ref.cacheFor(CacheDurations.reference);
      final ReviewContext ctx = await ref.watch(
        reviewContextProvider(reservationId).future,
      );
      ref.watch(contentLanguageProvider); // refetch after a language switch
      return ref.watch(reviewRepositoryProvider).categoriesFor(ctx);
    });
