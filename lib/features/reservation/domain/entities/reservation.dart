import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/guest_party.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../../discovery/domain/entities/stay_range.dart';
import 'reservation_status.dart';

/// A reservation as the guest app knows it.
///
/// Mirrors the fields of the Laravel `ReservationResource` the guest surface
/// needs (`id`, `hotel_id`, `room_type_id`, `room_id`, `check_in`, `check_out`,
/// `status`, `price_snapshot`, `created_at`). Laravel remains authoritative for
/// the status and the price (mobile/docs/architecture.md §6); the app never
/// transitions the status itself.
///
/// [hotelName] / [roomName] are display snapshots carried from the create
/// request so the confirmation screen renders without another round-trip.
///
/// [hotelCity] / [hotelImageUrl] mirror the guest reservation resource's
/// `hotel.city` / `hotel.cover_url` (present once the hotel is eager-loaded).
/// [roomNumber] mirrors `room.room_number` — the physically allocated room,
/// set once one is assigned / at check-in. [nightlyRate] mirrors
/// `room_type.base_price` — the authoritative nightly rate Extend Stay prices
/// from and the Account screen's loyalty-card "per night" figure reads.
/// The backend's cancellation decision (approved policy, 2026-09-26): the
/// app shows the cancel action and the refund text from this alone.
@immutable
class CancellationState {
  const CancellationState({
    required this.allowed,
    required this.fullRefund,
    required this.refundable,
    this.freeUntil,
    this.reason,
  });

  /// Nothing known (e.g. dummy data without a policy) — not cancellable.
  static const CancellationState unknown =
      CancellationState(allowed: false, fullRefund: false, refundable: false);

  final bool allowed;
  final bool fullRefund;
  final bool refundable;
  final DateTime? freeUntil;

  /// Machine reason when not allowed (`non_refundable_rate`,
  /// `free_cancellation_window_closed`, `status_not_cancellable`).
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is CancellationState &&
      other.allowed == allowed &&
      other.fullRefund == fullRefund &&
      other.refundable == refundable &&
      other.freeUntil == freeUntil &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(allowed, fullRefund, refundable, freeUntil, reason);
}

/// The backend's self check-in availability (hotel check-in mode, payment,
/// identity, room assignment, stay window).
@immutable
class CheckInAvailability {
  const CheckInAvailability({required this.allowed, this.reason, this.mode});

  static const CheckInAvailability unknown = CheckInAvailability(allowed: false);

  final bool allowed;

  /// `room_not_assigned`, `check_in_channel_not_allowed`, `identity_not_verified`, …
  final String? reason;

  /// Hotel mode: `self` / `reception` / `both`.
  final String? mode;

  @override
  bool operator ==(Object other) =>
      other is CheckInAvailability && other.allowed == allowed && other.reason == reason && other.mode == mode;

  @override
  int get hashCode => Object.hash(allowed, reason, mode);
}

@immutable
class Reservation {
  const Reservation({
    required this.id,
    required this.reference,
    required this.hotelId,
    required this.hotelName,
    required this.roomTypeId,
    required this.roomName,
    required this.stay,
    required this.party,
    required this.status,
    required this.priceSnapshot,
    required this.createdAt,
    this.roomId,
    this.hotelCity,
    this.hotelImageUrl,
    this.hotelReceptionPhone,
    this.hotelCheckInTime,
    this.roomNumber,
    this.nightlyRate,
    this.depositAmount,
    this.serviceFee,
    this.tax,
    this.taxRate,
    this.pricesIncludeTaxes,
    this.cancelledAt,
    this.cancellation = CancellationState.unknown,
    this.checkInAvailability = CheckInAvailability.unknown,
  });

  /// The backend primary key (as a string at the mobile boundary).
  final String id;

  /// A human-facing confirmation code shown to the guest.
  final String reference;

  final String hotelId;
  final LocalizedText hotelName;
  final String roomTypeId;
  final LocalizedText roomName;
  final String? roomId;
  final StayRange stay;
  final GuestParty party;
  final ReservationStatus status;

  /// The authoritative total the backend recorded for this reservation.
  final Money priceSnapshot;
  final DateTime createdAt;

  final String? hotelCity;
  final String? hotelImageUrl;

  /// The hotel's front-desk phone (`hotel.reception_phone`) — what the
  /// "تواصل مع الاستقبال" actions dial. Null when the hotel has none on file.
  final String? hotelReceptionPhone;

  /// The hotel's check-in time (`hotel.check_in_time`, `HH:mm`), if set.
  final String? hotelCheckInTime;
  final String? roomNumber;
  final Money? nightlyRate;

  /// The deposit hold this booking will take (`hotel.deposit_amount`,
  /// server-computed from the hotel's percentage). Null when unknown.
  final Money? depositAmount;

  /// The hotel's booking service fee, snapshotted when the booking was made
  /// (`service_fee_amount`); `null` when none.
  final Money? serviceFee;

  /// The booking tax (`tax_amount`: the snapshotted `tax_rate` % of the stay
  /// + service fee, server-computed); `null` when none.
  final Money? tax;

  /// The tax % snapshotted at booking (`tax_rate`); `null` when none.
  final num? taxRate;

  /// The hotel's `prices_include_taxes` flag: `true` when the room rate
  /// already includes taxes, `false` when the hotel's tax rate (if any) is
  /// added on top as [tax], `null` when unknown.
  final bool? pricesIncludeTaxes;

  /// What the guest pays for the booking: the stay plus service fee and tax.
  Money get totalToPay => serviceFee == null && tax == null
      ? priceSnapshot
      : Money(
          amount: ((priceSnapshot.amount +
                          (serviceFee?.amount ?? 0) +
                          (tax?.amount ?? 0)) *
                      100)
                  .round() /
              100,
          currency: priceSnapshot.currency,
        );

  /// Mirrors the resource's `cancelled_at` — set only once the reservation is
  /// actually cancelled.
  final DateTime? cancelledAt;

  final CancellationState cancellation;
  final CheckInAvailability checkInAvailability;

  int get nights => stay.nights;

  @override
  bool operator ==(Object other) =>
      other is Reservation &&
      other.id == id &&
      other.reference == reference &&
      other.hotelId == hotelId &&
      other.hotelName == hotelName &&
      other.roomTypeId == roomTypeId &&
      other.roomName == roomName &&
      other.roomId == roomId &&
      other.stay == stay &&
      other.party == party &&
      other.status == status &&
      other.priceSnapshot == priceSnapshot &&
      other.createdAt == createdAt &&
      other.hotelCity == hotelCity &&
      other.hotelImageUrl == hotelImageUrl &&
      other.hotelReceptionPhone == hotelReceptionPhone &&
      other.hotelCheckInTime == hotelCheckInTime &&
      other.roomNumber == roomNumber &&
      other.nightlyRate == nightlyRate &&
      other.depositAmount == depositAmount &&
      other.serviceFee == serviceFee &&
      other.tax == tax &&
      other.taxRate == taxRate &&
      other.pricesIncludeTaxes == pricesIncludeTaxes &&
      other.cancelledAt == cancelledAt &&
      other.cancellation == cancellation &&
      other.checkInAvailability == checkInAvailability;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        reference,
        hotelId,
        hotelName,
        roomTypeId,
        roomName,
        roomId,
        stay,
        party,
        status,
        priceSnapshot,
        createdAt,
        hotelCity,
        hotelImageUrl,
        hotelReceptionPhone,
        roomNumber,
        nightlyRate,
        depositAmount,
        serviceFee,
        tax,
        taxRate,
        pricesIncludeTaxes,
        cancelledAt,
        cancellation,
        checkInAvailability,
      ]);

  @override
  String toString() => 'Reservation($reference, ${status.wireValue})';
}
