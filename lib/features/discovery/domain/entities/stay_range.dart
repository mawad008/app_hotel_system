import 'package:flutter/foundation.dart';

/// Strips any time component, keeping the local calendar day.
DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// Whole calendar days from [from] to [to], ignoring the time of day.
///
/// Counted on UTC dates: local midnights are 23 or 25 hours apart on a
/// daylight-saving change (e.g. Egypt in spring and autumn), so a plain
/// `difference().inDays` would drop or add a night.
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// The calendar day [days] after [date] (midnight), safe across
/// daylight-saving changes, unlike adding a 24-hour `Duration`.
DateTime addCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// A confirmed check-in / check-out pair (`16 · Stay dates & available rooms`).
///
/// Both dates are calendar days (no time component). Check-out is always strictly
/// after check-in, so a stay is at least one night and a same-day checkout is
/// impossible — this is the only stay rule the app enforces. It carries no
/// booking policy such as a minimum/maximum stay or an advance-booking window,
/// none of which the approved baseline defines. Later phases (reservations,
/// the availability API) consume this value unchanged.
@immutable
class StayRange {
  StayRange({required DateTime checkIn, required DateTime checkOut})
      : checkIn = dateOnly(checkIn),
        checkOut = dateOnly(checkOut) {
    assert(
      this.checkOut.isAfter(this.checkIn),
      'StayRange requires check-out to be after check-in (got $checkIn → $checkOut)',
    );
  }

  /// Builds a range, or returns `null` when the dates do not form a valid stay
  /// (missing, or check-out not after check-in). Prefer this at boundaries where
  /// the input is not already validated (e.g. parsing an API response).
  static StayRange? tryCreate({DateTime? checkIn, DateTime? checkOut}) {
    if (checkIn == null || checkOut == null) return null;
    if (!dateOnly(checkOut).isAfter(dateOnly(checkIn))) return null;
    return StayRange(checkIn: checkIn, checkOut: checkOut);
  }

  final DateTime checkIn;
  final DateTime checkOut;

  /// Number of nights between the two dates. Always `>= 1`.
  int get nights => calendarDaysBetween(checkIn, checkOut);

  @override
  bool operator ==(Object other) =>
      other is StayRange &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut;

  @override
  int get hashCode => Object.hash(checkIn, checkOut);

  @override
  String toString() =>
      'StayRange(${checkIn.toIso8601String()} → ${checkOut.toIso8601String()})';
}
