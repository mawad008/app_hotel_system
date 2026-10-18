import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../notifications/presentation/state/notifications_providers.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../../reservation/presentation/state/reservation_providers.dart';
import '../../domain/bookings_filter.dart';

/// The guest's own reservations, newest first — backs the Bookings tab and
/// the Account screen's derived stats (previous stays, trusted-guest,
/// preferences).
final bookingsListProvider = FutureProvider.autoDispose<List<Reservation>>(
  (Ref ref) {
  // Refetch in the new language after a language switch.
  ref.watch(contentLanguageProvider);
    return ref.watch(reservationRepositoryProvider).list();
  },
);

/// Refetches everything that shows the guest's reservations after an action
/// that changed one (book, pay, verify, check in, extend, check out, cancel,
/// redeem): the Bookings tab, what derives from it (STAY_Home's current stay,
/// the Account stats), the notifications feed + bell badge (the backend
/// notifies the guest on these events), and — given [reservationId] — that
/// reservation's detail.
///
/// Call it on every successful reservation mutation rather than relying on
/// `autoDispose`: a root tab page can stay mounted underneath a pushed flow
/// (and `go` back to it reuses that page), so its list would otherwise keep
/// the pre-action snapshot until a manual refresh or an app restart.
///
/// Takes the caller's `invalidate` so both a `Ref` (controllers) and a
/// `WidgetRef` (pages) can use it.
void refreshGuestReservations(
  void Function(ProviderOrFamily provider) invalidate, {
  String? reservationId,
}) {
  invalidate(bookingsListProvider);
  invalidate(notificationFeedProvider);
  if (reservationId != null) invalidate(reservationDetailProvider(reservationId));
}

/// The selected pill on the Bookings tab. Local UI state — resets to
/// [BookingsFilter.current] whenever the page is rebuilt fresh.
final bookingsFilterProvider =
    StateProvider.autoDispose<BookingsFilter>((Ref ref) => BookingsFilter.current);
