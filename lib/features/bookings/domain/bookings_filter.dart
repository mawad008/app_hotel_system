import '../../reservation/domain/entities/reservation.dart';
import '../../reservation/domain/entities/reservation_status.dart';

/// The Bookings tab's three-pill filter (`docs/design-system.md` — "a
/// bookings list with الحالية/القادمة/السابقة tabs"). Presentation-only
/// classification of the guest's own [Reservation]s — it invents no backend
/// state, it only groups the statuses the backend already returns.
enum BookingsFilter { current, upcoming, past }

/// Statuses the guest is currently occupying the room for — including a
/// checkout that has started or is blocked (e.g. an outstanding balance): the
/// guest is still in the room and must be able to find the booking to finish.
const Set<ReservationStatus> _ongoingStatuses = <ReservationStatus>{
  ReservationStatus.checkedIn,
  ReservationStatus.inStay,
  ReservationStatus.checkoutInProgress,
  ReservationStatus.checkoutBlocked,
};

/// Statuses for a booking that has not started yet but is still live
/// (secured or on its way to being secured).
const Set<ReservationStatus> _upcomingStatuses = <ReservationStatus>{
  ReservationStatus.pending,
  ReservationStatus.depositHeld,
  ReservationStatus.verified,
};

/// Historical statuses — the stay has ended one way or another.
const Set<ReservationStatus> _pastStatuses = <ReservationStatus>{
  ReservationStatus.checkedOut,
  ReservationStatus.invoiced,
  ReservationStatus.cancelled,
};

extension ReservationBookingsClassification on Reservation {
  bool get isOngoingStay => _ongoingStatuses.contains(status);
  bool get isUpcomingBooking => _upcomingStatuses.contains(status);
  bool get isPastBooking => _pastStatuses.contains(status);
}
